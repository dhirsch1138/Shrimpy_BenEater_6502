;PURPOSE -  main code file
;
;Includes
  .include "via.s_imports"
  .include "lcd.s_imports"
  
  .code

reset:
  jsr lcd_init
  lda #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #%00001110 ; Display on; cursor on; blink off
  jsr lcd_instruction
  lda #%00000110 ; Increment and shift cursor; don't shift display
  jsr lcd_instruction
  lda #%00000001 ; Clear display
  jsr lcd_instruction

printfun:
  lda #"I"
  jsr print_char
  lda #" "
  jsr print_char
  lda #"l"
  jsr print_char
  lda #"o"
  jsr print_char
  lda #"v"
  jsr print_char
  lda #"e"
  jsr print_char
  lda #" "
  jsr print_char
  lda #"J"
  jsr print_char
  lda #"a"
  jsr print_char
  lda #"c"
  jsr print_char
  lda #"k"
  jsr print_char
  lda #"i"
  jsr print_char
  lda #"e"
  jsr print_char

loop:
  nop
  ;jump back to the loop reference. We are now looping forever and ever and ever
  jmp loop

lcd_init:
  lda #%00000010 ; Set 4-bit mode
  sta PORTB
  ora #LCD_4BIT_E
  sta PORTB
  and #%00001111
  sta PORTB
  rts

lcd_instruction:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr            ; Send high 4 bits
  sta PORTB
  ora #LCD_4BIT_E        ; Set E bit to send instruction
  sta PORTB
  eor #LCD_4BIT_E         ; Clear E bit
  sta PORTB
  pla
  and #%00001111 ; Send low 4 bits
  sta PORTB
  ora #LCD_4BIT_E         ; Set E bit to send instruction
  sta PORTB
  eor #LCD_4BIT_E         ; Clear E bit
  sta PORTB
  rts


lcd_wait:
  pha
  lda #%11110000  ; LCD data is input
  sta DDRB
lcdbusy:
  lda #LCD_4BIT_RW
  sta PORTB
  lda #(LCD_4BIT_RW | LCD_4BIT_E)
  sta PORTB
  lda PORTB       ; Read high nibble
  pha             ; and put on stack since it has the busy flag
  lda #LCD_4BIT_RW
  sta PORTB
  lda #(LCD_4BIT_RW | LCD_4BIT_E)
  sta PORTB
  lda PORTB       ; Read low nibble
  pla             ; Get high nibble off stack
  and #%00001000
  bne lcdbusy

  lda #LCD_4BIT_RW
  sta PORTB
  lda #%11111111  ; LCD data is output
  sta DDRB
  pla
  rts

print_char:
  jsr lcd_wait
  pha
  lsr
  lsr
  lsr
  lsr             ; Send high 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  pla
  and #%00001111  ; Send low 4 bits
  ora #RS         ; Set RS
  sta PORTB
  ora #E          ; Set E bit to send instruction
  sta PORTB
  eor #E          ; Clear E bit
  sta PORTB
  rts