; presumes that code including this has lcd_statics.inc included too



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
  lda absolute_addr,x
  beq @loop_end ; if empty, short circuit
@loop:
  jsr lcd_send_byte
  inx
  beq @loop_end ; if counter rolls over, stop; lest we loop forever
  lda absolute_addr,x
  bne @loop
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
  phx
  ldx #$00
  ;set the starting address of the character in CGRAM
  lda absolute_addr ; get the DDRAM address from the definition
  asl ;CGRAM for 5x8 is DDRAM addr shifted left * 3 (page 19 HD44780U datasheet)
  asl
  asl
  ora #LCD_INST_CRAMADR
  jsr lcd_instruction ; set address CGRAM address counter to the transformed CGRAM address from the definition
@loop:
  inx
  lda absolute_addr,x
  jsr lcd_send_byte ; write the character data byte/row to CRAM
  cpx #$09 ; loop until write all 8 bytes/rows
  bne @loop ; jmp
  plx
.endmacro
.endif