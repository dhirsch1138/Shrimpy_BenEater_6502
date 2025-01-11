;PURPOSE - defines the static register references & lcd functions 
;  interface as provided by Ben Eater's videos https://eater.net/6502
; adaptation from Ben Eater's keyboard.s https://eater.net/downloads/keyboard.s
;  much of the code is just copied from his work, but there are many changes from me.
;  rather than try to keep a diff in comments, I would encourage the reader to just diff
;  this code against the linked code above.
;
;NOTE/TODO-
;  While the LCD doesn't use all of PORTB of the VIA, this code will clobber
;  DDRB for the non-LCD ports right now (basically presuming they are output)
;  ideally we should try to preserve the non-LCD DDRB bits.
;
.export lcd_instruction
.export lcd_print_char
.export lcd_init

;Includes
  .include "via.s_imports"

.segment "LCD_SEGMENT"

LCD_4BIT_E  = %01000000
LCD_4BIT_RW = %00100000
LCD_4BIT_RS = %00010000 

lcd_init:
;Description
;  <TODO: Add description>
;Arguments
;  <TODO: Add arguments>
;Preconditions
;  <TODO: Add precondtions>
;Side Effects
;  <TODO: Add side effects>
  lda #%00000010 ; Set 4-bit mode
  sta VIA_PORTB
  ora #LCD_4BIT_E
  sta VIA_PORTB
  and #%00001111
  sta VIA_PORTB
  rts

lcd_instruction:
;Description
;  <TODO: Add description>
;Arguments
;  <TODO: Add arguments>
;Preconditions
;  <TODO: Add precondtions>
;Side Effects
;  <TODO: Add side effects>
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
;Description
;  <TODO: Add description>
;Arguments
;  <TODO: Add arguments>
;Preconditions
;  <TODO: Add precondtions>
;Side Effects
;  <TODO: Add side effects>
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
  ; logical break, we aren't busy anymore
  lda #LCD_4BIT_RW
  sta VIA_PORTB
  lda #%11111111  ; LCD data is output
  sta VIA_DDRB
  pla
  rts

lcd_print_char:
;Description
;  <TODO: Add description>
;Arguments
;  <TODO: Add arguments>
;Preconditions
;  <TODO: Add precondtions>
;Side Effects
;  <TODO: Add side effects>
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