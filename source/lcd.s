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
.export lcd_init_4bit
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

LCD_VIA_DDR = VIA1_DDRB
LCD_VIA_PORT = VIA1_PORTB

;the lcd is using ports D0 - D6
;NOTE THE LCD DDR SHOULD INITIALLY BE ALL INPUT $00 from via_init
LCD_VIA_OUTPUTMASK = %01111111
LCD_VIA_INPUTMASK = %01110000

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

lcd_init_4bit:
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
  lda LCD_VIA_DDR ; Set LCD output mask
  ora #(LCD_VIA_OUTPUTMASK)
  sta LCD_VIA_DDR  
  ; got this idea from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s
  ;
  ; The initialize from instruction sequence is specified in the datasheet, and is very specific. It requires
  ; sending 'raw' commands to the LCD that do not otherwise conform the to expected 4bit high/low nibble protocol
  ; used for other LCD 4 bit communication. Thus this will utilize 'raw' lcd send commands that should not be used
  ; outside of this context
  ;
  ; First we need to force the LCD into 4 bit mode. We do this by only sending the high
  ; bytes of a coordinated sequence of 'bitness' instructions
  ldx #$00 ; initialize index to walk through sequence
lcd_init_4bit_reset_rawbytes_loop:
  jsr delay_ms_100 ; this is likely far too much, I may refine this later.
  jsr delay_ms_100 
  ; Read next byte of force reset sequence data
  lda lcd_force_reset_rawbytes,x
  ; Exit loop if $00 read
  beq lcd_init_4bit_reset_rawbytes_end
  swn_macro ; as we are just sending the high 4 bits, swap nibbles
  jsr lcd_send_raw 
  inx 
  bra lcd_init_4bit_reset_rawbytes_loop
lcd_init_4bit_reset_rawbytes_end:
  jsr delay_ms_100
  ;
  ; The LCD is now in 4 bit mode, but is the busy flag cannot yet be used.
  ; We need to walk through a 4 bit instruction sequence to set the starting state
  ; of the LCD based on the datasheet's instructions.
  ldx #$00 ; initialize index to walk through sequence
lcd_init_4bit_reset_4bitraw_loop:
  jsr delay_ms_100 ; this is likely far too much, I may refine this later.
  lda lcd_force_reset_4bitraw,x ; Read next byte of force reset sequence data
  beq lcd_init_4bit_reset_4bitraw_end ; Exit loop if $00 read
  jsr lcd_send_raw_4bit
  inx 
  bra lcd_init_4bit_reset_4bitraw_loop
lcd_init_4bit_reset_4bitraw_end:
  plx    
  pla
  rts

;These instruction sequences are taken from the lcd controller datasheet

lcd_force_reset_rawbytes:
; got this idea from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s
        .byte LCD_INST_FUNCSET | LCD_FUNCSET_DATA ; #%00110000 ; designate 8-bit mode
        .byte LCD_INST_FUNCSET | LCD_FUNCSET_DATA ; #%00110000 ; designate 8-bit mode
        .byte LCD_INST_FUNCSET | LCD_FUNCSET_DATA ; #%00110000 ; designate 8-bit mode
        .byte LCD_INST_FUNCSET ; #%00100000 ; designate 4-bit mode
        .byte $00

lcd_force_reset_4bitraw:
; got this idea from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s
        .byte LCD_INST_FUNCSET | LCD_FUNCSET_LINE ; #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
        .byte LCD_INST_DISPLAY ; #%00001100 ; Display on; cursor off; blink off
        .byte LCD_INST_CLRDISP ; %00000001 ; Clear display
        .byte LCD_INST_ENTRYMO | LCD_ENTRYMO_INCR ; #%00000110 ; Increment and shift cursor; don't shift display
        .byte $00

lcd_send_raw_4bit:
;Description
;  Sends the byte to the LCD in 4 bit mode. No wait. No RS flag
;Arguments
;  A - LCD byte
;Precondition
;  first half of 4-bit init instructions done
;Side Effects
;  A is squished
;
;  pha - todo remove
  pha
  lsr
  lsr
  lsr
  lsr            
  jsr lcd_send_raw; Send high 4 bits
  pla
  and #%00001111 ; Send low 4 bits
  jsr lcd_send_raw; Send high 4 bits
; pla - todo remove
  rts

lcd_send_raw:
;Description
;  Sends the byte to the LCD, toggling the E flag.
;Arguments
;  A - LCD byte
;Precondition
;  LCD has powered up
;Side Effects
;  A is squished
;
;  pha todo remove
  sta LCD_VIA_PORT
  ora #(LCD_PIN_E) ; Set E bit to send instruction
  sta LCD_VIA_PORT
  eor #(LCD_PIN_E) ; Clear E bit
  sta LCD_VIA_PORT
;  pla todo remove
  rts

lcd_instruction:
;Description
;  Sends instruction byte to the LCD in normal operation, respecting the RS flag and the LCD wait register
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
  ora #(LCD_PIN_RS)
lcd_instruction_sendhigh:
  jsr lcd_send_raw
  pla
  and #%00001111 ; Send low 4 bits
  cpy #$01 ; are we setting RS ?
  bne lcd_instruction_sendlow ;IF RS is NOT enabled THEN skip applying the RS mask
  ora #(LCD_PIN_RS)
lcd_instruction_sendlow: 
  jsr lcd_send_raw
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
  lda lcd_print_hex_hexmap, x
  jsr lcd_send_byte
  pla
  and #$0F
  tax
  lda lcd_print_hex_hexmap, x
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
  jsr delay_ms_10 ; setting character memory seems odd > 1 mhz, add a bit of time
lcd_load_character_loop:
  inc LCD_ADDR_ZP
  bne lcd_load_character_skiphigh
  inc LCD_ADDR_ZP+1
lcd_load_character_skiphigh:
  lda (LCD_ADDR_ZP)
  jsr lcd_send_byte ;as the lcd is in 'write' mode from the CGRAM address, we can send eight sequential bytes to it
  dex
  jsr delay_ms_10 ; setting character memory seems odd > 1 mhz, add a bit of time
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
  lda LCD_VIA_DDR ; Set LCD input mask
  and #(LCD_VIA_INPUTMASK)
  sta LCD_VIA_DDR
lcd_wait_busy:
  lda #LCD_PIN_RW
  sta LCD_VIA_PORT
  lda #(LCD_PIN_RW | LCD_PIN_E)
  sta LCD_VIA_PORT
  lda LCD_VIA_PORT       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #LCD_PIN_RW
  sta LCD_VIA_PORT
  lda #(LCD_PIN_RW | LCD_PIN_E)
  sta LCD_VIA_PORT
  ;TODO is this lda doing anything? seems like it is superceded immediately by the pla. 
  ;unless reading from the via port triggers something on the lcd?
  lda LCD_VIA_PORT       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcd_wait_busy
  ; logical break, we aren't busy anymore
  lda #LCD_PIN_RW
  sta LCD_VIA_PORT
  lda LCD_VIA_DDR ; Set LCD output mask
  ora #(LCD_VIA_OUTPUTMASK)
  sta LCD_VIA_DDR
  pla
  rts

lcd_print_hex_hexmap:
  .byte "0123456789ABCDEF"
  .byte $00