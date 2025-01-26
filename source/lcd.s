;PURPOSE - defines the static register references & lcd functions 
;  interface as provided by Ben Eater's videos https://eater.net/6502
; adaptation from Ben Eater's keyboard.s https://eater.net/downloads/keyboard.s
;  much of the code is just copied from his work, but there are many changes from me.
;  rather than try to keep a diff in comments, I would encourage the reader to just diff
;  this code against the linked code above.
;
;NOTE/TODO-
;  While the LCD doesn't use all of PORTB of the VIA, this code will clobber
;  DDRB for the non-LCD ports right now (basically presuming they are output)
;  ideally we should try to preserve the non-LCD DDRB bits.
;

;====================================================
;Exports

;subroutines
.export lcd_instruction
.export lcd_init
.export lcd_load_custom_character
.export lcd_print_asciiz_ZP
.export lcd_send_byte
.export lcd_print_hex

;variables
.export LCD_ADDR_ZP

;====================================================
;Reserve RAM addresses

.segment "LCD_RAM"
LCD_RS_ENABLE:        .res 1, $00
;Description: (Boolean) Used to store if RS should be applied to the LCD instruction
;Values:
; * False - $00 for non-RS instructions (default)
; * True - $FF for RS instructions (like printing characters)
;Note: should be flagged with DEC as needed, always remember that its default state should be $00.

.segment "LCD_PAGEZERO": zeropage
LCD_ADDR_ZP:        .res 2, $0000




;====================================================
;Macros

.macro  lcd_wait_macro
;Description
;  Loops until the LCD no longer shows a busy status
;Arguments
;  None
;Preconditions
;  LCD is initialized and has its parameters set
;  LCD is in 4 bit mode
;Side Effects
;  None
  .local lcd_wait_busy ;limit scope of this symbol to this macro
  pha
  lda #%11110000  ; LCD data is input
  sta VIA1_DDRB
lcd_wait_busy:
  lda #LCD_PIN_RW
  sta VIA1_PORTB
  lda #(LCD_PIN_RW | LCD_PIN_E)
  sta VIA1_PORTB
  lda VIA1_PORTB       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #LCD_PIN_RW
  sta VIA1_PORTB
  lda #(LCD_PIN_RW | LCD_PIN_E)
  sta VIA1_PORTB
  ;TODO is this lda doing anything? seems like it is superceded immediately by the pla. 
  ;unless reading from the via port triggers something on the lcd?
  lda VIA1_PORTB       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcd_wait_busy
  ; logical break, we aren't busy anymore
  lda #LCD_PIN_RW
  sta VIA1_PORTB
  lda #%11111111  ; LCD data is output
  sta VIA1_DDRB
  pla
.endmacro

;====================================================
;Code
.segment "LCD_CODE"

;Includes

.include "via.inc"
.include "util_macros.inc"
.include "lcd_statics.inc"

lcd_init:
;Description
;  Inializes the lcd, sets 4 bit mode
;Arguments
;  None
;Preconditions
;  VIA DDRB must have the LCD's bits set to output
;Side Effects
;  LCD is set to accept 4-bit mode
;Notes
;  Does not include a wait for the LCD to be ready for the next command,
;  presuming that the code invoking the command will be smart enough to wait
;Todo
;  Should I be pushing A onto the stack such that this is transparent?
  pha
  ;per the HD44780U manual
  ;1) reset
  ;2) send the 4 bit instruction (swapped) 0010 for 4 bit operation
  lda #LCD_INST_FUNCSET
  swn_macro ;#%00000010 ; Set 4-bit mode by sending just the upper nibble
  sta VIA1_PORTB
  ora #LCD_PIN_E
  sta VIA1_PORTB
  ;3) send instruction for 4-bit, two line, 5x8
  lda #(LCD_INST_FUNCSET | LCD_FUNCSET_LINE)
  jsr lcd_instruction
 ; sta VIA1_PORTB
  stz LCD_RS_ENABLE  ;LCD_RS_ENABLE should be false
  pla
  rts

lcd_instruction:
;Description
;  Sends instruction byte to the LCD
;Arguments
;  A - LCD instruction byte
;Preconditions
;  LCD is initialized and has its parameters set
;Side Effects
;  Register A is squished
  lcd_wait_macro ;wait until lcd is no longer showing BUSY
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  bit LCD_RS_ENABLE ; enabled RS = $FF
  bpl lcd_instruction_sendhigh ; IF RS is NOT enabled THEN skip applying the RS mask
  ora #LCD_PIN_RS
lcd_instruction_sendhigh:
  sta VIA1_PORTB
  ora #LCD_PIN_E        ; Set E bit to send instruction
  sta VIA1_PORTB
  eor #LCD_PIN_E         ; Clear E bit
  sta VIA1_PORTB
  pla
  and #%00001111 ; Send low 4 bits
  bit LCD_RS_ENABLE ; enabled RS = $FF
  bpl lcd_instruction_sendlow ;IF RS is NOT enabled THEN skip applying the RS mask
  ora #LCD_PIN_RS
lcd_instruction_sendlow: 
  sta VIA1_PORTB
  ora #LCD_PIN_E         ; Set E bit to send instruction
  sta VIA1_PORTB
  eor #LCD_PIN_E         ; Clear E bit
  sta VIA1_PORTB
  rts

lcd_send_byte:
;Description
;  Sends byte to the LCD
;Arguments
;  A - byte to send
;Preconditions
;  LCD is ready to accept instruction bytes in RS (basically is it initialized and/or in a mode expecting writes)
;Side Effects
;  Instruction byte is sent to the LCD
;  Unless another mode is in effect (like writing CGRAM) this will write to the LCD DDRAM and increment the pointer if so configured
  pha
  dec LCD_RS_ENABLE        ;$00 - 1 = $FF (enabled)
  jsr lcd_instruction
  stz LCD_RS_ENABLE        ;$00 (disabled), saves up to three cycles over inc   
  pla
  rts

lcd_print_hex:
;Description
;  Sends hex byte to the LCD
;Arguments
;  A - hex to print
;Preconditions
;  hex  is sent to lcd to get printed
;Side Effects
;  two hex characters are sent to the LCD
  phx
  pha
  pha
  lsr
  lsr
  lsr
  lsr
  tax
  lda hexmap, x
  jsr lcd_send_byte
  pla
  and #$0F
  tax
  lda hexmap, x
  jsr lcd_send_byte
  pla
  plx
  rts

lcd_print_asciiz_ZP:
;Description
;  Prints the message to the LCD character by character from the ZP variable
;Arguments
;  LCD_ADDR_ZP - references a nul terminated string in memory
;Preconditions
;  LCD_ADDR_ZP is pointed at a null terminated string
;Side Effects
;  * LCD_ADDR_ZP is iterated through and printed to the LCD
;Note
  pha
lcd_print_asciiz_print_loop:
  lda (LCD_ADDR_ZP)
  beq lcd_print_asciiz_print_escape
  jsr lcd_send_byte
  inc LCD_ADDR_ZP
  bne lcd_print_asciiz_print_loop
  inc LCD_ADDR_ZP+1
  bra lcd_print_asciiz_print_loop ; jmp
lcd_print_asciiz_print_escape:
  pla
  rts

lcd_load_custom_character:
;Description
;  Loads the character definition to CGRAM
;Arguments
;  LCD_ADDR_ZP - address of character set
;      Offset 0    - CGRAM address
;      Offset 1-8  - values to write to CGRAM
;Preconditions
;  LCD should be fully initialized, it seems to get cranky if you try to poke CGRAM too early
;Side Effects
;  Character definition is loaded into CGRAM
;Note
;  Expected character definition format:
;    Offset 0    - CGRAM address
;    Offset 1-8  - values to write to CGRAM
  pha
  phx
  ldx $0a
  lda (LCD_ADDR_ZP)
  ora #LCD_INST_CRAMADR
  jsr lcd_instruction ;set addr
lcd_load_character_loop:
  inc LCD_ADDR_ZP
  bne lcd_load_character_skiphigh
  inc LCD_ADDR_ZP+1
lcd_load_character_skiphigh:
  lda (LCD_ADDR_ZP)
  jsr lcd_send_byte ;as the lcd is in 'write' mode from the CGRAM address, we can send eight sequential bytes to it
  dex
  bne lcd_load_character_loop ; jmp
lcd_load_character_done:
  plx
  pla
  rts

hexmap:
  .byte "0123456789ABCDEF"