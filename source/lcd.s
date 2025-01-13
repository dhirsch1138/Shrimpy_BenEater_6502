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
.export lcd_print_char
.export lcd_print_hex
;variables
.export LCD_RS_ENABLE

;====================================================
;Reserve RAM addresses

.segment "LCD_RAM"
;Nothing here

.segment "LCD_PAGEZERO"

LCD_RS_ENABLE:        .res 1, $00
;Description: (Boolean) Used to store if RS should be applied to the LCD instruction
;Values:
; * False - $00 for non-RS instructions (default)
; * True - $FF for RS instructions (like printing characters)
;Note: should be flagged with DEC as needed, always remember that its default state should be $00.

;====================================================
;Includes

.include "via.inc"

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
  sta VIA_DDRB
lcd_wait_busy:
  lda #LCD_4BIT_RW
  sta VIA_PORTB
  lda #(LCD_4BIT_RW | LCD_4BIT_E)
  sta VIA_PORTB
  lda VIA_PORTB       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #LCD_4BIT_RW
  sta VIA_PORTB
  lda #(LCD_4BIT_RW | LCD_4BIT_E)
  sta VIA_PORTB
  ;TODO is this lda doing anything? seems like it is superceded immediately by the pla. 
  ;unless reading from the via port triggers something on the lcd?
  lda VIA_PORTB       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcd_wait_busy
  ; logical break, we aren't busy anymore
  lda #LCD_4BIT_RW
  sta VIA_PORTB
  lda #%11111111  ; LCD data is output
  sta VIA_DDRB
  pla
.endmacro

;====================================================
;Code
.segment "LCD_CODE"

LCD_4BIT_E  = %01000000
LCD_4BIT_RW = %00100000
LCD_4BIT_RS = %00010000 

lcd_init:
;Description
;  Inializes the lcd, sets 4 bit mode
;Arguments
;  None
;Preconditions
;  VIA DDRB must have the LCD's bits set to output
;Side Effects
;  LCD is set to accept 4-bit mode
;  Register A is squished
;Notes
;  Does not include a wait for the LCD to be ready for the next command,
;  presuming that the code invoking the command will be smart enough to wait
;Todo
;  Should I be pushing A onto the stack such that this is transparent?
  lda #%00000010 ; Set 4-bit mode
  sta VIA_PORTB
  ora #LCD_4BIT_E
  sta VIA_PORTB
  and #%00001111
  sta VIA_PORTB
  stz LCD_RS_ENABLE  ;LCD_RS_ENABLE should be false
  rts

lcd_instruction:
;Description
;  Sends instruction byte to the LCD
;Arguments
;  A - LCD instruction byte
;Preconditions
;  LCD is initialized and has its parameters set
;  LCD is in 4 bit mode
;Side Effects
;  Instruction byte is sent to the LCD in 4-bit mode
;  Register A is squished
  lcd_wait_macro ;wait until lcd is no longer showing BUSY
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  bit LCD_RS_ENABLE ; enabled RS = $FF
  bpl lcd_instruction_sendhigh ; IF RS is NOT enabled THEN skip applying the RS mask
  ora #LCD_4BIT_RS
lcd_instruction_sendhigh:
  sta VIA_PORTB
  ora #LCD_4BIT_E        ; Set E bit to send instruction
  sta VIA_PORTB
  eor #LCD_4BIT_E         ; Clear E bit
  sta VIA_PORTB
  pla
  and #%00001111 ; Send low 4 bits
  bit LCD_RS_ENABLE ; enabled RS = $FF
  bpl lcd_instruction_sendlow ;IF RS is NOT enabled THEN skip applying the RS mask
  ora #LCD_4BIT_RS
lcd_instruction_sendlow: 
  sta VIA_PORTB
  ora #LCD_4BIT_E         ; Set E bit to send instruction
  sta VIA_PORTB
  eor #LCD_4BIT_E         ; Clear E bit
  sta VIA_PORTB
  rts

lcd_print_char:
;Description
;  Sends char to the LCD
;Arguments
;  A - char to print
;Preconditions
;  Char is sent to lcd to get printed
;Side Effects
;  Instruction byte is sent to the LCD in 4-bit mode
;  Register A is squished
  dec LCD_RS_ENABLE        ;$00 - 1 = $FF (enabled)
  jsr lcd_instruction
  stz LCD_RS_ENABLE        ;$00 (disabled), saves up to three cycles over inc   
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
  jsr lcd_print_char
  pla
  and #$0F
  tax
  lda hexmap, x
  jsr lcd_print_char
  pla
  plx
  rts
 
  hexmap:
  .byte "0123456789ABCDEF"