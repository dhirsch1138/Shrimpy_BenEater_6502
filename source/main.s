;PURPOSE -  main code file
;
; adaptation from Ben Eater's keyboard.s https://eater.net/downloads/keyboard.s
; mostly I am using it to learn to talk to the lcd in 4-bit mode
;

;====================================================
;Exports
;nothing here

;====================================================
;Reserve RAM addresses
;nothing here

;====================================================
;Includes

  .include "via.inc"
  .include "lcd.inc"

;====================================================
;Macros
;nothing here

;====================================================
;Code

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
  ; presumes we will continue executing into 'loop'

loop:
;Description
;  Loops forever updating lcd 
;Arguments
;  None
;Preconditions
;  lcd is intialized and setup for display
;Side Effects
;  Updates LCD with the possible asciiz
  lcd_print_asciiz_macro hello ; lcd.inc
  jsr half_second
  jsr half_second
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  lcd_print_asciiz_macro world ; lcd.inc
  jsr half_second
  jsr half_second
  lda #%00000001 ; Clear display
  jsr lcd_instruction 
  bra loop ;jmp

hello: .asciiz "Hello"
world: .asciiz "World!"

half_second:
;Description
;  delays for approx 500k cycles (half second @ 1mhz)
;Arguments
;  None
;Preconditions
;  non
;Side Effects
;  nop
;Note
;  formula
;    The delay is 9*(256*A+Y)+8 cycles
;     9*($100*$d9+$01)+8 = $7A111 = 499985 
;     499985 + JSR(6) + RTS(6) = 499997
  lda #$d9
  ldy #$01
delay:
  cpy #1
  dey
  sbc #0
  bcs delay
  rts
