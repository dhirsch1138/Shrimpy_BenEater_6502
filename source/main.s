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
;  * Custom dinosaur character loaded to lcd
;   
  ldx #$ff
  txs
  jsr delay_ms_100 ; give the board time to come up
  jsr via_init ; setup the via
  jsr delay_ms_100 ; give the lcd a bit more time before we ask it to do work
  jsr lcd_init_4bit ; init the lcd in 4 bit mode
  jsr delay_ms_100 ; this is overly conservative, might remove this
  ; Execute LCD parameter initialization sequence
  ; got this idea from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s
  ; initialize index to walk through sequence
  ldx #$00
main_lcd_init_sequence_loop:
  jsr delay_ms_100
  lda main_lcd_init_sequence,x ; Read next byte of force reset sequence data
  beq main_lcd_init_sequence_end ; Exit loop if $00 read
  jsr lcd_instruction
  inx 
  bra main_lcd_init_sequence_loop
main_lcd_init_sequence_end:
  jsr delay_ms_100 
  ;load custom character(s)
  load_addr_to_zp_macro dinochar, LCD_ADDR_ZP ;set dinochar as the next LCD_ADDR_ZP
  jsr lcd_load_custom_character ;load dinochar as a custom character
  bra main_loop ; jmp

main_lcd_init_sequence:
; got this idea from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s
  .byte LCD_INST_FUNCSET | LCD_FUNCSET_LINE ; #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  .byte LCD_INST_DISPLAY | LCD_DISPLAY_DSON ; #%00001100 ; Display on; cursor off; blink off
  .byte LCD_INST_ENTRYMO | LCD_ENTRYMO_INCR ; #%00000110 ; Increment and shift cursor; don't shift display
  .byte LCD_INST_CLRDISP ; %00000001 ; Clear display
  .byte LCD_INST_RTNHOME ; return cursor home
  .byte $00

main_loop:
;Description
;  Loops forever updating lcd 
;Arguments
;  None
;Uses
;  Y is the dinosaur location address
;  X is the loop counter
;Preconditions
;  lcd is intialized and setup for display, custom characters are loaded
;Side Effects
;  Updates LCD
  ldx #$00
  ldy #LCD_DDRAM2LN48CR ;dino starts at the beginning of the second line of the display
loop:
  txa ; get the loop count
  jsr lcd_print_hex
  lda #$20 ;space
  jsr lcd_send_byte
  load_addr_to_zp_macro dinosaur_says, LCD_ADDR_ZP ;load the address of addr to LCD_ADDR_ZP ZP word
  jsr lcd_print_asciiz_ZP ;print the LCD_ADDR_ZP ZP word on the LCD
  tya ; set dinosaur location
  jsr lcd_instruction
  lda dinochar ;dino char set (offset 0 is the address!)
  jsr lcd_send_byte
  iny ; increase dinosaur location
  cpy #(LCD_DDRAM2LN48CR | %00010000) ;if dino gets to end of line (16 characters) reset it
  bmi loop_delay
  ldy #LCD_DDRAM2LN48CR ;reset dino to beginning of the second line of the display
loop_delay:
  jsr delay_ms_1000 ; dino moves once a second
  lda #LCD_INST_CLRDISP; Clear display
  jsr lcd_instruction
  jsr delay_ms_10
  inx
  bra loop ;jmp


dinosaur_says: .asciiz "Rwaaaar!"
dinochar: .byte %00000000, %00001111, %00001010, %00001111, %00001100, %00001110, %00011100, %00001010, %00000000
;Offset 0    - CGRAM address
;Offset 1-8  - values to write to CGRAM
