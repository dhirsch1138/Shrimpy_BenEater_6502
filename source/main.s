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
.segment "MAIN_RAM"
MAIN_LOOP_COUNT:        .res 1, $00
;Description: (HEX) Used to store count of main loop iterations

;====================================================
;Macros

;====================================================
;Code

  .code

;Includes

  .include "via.inc"
  .include "lcd.inc"
  .include "util_macros.inc"

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
  stz MAIN_LOOP_COUNT
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
  lda MAIN_LOOP_COUNT
  jsr lcd_print_hex
  lda #$20 ;space
  jsr lcd_print_char
  load_addr_to_zp_macro alphabet, LCD_PRINT_PTR ;load the address of addr to LCD_PRINT_PTR ZP word
  jsr lcd_print_asciiz_ZP ;print the LCD_PRINT_PTR ZP word on the LCD
  lda #$20 ;space
  jsr lcd_print_char
  load_addr_to_zp_macro numbers, LCD_PRINT_PTR ;load the address of addr to LCD_PRINT_PTR ZP word
  jsr lcd_print_asciiz_ZP ;print the LCD_PRINT_PTR ZP word on the LCD
  jsr half_second
  jsr half_second
  lda #%00000001 ; Clear display
  jsr lcd_instruction
  inc MAIN_LOOP_COUNT 
  bra loop ;jmp

alphabet: .asciiz "ABCDEFGHIJKLMNOPQRSTUVWXYZ"
numbers: .asciiz "0123456789"

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
  delay_macro #$d9, #$01
  rts