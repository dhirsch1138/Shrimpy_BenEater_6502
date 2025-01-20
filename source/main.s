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
DINO_LOCATION:        .res 1, $00
;Description: used to store the location of the dinosaur in the LCD's DDRAM

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
  lda #(LCD_INST_FUNCSET | LCD_FUNCSET_LINE); Set 4-bit mode; 2-line display; 5x8 font
  jsr lcd_instruction
  lda #(LCD_INST_DISPLAY | LCD_DISPLAY_DSON | LCD_DISPLAY_CUON); Display on; cursor on; blink off
  jsr lcd_instruction
  lda #(LCD_INST_DISPLAY | LCD_DISPLAY_DSON); Display on; cursor off; blink off
  jsr lcd_instruction
  lda #(LCD_INST_ENTRYMO | LCD_ENTRYMO_INCR); Increment and shift cursor; don't shift display
  jsr lcd_instruction
  load_addr_to_zp_macro dinochar, LCD_ADDR_ZP ;set dinochar as the next LCD_ADDR_ZP
  jsr lcd_load_custom_character ;load dinochar as a custom character 
  lda #LCD_INST_RTNHOME
  jsr lcd_instruction
  lda #LCD_INST_CLRDISP ; Clear display
  jsr lcd_instruction
  stz MAIN_LOOP_COUNT
  ; presumes we will continue executing into 'main_loop'

main_loop:
;Description
;  Loops forever updating lcd 
;Arguments
;  None
;Preconditions
;  lcd is intialized and setup for display, custom characters are loaded
;Side Effects
;  Updates LCD
  lda #LCD_SETDDRAMADDR ; DDRAM location for the beginning of the second line
  sta DINO_LOCATION ;dino starts at the beginning of the second line of the display
loop:
  lda MAIN_LOOP_COUNT
  jsr lcd_print_hex
  lda #$20 ;space
  jsr lcd_send_byte
  load_addr_to_zp_macro dinosaur_says, LCD_ADDR_ZP ;load the address of addr to LCD_ADDR_ZP ZP word
  jsr lcd_print_asciiz_ZP ;print the LCD_ADDR_ZP ZP word on the LCD
  lda DINO_LOCATION ; set dinosaur location
  jsr lcd_instruction
  lda dinochar ;dino char set (offset 0 is the address!)
  jsr lcd_send_byte
  inc DINO_LOCATION
  lda DINO_LOCATION
  cmp #(LCD_SETDDRAMADDR | %00010000) ;if dino gets to end of line (16 characters) reset it
  bmi loop_delay
  lda #LCD_SETDDRAMADDR; DDRAM location for the beginning of the second line
  sta DINO_LOCATION ;reset dino to beginning of the second line of the display
loop_delay:
  lda #$02 ; delay for ~1 second
loop_delay_half_second:
  delay_macro #$d9, #$01 ;delay for 500003 cycles, which is ~500ms @ 1mhz
  dea
  bne loop_delay_half_second 
  lda #LCD_INST_CLRDISP; Clear display
  jsr lcd_instruction
  inc MAIN_LOOP_COUNT 
  bra loop ;jmp


dinosaur_says: .asciiz "Rwaaaar!"
dinochar: .byte %00000000, %00001111, %00001010, %00001111, %00001100, %00001110, %00011100, %00001010, %00000000
;Offset 0    - CGRAM address
;Offset 1-8  - values to write to CGRAM
