;PURPOSE - provides an interface for a HD44780U LCD controller, in 4-bit serial mode, by a VIA.
;  DATASHEET - ..\doc\HD44780.pdf
;  * interface as provided by Ben Eater's videos https://eater.net/6502
;  * adaptation from Ben Eater's keyboard.s https://eater.net/downloads/keyboard.s
;  * I also cribbed ideas from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s
;  * rather than try to keep a diff in comments, I would encourage the reader to just reference the original masters 
;
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
LCD_ADDR_ZP:        .addr  $0000


;====================================================
;Macros

;====================================================
;Defines
;Adjust these to fit implementation with your VIA(s)

LCD_VIA_DDR = VIA1_DDRB
LCD_VIA_PORT = VIA1_PORTB

;the lcd is using ports D0 - D6
LCD_VIA_OUTPUTMASK = %01111111
LCD_VIA_INPUTMASK = %11110000

;====================================================

;Code
.segment "LCD_CODE"

;Includes

.include "via.inc"
.include "util_macros.inc"
.include "lcd_statics.inc"
.include "util.inc"

.proc lcd_init ; label + scope (This isn't required, I am just experimenting w/ ca65 functionality)
;Description
;  Inializes the lcd & sets 4 bit mode using the initialization by instruction sequence
;  Doing things the hard way as the LCD seems super whiny about timing and power issues.
;Arguments
;  None
;Preconditions
;  None
;Side Effects
;  LCD is set to accept 4-bit mode
;  A is squished
;Notes
;  The busy flag is not available during the instruction initialization sequence
;  The initialize from instruction sequence is specified in the datasheet, and is very specific. 
;   reference : (figure 24 on page 46 of datasheet)
  phx
  ; First we need to force the LCD into 4 bit mode. We do this by only sending the high
  ; bytes of a coordinated sequence of 'bitness' instructions.
  ; These instructions are unique because:
  ;  * These direct byte submissions, with swapped nibbles due to the 4-bit connection.
  ;  * We are not sending the low byte, or checking the lcd busy flag. These are blind writes.
  jsr delay_ms_50 ; give the LCD time to power up
  ldx #$00 ; initialize index to walk through sequence
@bitness_instruction_loop:
  jsr delay_ms_10 ; this is likely far too much, I may refine this later.
  ; Read next byte of force reset sequence data
  lda bitness_instructions,x
  ; Exit loop if $00 read
  beq @bitness_instruction_loop_end
  lsr ; Send high 4 bits, so we need to shift them into the effective low nibble
  lsr
  lsr
  lsr
  jsr lcd_send_nibble 
  inx 
  bra @bitness_instruction_loop ; jmp
@bitness_instruction_loop_end:
  ;
  ; The LCD is now in 4 bit mode, but is the busy flag cannot yet be used.
  ; We need to walk through a 4 bit instruction sequence to set the starting state
  ; of the LCD based on the datasheet's instructions.
  ldx #$00 ; initialize index to walk through sequence
@instruction_loop:
  jsr delay_ms_10 ; this is likely far too much, I may refine this later.
  lda reset_instructions,x ; Read next byte of force reset sequence data
  beq @instruction_loop_end ; Exit loop if $00 read
  jsr lcd_instruct_nobusycheck ; send an instruction w/o checking the busy
  inx 
  bra @instruction_loop
@instruction_loop_end:
  plx
  rts

;These instruction sequences are taken from the lcd controller datasheet
;these are tied to the scope of lcd_init
;I took this idea from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s

bitness_instructions:
  .byte LCD_INST_FUNCSET | LCD_FUNCSET_DATA ; #%00110000 ; designate 8-bit mode
  .byte LCD_INST_FUNCSET | LCD_FUNCSET_DATA ; #%00110000 ; designate 8-bit mode
  .byte LCD_INST_FUNCSET | LCD_FUNCSET_DATA ; #%00110000 ; designate 8-bit mode
  .byte LCD_INST_FUNCSET ; #%00100000 ; designate 4-bit mode
  .byte $00

reset_instructions:
  .byte LCD_INST_FUNCSET | LCD_FUNCSET_LINE ; #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  .byte LCD_INST_DISPLAY ; #%00001000 ; Display off; cursor off; blink off
  .byte LCD_INST_CLRDISP ; #%00000001 ; Clear display
  .byte LCD_INST_ENTRYMO | LCD_ENTRYMO_INCR ; #%00000110 ; Increment and shift cursor; don't shift display
  .byte $00

.endproc ;end of lcd_init procedure scope

lcd_instruction:
;Description
;  Sends instruction byte to the LCD in normal operation, respecting the RS flag and the LCD wait register
;Arguments
;  A - LCD instruction byte
;  Y - if Y = 1 THEN we are setting the RS pin with this instruction
;Preconditions
;  LCD is initialized and has its parameters set
;Side Effects
;  byte is sent to LCD as instruction
;  A is squished
  jsr lcd_wait ;wait until lcd is no longer showing BUSY
lcd_instruct_nobusycheck: ; send an instruction w/o checking the busy flag, should only really be used by instruction init sequence
  pha
  lsr
  lsr
  lsr
  lsr ; Send high 4 bits
  jsr lcd_send_nibble
  pla ; Send low 4 bits
  and #%00001111 
  jsr lcd_send_nibble
  rts

lcd_send_byte:
;Description
;  Sends byte to the LCD
;Arguments
;  A - byte to send
;Preconditions
;  LCD is fully initialized
;Side Effects
;  Byte is sent to the LCD with the register select flag (RS) set 
;  A is squished
  jsr lcd_wait ; wait until lcd is no longer showing BUSY
  pha
  lsr
  lsr
  lsr
  lsr ; Send high 4 bits
  ora #(LCD_PIN_RS)
  jsr lcd_send_nibble
  pla ; Send low 4 bits
  and #%00001111 
  ora #(LCD_PIN_RS)
  jsr lcd_send_nibble
  rts

.proc lcd_print_hex ; label + scope, not required but I am having fun using ca65 features
;Description
;  Sends hex byte to the LCD
;Arguments
;  A - hex to print
;Preconditions
;  lcd is initialized in 4-bit mode
;Side Effects
;  two hex characters are sent to the LCD
;  A is squished
  phx
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
  plx
  rts

hexmap:
  .byte "0123456789ABCDEF"  

.endproc ; end scope of lcd_print_hex

lcd_print_asciiz_ZP:
;Description
;  Prints the message to the LCD character by character from the ZP variable
;Arguments
;  LCD_ADDR_ZP - references a nul terminated string in memory
;Preconditions
;  LCD_ADDR_ZP is pointed at a null terminated string
;  lcd is initialized in 4-bit mode
;Side Effects
;  * LCD_ADDR_ZP is iterated through and printed to the LCD
;  * A is squished
;Note
@loop:
  lda (LCD_ADDR_ZP)
  beq @loop_end
  jsr lcd_send_byte
  inc_zp_addr_macro LCD_ADDR_ZP
  bra @loop ; jmp
@loop_end:
  rts

lcd_load_custom_character:
;Description
;  Loads the character definition to CGRAM
;Arguments
;  LCD_ADDR_ZP - address of character set
;      Offset 0    - DDRAM address
;      Offset 1-9  - values to write to CGRAM
;Uses
;  X - count of how many bytes we have sent for the character
;Preconditions
;  LCD should be fully initialized, it seems to get cranky if you try to poke CGRAM too early
;Side Effects
;  Character definition is loaded into CGRAM
;  A is squished
;Note
;  Expected character definition format:
;    Offset 0    - DDROM address
;    Offset 1-9  - values to write to CGRAM
  phx
  ldx #$00
  ;set the starting address of the character in CGRAM
  lda (LCD_ADDR_ZP) ; get the DDROM address from the definition
  asl ;CGRAM for 5x8 is DDROM addr shifted left * 3 (page 19 HD44780U datasheet)
  asl
  asl
  ora #LCD_INST_CRAMADR
  jsr lcd_instruction ; set address CGRAM address counter to the transformed CGRAM address from the definition
@loop:
  inc_zp_addr_macro LCD_ADDR_ZP ; increment ZP address pointer to get next byte: the next row of the character
  lda (LCD_ADDR_ZP)
  jsr lcd_send_byte ; write the character data byte/row to CRAM
  inx
  cpx #$09 ; loop until write all 8 bytes/rows
  bne @loop ; jmp
  plx
  rts

lcd_send_nibble:
;Description
;  Sends the nibble to the LCD, toggling the E flag.
;  The instructions are full byte, of course, but as this is a 4-bit connection
;  only the lower nibble of the byte in the accumulator are actually sent.
;Arguments
;  A - LCD byte
;Precondition
;  LCD has powered up
;Side Effects
;  * LCD output mask is applied to the VIA DD
;  * The nibble is sent to the LCD port via the VIA, strobing the E input 
;None
  pha
  lda LCD_VIA_DDR ; Set LCD output mask
  ora #(LCD_VIA_OUTPUTMASK)
  sta LCD_VIA_DDR
  pla
  sta LCD_VIA_PORT
  ora #(LCD_PIN_E) ; Set E bit to send instruction
  sta LCD_VIA_PORT
  eor #(LCD_PIN_E) ; Clear E bit
  sta LCD_VIA_PORT
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
@busy_loop:
  lda #LCD_REGISTER_READ
  jsr lcd_read_byte
  and #LCD_BUSYFLAG
  bne @busy_loop
  pla
  rts

lcd_read_byte:
;Description
;  reads the data byte from lcd in 4-bit mode
;Arguments
;   A - #LCD_PIN_RS mask if we are reading data from a lcd memory address
;       OR #LCD_REGISTER_READ if we are reading from the lcd register
;Uses
;  Y - #LCD_PIN_RS mask if we are reading from an lcd memory address
;       OR #LCD_REGISTER_READ if we are reading from the lcd register
;  X - read low nibble as xxxx####
;Preconditions
;  LCD is initialized and has its parameters set
;  LCD is in 4 bit mode
;  IF A - #LCD_PIN_RS the lcd address counter should be set to the address to read
;Side Effects
;  The read byte is put into the accumulator
  phx
  phy
  tay ; load the read mask from the argument (reading register or data)
  jsr lcd_read_nibble ; read high nibble into accumulator
  pha
  tya ; load the read mask from the argument (reading register or data)
  jsr lcd_read_nibble ; read low nibble into accumulator
  tax ; store low nibble in X for util_joinnibbles
  pla ; pull the high nibble into A for util_joinnibbles
  jsr util_joinnibbles
  ply
  plx
  rts


lcd_read_nibble:
;Description
;  reads nibble from lcd in 4-bit mode (note the RS flag is not set, so this is for reading the register right now)
;Arguments
;  A - #LCD_PIN_RS mask OR #LCD_REGISTER_READ
;Uses
;  X - enabled read byte
;Preconditions
;  LCD is initialized and has its parameters set
;  LCD is in 4 bit mode
;Side Effects
;  The read nibble is put into the accumulator as xxxx####
  phx
  pha
  lda LCD_VIA_DDR ; Set LCD input mask
  and #(LCD_VIA_INPUTMASK)
  sta LCD_VIA_DDR
  pla
  ora #LCD_PIN_RW ; apply the RW pin mask so that the lcd knows we are reading
  sta LCD_VIA_PORT ; write the command
  ora #LCD_PIN_E
  sta LCD_VIA_PORT ; strobe the enable on 
  tax
  lda LCD_VIA_PORT ; Read nibble
  pha
  txa
  eor #LCD_PIN_E
  sta LCD_VIA_PORT ; turn off enable strobe
  pla
  plx
  rts