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