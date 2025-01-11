;PURPOSE -  main code file
;
; adaptation from Ben Eater's keyboard.s https://eater.net/downloads/keyboard.s
; mostly I am using it to learn to talk to the lcd in 4-bit mode
;
;Includes
  .include "via.s_imports"
  ;.include "lcd.s_imports"

LCD_4BIT_E  = %01000000
LCD_4BIT_RW = %00100000
LCD_4BIT_RS = %00010000 
  
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
  jsr print_char
  inx
  jmp print

loop:
  nop
  ;jump back to the loop reference. We are now looping forever and ever and ever
  jmp loop

message: .asciiz "Jackie is cute!"

lcd_init:
  lda #%00000010 ; Set 4-bit mode
  sta VIA_PORTB
  ora #LCD_4BIT_E
  sta VIA_PORTB
  and #%00001111
  sta VIA_PORTB
  rts

lcd_instruction:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  sta VIA_PORTB
  ora #LCD_4BIT_E        ; Set E bit to send instruction
  sta VIA_PORTB
  eor #LCD_4BIT_E         ; Clear E bit
  sta VIA_PORTB
  pla
  and #%00001111 ; Send low 4 bits
  sta VIA_PORTB
  ora #LCD_4BIT_E         ; Set E bit to send instruction
  sta VIA_PORTB
  eor #LCD_4BIT_E         ; Clear E bit
  sta VIA_PORTB
  rts


lcd_wait:
  pha
  lda #%11110000  ; LCD data is input
  sta VIA_DDRB
lcdbusy:
  lda #LCD_4BIT_RW
  sta VIA_PORTB
  lda #(LCD_4BIT_RW | LCD_4BIT_E)
  sta VIA_PORTB
  lda VIA_PORTB       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #LCD_4BIT_RW
  sta VIA_PORTB
  lda #(LCD_4BIT_RW | LCD_4BIT_E)
  sta VIA_PORTB
  lda VIA_PORTB       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcdbusy

  lda #LCD_4BIT_RW
  sta VIA_PORTB
  lda #%11111111  ; LCD data is output
  sta VIA_DDRB
  pla
  rts

print_char:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4 bits
  ora #LCD_4BIT_RS         ; Set RS
  sta VIA_PORTB
  ora #LCD_4BIT_E          ; Set E bit to send instruction
  sta VIA_PORTB
  eor #LCD_4BIT_E          ; Clear E bit
  sta VIA_PORTB
  pla
  and #%00001111  ; Send low 4 bits
  ora #LCD_4BIT_RS         ; Set RS
  sta VIA_PORTB
  ora #LCD_4BIT_E          ; Set E bit to send instruction
  sta VIA_PORTB
  eor #LCD_4BIT_E          ; Clear E bit
  sta VIA_PORTB
  rts