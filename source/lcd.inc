;PURPOSE - Imports needed symbols defined in lcd.s
;

.import lcd_instruction
.import lcd_init
.import lcd_print_char
.import lcd_print_hex

.import LCD_RS_ENABLE

;Macros

.macro  lcd_print_asciiz_macro asciiz   ; Print an asciiz to the lcd
;Description
;  Prints the message to the LCD character by character
;Arguments
;  None
;Preconditions
;  Expected to be called from reset
;  symbol 'message' exists as null terminated string
;Side Effects
;  * a character from message, indexed w/ x
;  * if we find the null at the end of message jump to the nop loop
;  * the character is printed to the lcd
;  * x is incremented
;Note
;  The macro is overengineering, but I am using this to play with macros. "I'm learnding!"
  .local lcd_print_asciiz_macro_print_loop
  .local lcd_print_asciiz_macro_print_escape
  ldx #0
lcd_print_asciiz_macro_print_loop:
  lda asciiz,x
  beq lcd_print_asciiz_macro_print_escape
  jsr lcd_print_char
  inx
  bra lcd_print_asciiz_macro_print_loop ;jmp
lcd_print_asciiz_macro_print_escape:
.endmacro