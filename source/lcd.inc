;PURPOSE - Imports needed symbols defined in lcd.s
;

.global lcd_instruction
.global lcd_init
.global lcd_send_byte
.global lcd_print_hex

;LCD defines
;========================================================================================================

;*** LCD init type
; uncomment to do init by instruction (default is normal internal LCD reset)
;LCD_DO_INSTRUCTION_INIT = $01


;** Adjust these to fit implementation with your VIA(s)
LCD_VIA_DDR = VIA1_DDRB
LCD_VIA_PORT = VIA1_PORTB

;*** DDR masks that will be applied to the LCD_VIA_DDR
; Current implementation is using ports D0 - D6
LCD_VIA_OUTPUTMASK = %01111111
LCD_VIA_INPUTMASK = %11110000



;LCD statics
;========================================================================================================

;control symbols
;==================
LCD_PIN_E  = %01000000
LCD_PIN_RW = %00100000
LCD_PIN_RS = %00010000 

;instruction masks
;==================
LCD_INST_CRAMADR = %01000000
LCD_INST_FUNCSET = %00100000
LCD_INST_CURSHFT = %00010000
LCD_INST_DISPLAY = %00001000
LCD_INST_ENTRYMO = %00000100
LCD_INST_RTNHOME = %00000010
LCD_INST_CLRDISP = %00000001

;function masks (use w/ LCD_INST_FUNCSET)
;==================
;000XXX00
LCD_FUNCSET_DATA = %00010000 ;8-bit mode (default 4-bit mode)
LCD_FUNCSET_LINE = %00001000 ;two line mode (default one line mode)
LCD_FUNCSET_SIZE = %00000100 ;5x10 characters (default 5x8)

;cursor shift masks (use w/ LCD_INST_CURSHFT)
;==================
;0000XX00
LCD_CURSHFT_MOVE = %00001000 ; display shifts (default cursor shifts)
LCD_CURSHFT_SDIR = %00000100 ; shift right (default shift left)

;display masks (use w/ LCD_INST_DISPLAY)
;==================
;00000XXX
LCD_DISPLAY_DSON = %00000100 ; display on (default display off)
LCD_DISPLAY_CUON = %00000010 ; cursor on (default cursor off)
LCD_DISPLAY_BLON = %00000001 ; blink on (default blink off)

;entry mode masks (use w/ LCD_INST_ENTRYMO)
;==================
;000000XX
LCD_ENTRYMO_INCR = %00000010 ; increment cursor (default decrement cursor)
LCD_ENTRYMO_ADSH = %00000001 ; accompanies display shift (default no)

;DDRAM shortcuts
;==================
LCD_DDRAM2LN58CR = %11000000 ; set the DDRRAM address to the start of the 2nd line (if 2line mode, 5x8 characters)

;REGISTER masks
;==================
LCD_BUSYFLAG = %10000000
LCD_REGISTER_READ = %00000000



;LCD macros
;========================================================================================================

.if    .definedmacro(lcd_print_asciiz_macro)
.else
.macro lcd_print_asciiz_macro absolute_addr
;Description
;  Prints the message to the LCD character by character from the ZP variable
;Arguments
;  absolute_addr - address to start of nul terminate string
;Preconditions
;  absolute_addr - address to start of nul terminate string
;  lcd is initialized
;Side Effects
;  * A is squished
;  * contents of absolute_addr are sent to LCD
;Note
  .local @loop
  .local @loop_end
  phx
  ldx #$00
@loop:
  lda absolute_addr,x
  beq @loop_end
  jsr lcd_send_byte
  inx
  bne @loop ; if counter rolls over, stop; lest we loop forever
@loop_end:
  plx
.endmacro
.endif


.if    .definedmacro(lcd_load_custom_character_macro)
.else
.macro lcd_load_custom_character_macro absolute_addr
;Description
;  Loads the character definition to CGRAM
;Arguments
;  absolute_addr - address of character set
;      Offset 0    - DDRAM address
;      Offset 1-9  - values to write to CGRAM
;Uses
;  X - count of how many bytes we have sent for the character
;Preconditions
;  LCD should be fully initialized
;Side Effects
;  Character definition is loaded into CGRAM
;  A is squished
;Note
;  Expected character definition format:
;    Offset 0    - DDRAM address
;    Offset 1-9  - values to write to CGRAM
  .local @loop
  ;set the starting address of the character in CGRAM
  lda absolute_addr ; get the DDRAM address from the definition
  asl ;CGRAM for 5x8 is DDRAM addr shifted left * 3 (page 19 HD44780U datasheet)
  asl
  asl
  ora #LCD_INST_CRAMADR
  jsr lcd_instruction ; set address CGRAM address counter to the transformed CGRAM address from the definition
  phx
  ldx #$01
@loop:
  lda absolute_addr,x
  jsr lcd_send_byte ; write the character data byte/row to CRAM
  inx
  cpx #$09 ; loop until write all 8 bytes/rows
  bne @loop ; jmp
  plx
.endmacro
.endif


.if    .definedmacro(lcd_load_custom_character_list_macro)
.else
.macro lcd_load_custom_character_list_macro absolute_addr
;Description
;  Loads the character definition to CGRAM
;Arguments
;  absolute_addr - address of character set list
;   Offset 0 - # of character sets
;   Offset N - character set
;      Offset 0    - DDRAM address
;      Offset 1-9  - values to write to CGRAM
;Uses
;  X - count of how many characters have to send still
;  Y - byte offset
;Preconditions
;  LCD should be fully initialized
;Side Effects
;  Character definition is loaded into CGRAM
;  A is squished
;Note
;  Expected character definition format:
;    Offset 0    - DDRAM address
;    Offset 1-9  - values to write to CGRAM
  .local @list_loop
  .local @list_end
  .local @row_loop
  phx
  phy
  ldy #$00 ; character list byte offset (gets set to 1 at the start of @list_loop)
  lda absolute_addr ; get the number of characters to load
  beq @list_end ; if the list says 0 things stop
  tax ; store character count in x
@list_loop:
  iny
  lda absolute_addr,y ; get the DDRAM address from the definition
  asl ;CGRAM for 5x8 is DDRAM addr shifted left * 3 (page 19 HD44780U datasheet)
  asl
  asl
  ora #LCD_INST_CRAMADR
  jsr lcd_instruction ; set address CGRAM address counter to the transformed CGRAM address from the definition
  phx
  ldx #$08 ; send the next eight bytes
@row_loop:
  iny
  lda absolute_addr,y
  jsr lcd_send_byte ; write the character data byte/row to CRAM
  dex
  bne @row_loop
  plx
  dex
  bne @list_loop
@list_end:
  ply
  plx
.endmacro
.endif

.if    .definedmacro(lcd_foreach_instruction_macro)
.else
.macro lcd_foreach_instruction_macro absolute_addr_to_instructions_z, instruction_call, delay_call
;Description
;  Enumerates the list of instructions @ absolute_addr_to_instructions_z, calling the instruction_call for each instance. 
;  The delay_call is called for each iteration if specified
;Arguments
;  absolute_addr_to_instructions_z - absolute address of NUL terminated list of instruction bytes
;  instruction_call - instruction to call (example 'jsr lcd_instruction')
;  delay_call (option) - delay function to call (example 'jsr delay_ms_10')
;Uses
;  X - byte index
;Preconditions
;  LCD should be powered on
;Side Effects
;  A is squished
;Note
;  this will call whatever you pass it, for good or ill. this might hide evil
  .local @loop
  .local @end
  phx
  ldx #$00 ; initialize index to walk through sequence
@loop:
  .ifnblank delay_call ; include the delay_call if defined
    delay_call
  .endif
  lda absolute_addr_to_instructions_z,x ; read next instruction
  beq @end; exit loop if nul $00 read
  instruction_call
  inx 
  bne @loop ; if the counter rolls over stop, lest we loop forever
@end:
  plx
.endmacro
.endif