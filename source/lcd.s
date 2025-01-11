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

;allocate addresses & space for LCD variables
.segment "LCD_RAM"

LCD_RS_ENABLE:        .res 1, $00
;Description: Used to store if RS should be applied to the LCD instruction
;Values:
; * zero for non-RS instructions
; * non-zero for RS instructions (like printing characters)

;Includes
.include "via.s_imports"

.segment "LCD_SEGMENT"

LCD_4BIT_E  = %01000000
LCD_4BIT_RW = %00100000
LCD_4BIT_RS = %00010000 

lcd_init:
;Description
;  Inializes the lcd, sets 4 bit mode
;Arguments
;  None
;Preconditions
;  VIA DDRB must have the LCD's bits set to output
;Side Effects
;  LCD is set to accept 4-bit mode
;  Register A is squished
;Notes
;  Does not include a wait for the LCD to be ready for the next command,
;  presuming that the code invoking the command will be smart enough to wait
;Todo
;  Should I be pushing A onto the stack such that this is transparent?
  lda #%00000010 ; Set 4-bit mode
  sta VIA_PORTB
  ora #LCD_4BIT_E
  sta VIA_PORTB
  and #%00001111
  sta VIA_PORTB
  rts

lcd_instruction:
;Description
;  Sends instruction byte to the LCD
;Arguments
;  A - LCD instruction byte
;Preconditions
;  LCD is initialized and has its parameters set
;  LCD is in 4 bit mode
;Side Effects
;  Instruction byte is sent to the LCD in 4-bit mode
;  Register A is squished
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
;  Loops until the LCD no longer shows a busy status
;Arguments
;  None
;Preconditions
;  LCD is initialized and has its parameters set
;  LCD is in 4 bit mode
;Side Effects
;  None
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
;  Sends character to LCD
;Arguments
;  A - character byte to send
;Preconditions
;  LCD is initialized and has its parameters set
;  LCD is in 4 bit mode
;Side Effects
;  char byte is sent to the LCD in 4-bit mode
;  register A is squished
;Note
;  Is this just lcd_instruction that just sets RS?
;Todo
;  compare this to lcd_instruction and collape as possible
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