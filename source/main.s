;PURPOSE -  main code file
;
; adaptation from Ben Eater's keyboard.s https://eater.net/downloads/keyboard.s
; mostly I am using it to learn to talk to the lcd in 4-bit mode
;
;Includes
  .include "via.s_imports"
  .include "lcd.s_imports"

  .code

reset:
;Description
;  The reset entrypoint for this project
;Arguments
;  None (called from reset)
;Preconditions
;  Invoked from reset vector
;Side Effects
;  * VIA pot B is set to output on all bits
;  * intializes LCD
;    * for 4bit
;    * 2 line display
;    * 5x8 fonts
;  * enables LCD
;    * Dislay on
;    * cursor on
;    * blink off
;  * sets LCD parameters
;    * increment cursor on update
;    * shift cursor on update
;    * do NOT shift display on update

  ldx #$ff
  txs
  lda #%11111111 ; Set all pins on port B to output
  sta VIA_DDRB
  jsr lcd_init
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  ; presumes we will continue executing into 'print'

print:
;Description
;  Prints the message to the LCD charater by character
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
  ldx #0
print_loop:
  lda message,x
  beq loop
  lcd_print_char_macro ;macro to print character, defined in lcd.s_imports.
  inx
  bra print_loop ;jmp

loop:
;Description
;  Loops on nop. 
;Arguments
;  None
;Preconditions
;  Does nothing
;Side Effects
  nop
  bra loop ;jmp

message: .asciiz "Jackie is cute!"