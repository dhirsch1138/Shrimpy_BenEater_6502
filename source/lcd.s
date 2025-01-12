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

.segment "LCD_PAGEZERO"

LCD_RS_ENABLE:        .res 1, $00
;Description: (Boolean) Used to store if RS should be applied to the LCD instruction
;Values:
; * False - $00 for non-RS instructions (default)
; * True - $FF for RS instructions (like printing characters)
;Note: should be flagged with DEC as needed, always remember that its default state should be $00.

;Includes
.include "via.s_imports"

.segment "LCD_CODE"

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
  stz LCD_RS_ENABLE  ;LCD_RS_ENABLE should be false
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
  bit LCD_RS_ENABLE ; enabled RS = $FF
  bpl lcd_sendhigh ; IF RS is NOT enabled THEN skip applying the RS mask
  ora #LCD_4BIT_RS
lcd_sendhigh:
  sta VIA_PORTB
  ora #LCD_4BIT_E        ; Set E bit to send instruction
  sta VIA_PORTB
  eor #LCD_4BIT_E         ; Clear E bit
  sta VIA_PORTB
  pla
  and #%00001111 ; Send low 4 bits
  bit LCD_RS_ENABLE ; enabled RS = $FF
  bpl lcd_sendlow ;IF RS is NOT enabled THEN skip applying the RS mask
  ora #LCD_4BIT_RS
lcd_sendlow: 
  sta VIA_PORTB
  ora #LCD_4BIT_E         ; Set E bit to send instruction
  sta VIA_PORTB
  eor #LCD_4BIT_E         ; Clear E bit
  sta VIA_PORTB
  bit LCD_RS_ENABLE ; enabled RS = $FF
  bpl lcd_instruction_done ;IF RS is enabled THEN return to lcd_print_char
  bra lcd_print_char_done ;jmp
lcd_instruction_done:
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
;  wrapper for lcd_instruction that also sets the LCD_RS_ENABLE flag
;  I know this is trading ROM (which I have a lot of) for RAM
;  (which I have less of); but I want practice utilizing RAM
  dec LCD_RS_ENABLE ;$00 - 1 = $FF (enabled)
  bra lcd_instruction ;doing a direct jmp to spare the work of stacking subroutines
lcd_print_char_done:
  stz LCD_RS_ENABLE ;$00 (disabled), saves up to three cycles over inc 
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