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
MAIN_LOOPCOUNTER:           .byte  $00
DINOSAUR_X_LOCATION:        .byte  $00
;====================================================
;Macros

;====================================================
;Code

  .code

;Includes

  .include "via.inc"
  .include "lcd.inc"
  .include "lcd_macros.inc"
  .include "lcd_statics.inc"
  .include "util_macros.inc"
  .include "util.inc"  

reset:
;Description
;  The reset entrypoint for this project
;Arguments
;  None (called from reset)
;Preconditions
;  Invoked from reset vector
;Side Effects
;  * Stack pointer is initialized
;  * via is initialized
;  * LCD is initialized
;  * Custom characters are loaded
;   
  ldx #$ff
  txs
  jsr via_init ; setup the via
  jsr setup_lcd ; setup the lcd
  ;continue executing into main_loop ; bra main_loop ; jmp

main_loop:
;Description
;  Loops forever updating lcd 
;Arguments
;  None
;Uses
;  DINOSAUR_X_LOCATION is the dinosaur location address
;  MAIN_LOOPCOUNTER is the loop counter
;Preconditions
;  lcd is intialized and setup for display, custom characters are loaded
;Side Effects
;  Updates LCD
  lda #$00
  sta MAIN_LOOPCOUNTER
  lda #LCD_DDRAM2LN58CR ; dino resets to the beginning of the second line of the display
  sta DINOSAUR_X_LOCATION
  lda #LCD_INST_CLRDISP ; clear the screen and reset pointers
  jsr lcd_instruction
@loop:
  ; draw top line by writing incrementally
  lda MAIN_LOOPCOUNTER ; write loop counter as hex
  jsr lcd_print_hex 
  lda #$20 ; write space " "
  jsr lcd_send_byte 
  ; write a hearts, animating it with loop count
  lda MAIN_LOOPCOUNTER
  ror
  bcs @full_heart
  lda emptyheartchar
  bra @past_heart
@full_heart:
  lda fullheartchar
@past_heart:
  jsr lcd_send_byte  
  lda #$20 ; write space " "
  jsr lcd_send_byte
  lcd_print_asciiz_macro dinosaur_says
  ; draw bottom line by drawing dinosaur to its specific location
  lda DINOSAUR_X_LOCATION ; set the lcd cursor to the location of the dinosaur
  jsr lcd_instruction
  lda dinorightchar ; write a dinosaur
  jsr lcd_send_byte
  ; draw cake @ position 15 on second row
  lda #(LCD_DDRAM2LN58CR | $0F)
  cmp DINOSAUR_X_LOCATION ; if the cake would overwrite the dinosaur do not draw cake
  beq @nocake
  jsr lcd_instruction
  lda cakechar ; write cake
  jsr lcd_send_byte
@nocake:
  ; update the dinosaur's location, resetting the position if it walked off the lcd
  inc DINOSAUR_X_LOCATION ; increment the dinosaur location
  lda DINOSAUR_X_LOCATION ; IF the dinosaur's location puts it off the end of the display THEN reset it.
  cmp #(LCD_DDRAM2LN58CR | %00010000) ; the display is sixteen characters, so if position is not 16 (0 indexed) then it doesn't need a reposition
  bmi @skip_dino_reposition
  lda #LCD_DDRAM2LN58CR ; dino resets to the beginning of the second line of the display
  sta DINOSAUR_X_LOCATION
@skip_dino_reposition:
  ; delay and loop
  jsr delay_ms_1000 ; wait one second, this whole loop should take ~1 second (recognize that the actual instructions will make it take longer of course)
  lda #LCD_INST_CLRDISP; Clear display
  jsr lcd_instruction
  inc MAIN_LOOPCOUNTER ; increment the loop counter. 
  bra @loop ;jmp

dinosaur_says: .asciiz "Rwaaaar!"

.proc setup_lcd ; label & scope, not required but it limits the scope of the instruction list
;Description
;  Sets up the the LCD
;Arguments
;  None
;Preconditions
;  VIA should be setup
;Side Effects
;  * LCD is initialized
;  * LCD parameters are set
;  * customer characters are loaded
;  * A is squished
;Notes
;  the character loading is redundant, but I wanted to see if I could load character sets and single characters
  jsr lcd_init ; init the lcd in 4 bit mode
  lcd_foreach_instruction_macro instructions, jsr lcd_instruction; specify the lcd parameters for this program
  lcd_load_custom_character_list_macro character_load_list ; load characters from a character list
  lcd_load_custom_character_macro cakechar ; make sure we can still load single characters
  rts

instructions:
; got this idea from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s
  .byte LCD_INST_FUNCSET | LCD_FUNCSET_LINE ; #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  .byte LCD_INST_DISPLAY | LCD_DISPLAY_DSON ; #%00001100 ; Display on; cursor off; blink off
  .byte LCD_INST_ENTRYMO | LCD_ENTRYMO_INCR ; #%00000110 ; Increment and shift cursor; don't shift display
  .byte LCD_INST_CLRDISP ; %00000001 ; Clear display
  .byte $00

.endproc

;custom character definitions:
;
;The datasheet says we get eight usuable custom character address that are in CGRAM (addressible in DDROM as $00 - $08)
;
;To make referencing these characters simple, I created a basic structure for 5x8 font custom character definitions
; * Offset 0    - DDRAM address
; * Offset 1-9  - bytes to write to CGRAM
;
;The primary benefit of this structure is that the program can simply reference the label when wanting to send the custom character,
;as offset 0 is the DDRAM that the custom character should be addressible at (if it was loaded)
;
;The lcd_load_custom_character subroutine handles the translation of the DDROM address to the applicable CGRAM addresses that the character will be
;stored.
character_load_list:
  .byte $03 ;number of characters to load
dinorightchar: 
  .byte $00 ;DDRAM address 
  .byte %00001111  ;b0
  .byte %00001010  ;b1
  .byte %00001111  ;b2
  .byte %00001100  ;b3
  .byte %00001110  ;b4
  .byte %00011100  ;b5
  .byte %00001010  ;b6
  .byte %00000000  ;b7
fullheartchar: 
  .byte $01  ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00001010  ;b1
  .byte %00011111  ;b2
  .byte %00011111  ;b3
  .byte %00001110  ;b4
  .byte %00000100  ;b5
  .byte %00000000  ;b6
  .byte %00000000  ;b7
emptyheartchar: 
  .byte $02  ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00001010  ;b1
  .byte %00010101  ;b2
  .byte %00010001  ;b3
  .byte %00001010  ;b4
  .byte %00000100  ;b5
  .byte %00000000  ;b6
  .byte %00000000  ;b7  


  cakechar: 
  .byte $03  ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00000000  ;b1
  .byte %00000000  ;b2
  .byte %00001010  ;b3
  .byte %00011111  ;b4
  .byte %00011111  ;b5
  .byte %00011111  ;b6
  .byte %00000000  ;b7