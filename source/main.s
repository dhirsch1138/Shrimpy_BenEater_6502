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
  jsr lcd_init ; init the lcd in 4 bit mode
  jsr set_lcd_params ; specify the lcd parameters for this program
  jsr load_lcd_custom_characters ; load custom characters to the lcd
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
  lda #LCD_DDRAM2LN58CR
  sta DINOSAUR_X_LOCATION ;dino starts at the beginning of the second line of the display
  lda #LCD_INST_CLRDISP ; clear the screen and reset pointers
  jsr lcd_instruction
@loop:
  lda MAIN_LOOPCOUNTER ; write loop counter as hex
  jsr lcd_print_hex 
  lda #$20 ; write space " "
  jsr lcd_send_byte  
  lda heartchar ; write heart customer character
  jsr lcd_send_byte  
  lda #$20 ; write space " "
  jsr lcd_send_byte
  load_addr_to_zp_macro dinosaur_says, LCD_ADDR_ZP ; load the address of nul terminated string (asciiz) to LCD_ADDR_ZP ZP word
  jsr lcd_print_asciiz_ZP ; send the asciiz that LCD_ADDR_ZP is pointing to the LCD
  lda DINOSAUR_X_LOCATION ; set the lcd cursor to the location of the dinosaur
  jsr lcd_instruction
  lda dinochar ; write the dinosaur customer character
  jsr lcd_send_byte
  inc DINOSAUR_X_LOCATION ; increment the dinosaur location
  lda DINOSAUR_X_LOCATION ; IF the dinosaur's location puts it off the end of the display THEN reset it.
  cmp #(LCD_DDRAM2LN58CR | %00010000) ; the display is sixteen characters, so if position is not 16 (0 indexed) then it doesn't need a reposition
  bmi @skip_dino_reposition
  lda #LCD_DDRAM2LN58CR
  sta DINOSAUR_X_LOCATION
@skip_dino_reposition:
  jsr delay_ms_1000 ; wait one second, this whole loop should take ~1 second (recognize that the actual instructions will make it take longer of course)
  lda #LCD_INST_CLRDISP; Clear display
  jsr lcd_instruction
  inc MAIN_LOOPCOUNTER ; increment the loop counter. 
  bra @loop ;jmp

dinosaur_says: .asciiz "Rwaaaar!"

.proc set_lcd_params ; label + scope (This isn't required, I am just experimenting w/ ca65 functionality)
;Description
;  sets the initial operating parameters for this program
;Arguments
;  None
;Preconditions
;  lcd should be initialized
;Side Effects
;  initial operating parameters for LCD are setup
;   
; Execute LCD parameter initialization sequence
; got this idea from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s
; initialize index to walk through sequence
  ldx #$00
@loop:
  lda instructions,x ; Read next byte of force reset sequence data
  beq @loop_end ; Exit loop if $00 read
  jsr lcd_instruction
  inx 
  bra @loop
@loop_end:
  rts

instructions:
; got this idea from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s
  .byte LCD_INST_FUNCSET | LCD_FUNCSET_LINE ; #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  .byte LCD_INST_DISPLAY | LCD_DISPLAY_DSON ; #%00001100 ; Display on; cursor off; blink off
  .byte LCD_INST_ENTRYMO | LCD_ENTRYMO_INCR ; #%00000110 ; Increment and shift cursor; don't shift display
  .byte LCD_INST_CLRDISP ; %00000001 ; Clear display
  .byte $00

.endproc ; end of set_lcd_params scope


load_lcd_custom_characters:
;Description
;  Loads custom character definitions into the lcd CGRAM
;Arguments
;  None
;Preconditions
;  LCD should be fully initialized and set to 5x8 font mode
;Side Effects
;  Custom characters are loaded to lcd
  load_addr_to_zp_macro dinochar, LCD_ADDR_ZP ;set dinochar as the next LCD_ADDR_ZP
  jsr lcd_load_custom_character ;load dinochar as a custom character
  load_addr_to_zp_macro heartchar, LCD_ADDR_ZP ;set dinochar as the next LCD_ADDR_ZP
  jsr lcd_load_custom_character ;load dinochar as a custom character
  rts

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
dinochar: 
  .byte $00 ;DDRAM address 
  .byte %00001111  ;b0
  .byte %00001010  ;b1
  .byte %00001111  ;b2
  .byte %00001100  ;b3
  .byte %00001110  ;b4
  .byte %00011100  ;b5
  .byte %00001010  ;b6
  .byte %00000000  ;b7
heartchar: 
  .byte $01  ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00001010  ;b1
  .byte %00011111  ;b2
  .byte %00011111  ;b3
  .byte %00001110  ;b4
  .byte %00000100  ;b5
  .byte %00000000  ;b6
  .byte %00000000  ;b7