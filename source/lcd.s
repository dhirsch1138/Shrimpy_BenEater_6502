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

.segment "LCD_PAGEZERO": zeropage
LCD_ADDR_ZP:        .res 2, $0000

LCD_DDR = VIA1_DDRB
LCD_VIAPORT = VIA1_PORTB

;====================================================
;Macros

;====================================================
;Code
.segment "LCD_CODE"

;Includes

.include "via.inc"
.include "util_macros.inc"
.include "lcd_statics.inc"
.include "util.inc"

lcd_init_full_init:
;Description
;  Inializes the lcd, sets 4 bit mode
;Arguments
;  None
;Preconditions
;  VIA DDRB must have the LCD's bits set to output
;Side Effects
;  LCD is set to accept 4-bit mode
;  A is squished
;  X is squished
;  Y is squished
;Notes
;  Does not include a wait for the LCD to be ready for the next command,
;  presuming that the code invoking the command will be smart enough to wait
;
  lda #%11111111 ; Set all pins on port B to output
  sta LCD_DDR
  ;per the HD44780U manual (init by instruction)
  ;1) reset
  delay_macro #$FF, #$FF ; datasheet says it needs a small delay between function inits, this gives the LCD time to power up
  ;2) send the 8-bit function instruction as just the upper nibble * 3
  lda #(LCD_INST_FUNCSET | LCD_FUNCSET_DATA)
  swn_macro ;#%00000011 ; Set 8-bit mode by sending just the upper nibble
  ldx $03
lcd_init_8bit: 
  delay_macro #$A0, #$FF ; datasheet says it needs a small delay between function inits, this gives the LCD time to power up
  sta LCD_VIAPORT
  ora #LCD_PIN_E
  sta LCD_VIAPORT
  eor #LCD_PIN_E
  sta LCD_VIAPORT
  dex
  bne lcd_init_8bit
  ;3) send the 4-bit function instruction as just the upper nibble
  delay_macro #$A0, #$FF ; datasheet says it needs a small delay between function inits, this gives the LCD time to power up
  lda #LCD_INST_FUNCSET
  swn_macro ;#%00000010 ; Set 4-bit mode by sending just the upper nibble
  sta LCD_VIAPORT
  ora #LCD_PIN_E
  sta LCD_VIAPORT
  eor #LCD_PIN_E
  sta LCD_VIAPORT 
  ;4) function set
  delay_macro #$A0, #$FF ; datasheet says it needs a small delay between function inits
  lda #(LCD_INST_FUNCSET | LCD_FUNCSET_LINE); Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  ;5) display set
  delay_macro #$A0, #$FF ; datasheet says it needs a small delay between function inits
  lda #LCD_INST_DISPLAY ; display off
  jsr lcd_instruction
  delay_macro #$A0, #$FF ; datasheet says it needs a small delay between function inits
  lda #LCD_INST_CLRDISP ; Clear display
  jsr lcd_instruction
  ;6) entry mode set
  delay_macro #$A0, #$FF ; datasheet says it needs a small delay between function inits
  lda #(LCD_INST_ENTRYMO | LCD_ENTRYMO_INCR); Increment and shift cursor; don't shift display
  jsr lcd_instruction
  ;after formal init
  delay_macro #$A0, #$FF ; datasheet says it needs a small delay between function inits
  lda #(LCD_INST_DISPLAY | LCD_DISPLAY_DSON); Display on; cursor off; blink off
  jsr lcd_instruction
  lda #LCD_INST_CLRDISP ; Clear display
  jsr lcd_instruction
  lda #LCD_INST_RTNHOME ; return cursor home
  jsr lcd_instruction
  delay_macro #$A0, #$FF ; datasheet says it needs a small delay between function inits
  rts

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
  pha
  phx
  lda #%11111111 ; Set all pins on port B to output
  sta LCD_DDR
  jsr delay_ms_100
  lda #(LCD_INST_FUNCSET | LCD_FUNCSET_DATA); #%00110000 ; designate 8-bit mode
  swn_macro ;#%00000011 ; Set 8-bit mode by sending just the upper nibble
  jsr lcd_send_raw ; send it three times to force initializtion
  jsr delay_ms_100    
  jsr lcd_send_raw ; send it three times to force initializtion
  jsr delay_ms_100
  jsr lcd_send_raw ; send it three times to force initializtion
  jsr delay_ms_100  
  lda #LCD_INST_FUNCSET ; #%00100000 ; designate 4-bit mode
  swn_macro ;#%00000010 ; Set 4-bit mode by sending just the upper nibble
  jsr lcd_send_raw
  jsr delay_ms_100
  lda #(LCD_INST_FUNCSET | LCD_FUNCSET_LINE); #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_send_raw_4bit
  jsr delay_ms_50
  lda #LCD_INST_DISPLAY ; #%00001000 ; Display off
  jsr lcd_send_raw_4bit
  jsr delay_ms_50
  lda #LCD_INST_CLRDISP ; %00000001 ; Clear display
  jsr lcd_send_raw_4bit   
  jsr delay_ms_50
  lda #(LCD_INST_ENTRYMO | LCD_ENTRYMO_INCR); #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_send_raw_4bit
  jsr delay_ms_50
  ;we 'should' be initialized at this point
  ;redefine setup as we've allegedly initialized at this point 
  lda #(LCD_INST_FUNCSET | LCD_FUNCSET_LINE); #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  jsr delay_ms_50
  lda #(LCD_INST_DISPLAY | LCD_DISPLAY_DSON); #%00001100 ; Display on; cursor off; blink off
  jsr lcd_instruction
  jsr delay_ms_50
  lda #(LCD_INST_ENTRYMO | LCD_ENTRYMO_INCR); #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  jsr delay_ms_50
  lda #LCD_INST_CLRDISP; Clear display
  jsr lcd_instruction
  jsr delay_ms_50
  lda #LCD_INST_RTNHOME; return cursor home
  jsr lcd_instruction    
  plx
  pla
  rts


lcd_send_raw_4bit:
;Description
;  Sends the byte to the LCD in 4 bit mode. No wait. No RS bit
;Arguments
;  A - LCD byte
;Precondition
;  first half of 4-bit init instructions done
;Side Effects
;  None
  pha
  pha
  lsr
  lsr
  lsr
  lsr            
  jsr lcd_send_raw; Send high 4 bits
  pla
  and #%00001111 ; Send low 4 bits
  jsr lcd_send_raw; Send high 4 bits
  pla
  rts

lcd_send_raw:
;Description
;  Sends the byte to the LCD, toggling the E flag. No wait
;Arguments
;  A - LCD byte
;Precondition
;  LCD has powered up
;Side Effects
;  None
  pha
  sta LCD_VIAPORT
  ora #LCD_PIN_E
  sta LCD_VIAPORT
  eor #LCD_PIN_E
  sta VIA1_PORTB
  pla
  rts

lcd_instruction:
;Description
;  Sends instruction byte to the LCD
;Arguments
;  A - LCD instruction byte
;  Y - if Y = 1 THEN we are setting the RS pin with this instruction
;Preconditions
;  LCD is initialized and has its parameters set
;Side Effects
;  None
  phy
  ldy #$00 ; THEN this is being called as a command (as in it is invoked as lcd_instruction) THEN store 0 to Y to flag this as not a RS operation
lcd_instruction_y_set: ; if jumping here Y should already be pushed onto the stack, and Y should 1
  pha
  jsr lcd_wait ;wait until lcd is no longer showing BUSY
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  cpy #$01 ; are we setting RS ?
  bne lcd_instruction_sendhigh ; IF RS is NOT enabled THEN skip applying the RS mask
  ora #LCD_PIN_RS
lcd_instruction_sendhigh:
  sta LCD_VIAPORT
  ora #LCD_PIN_E        ; Set E bit to send instruction
  sta LCD_VIAPORT
  eor #LCD_PIN_E         ; Clear E bit
  sta LCD_VIAPORT
  pla
  and #%00001111 ; Send low 4 bits
  cpy #$01 ; are we setting RS ?
  bne lcd_instruction_sendlow ;IF RS is NOT enabled THEN skip applying the RS mask
  ora #LCD_PIN_RS
lcd_instruction_sendlow: 
  sta LCD_VIAPORT
  ora #LCD_PIN_E         ; Set E bit to send instruction
  sta LCD_VIAPORT
  eor #LCD_PIN_E         ; Clear E bit
  sta LCD_VIAPORT
  pla
  ply
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
  phy ; y will be pulled from stack in lcd_instruction
  ldy #$01 ; set Y to 1 to flag that the register select flag should be sent as this is data / vs command
  bra lcd_instruction_y_set ;jmp

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

lcd_wait:
;Description
;  Loops until the LCD no longer shows a busy status
;Arguments
;  None
;Preconditions
;  LCD is initialized and has its parameters set
;  LCD is in 4 bit mode
;Side Effects
;  None
  pha
  lda #%11110000  ; LCD data is input
  sta LCD_DDR
lcd_wait_busy:
  lda #LCD_PIN_RW
  sta LCD_VIAPORT
  lda #(LCD_PIN_RW | LCD_PIN_E)
  sta LCD_VIAPORT
  lda LCD_VIAPORT       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #LCD_PIN_RW
  sta LCD_VIAPORT
  lda #(LCD_PIN_RW | LCD_PIN_E)
  sta LCD_VIAPORT
  ;TODO is this lda doing anything? seems like it is superceded immediately by the pla. 
  ;unless reading from the via port triggers something on the lcd?
  lda LCD_VIAPORT       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcd_wait_busy
  ; logical break, we aren't busy anymore
  lda #LCD_PIN_RW
  sta LCD_VIAPORT
  lda #%11111111  ; LCD data is output
  sta LCD_DDR
  pla
  rts

hexmap:
  .byte "0123456789ABCDEF"