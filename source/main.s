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
  ldx #0

print:
  lda message,x
  beq loop
  jsr lcd_print_char
  inx
  jmp print

loop:
  nop
  ;jump back to the loop reference. We are now looping forever and ever and ever
  jmp loop

message: .asciiz "Jackie is cute!"