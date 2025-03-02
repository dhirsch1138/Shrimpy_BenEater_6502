;PURPOSE -  main code file
;
; adaptation from Ben Eater's keyboard.s https://eater.net/downloads/keyboard.s
; mostly I am using it to learn to talk to the lcd in 4-bit mode
;

;====================================================
;Exports
.export interrupt
.export reset

;====================================================
;Reserve RAM addresses
.segment "MAIN_RAM"
MAIN_LOOPCOUNTER:        .byte  $00
RTC_CLOCK:               .dword  $00 ; four bytes
RTC_DELAY_TARGET:        .dword  $00 ; four bytes
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
  .include "defines.inc"
  .include "util_macros.inc"
  .include "util.inc"  
  .include "characters.inc"


;====================================================
;Defines


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
  sei
  cld ; not required for a cmos CPU but why not
  ldx #$ff
  txs
  jsr via_init ; setup the via
  jsr setup_lcd ; setup the lcd
  lda #LCD_INST_CLRDISP ; clear the screen and reset pointers
  jsr lcd_instruction
  lcd_print_asciiz_macro start_up
  jsr setup_via_timers
  lda #'T'
  jsr lcd_send_byte   
  cli
  lda #'I'
  jsr lcd_send_byte
  jmp main_loop

setup_via_timers:
;Description
;  Defines and starts via interrupt timer(s)
;Arguments
;  None
;Preconditions
;  None
;Side Effects
;  * Sets up the via timer T1 as a freerun generating interrupts @ 10ms
;  * squishes A
  lda #$00
  sta RTC_CLOCK
  sta RTC_CLOCK + 1
  sta RTC_CLOCK + 2
  sta RTC_CLOCK + 3
  lda #$01
  jsr via1_init_timer_1 ; setup timer 1 on via 1 as a continuous timer that w/ PB7 pulsing disabled.
  rts  

start_up: .asciiz "OK? "

interrupt:
;Description
;  Handles interrupts.
;Arguments
;  None
;Preconditions
;  None
;Side Effects
;  Handles and (hopefully) clears interrupts
  jsr service_via1
interrupt_cleared:  
  rti


service_via1:
;DescriptionRTC_CLOCK
;  Looks for and handles interrupts from via1
;Arguments
;  None
;Preconditions
;  invoked as part of the interrup handler
;Side Effects
;  Handles:
;    * T1 interrupts - setting TIMERFLAG if is not already set
  bit VIA1_IFR ; if the interrupt didn't come from via then fallback
  bpl @via_clear
  bvc @not_t1 ; if the interrupt didn't come from timer one then continue checking
  ;interrupt is from timer1
  bit VIA1_T1CL ; clear t1 interrupt by reading from lower order counter
  inc_dword_at_addr_macro RTC_CLOCK
  bra @via_clear ; jmp
@not_t1: ; other interrupts would be handled here
@via_clear: ; once all interrupts for via1 have been accounted for
  rts 

main_loop:
;Description
;  Loops forever updating lcd 
;Arguments
;  None
;Uses
;  MAIN_LOOPCOUNTER is the loop counter
;Preconditions
;  lcd is intialized and setup for display, custom characters are loaded
;Side Effects
;  Updates LCD
  lda #$00
  sta RTC_DELAY_TARGET
  sta RTC_DELAY_TARGET + 1
  sta RTC_DELAY_TARGET + 2
  sta RTC_DELAY_TARGET + 3
  sta MAIN_LOOPCOUNTER ; lda #$00 ; sta MAIN_LOOPCOUNTER
  lda #LCD_INST_CLRDISP ; clear the screen and reset pointers
  jsr lcd_instruction
@loop:
  jsr draw_lcd_frame ; update the lcd
  sei ; quiet interrupt long enough to grab the clock and copy it into RTC_DELAY_TARGET
  copy_dwords_at_addrs_macro RTC_CLOCK, RTC_DELAY_TARGET ; copy clock into our delay target
  cli
  adc_dword_at_addr_macro RTC_DELAY_TARGET, #$64 ; increment delay target, mind it is a 32 bit number
@delay:
  wai
  sei ; quiet interrupt while we compare clock
  lda RTC_CLOCK + 3 ; starting with the highest byte of the 32 bit RTC_CLOCK, see if we have equaled or surpased or delay target
  cmp RTC_DELAY_TARGET + 3
  bmi @continue_delay
  lda RTC_CLOCK + 2
  cmp RTC_DELAY_TARGET + 2
  bmi @continue_delay
  lda RTC_CLOCK + 1
  cmp RTC_DELAY_TARGET + 1
  bmi @continue_delay  
  lda RTC_CLOCK
  cmp RTC_DELAY_TARGET
  bmi @continue_delay
  bra @end_delay
@continue_delay:
  cli
  bra @delay
@end_delay:
  cli    
  lda #LCD_INST_CLRDISP; Clear display
  jsr lcd_instruction
  inc MAIN_LOOPCOUNTER ; increment the loop counter. 
  jmp @loop ; loop forever

.proc draw_lcd_frame
;Description
;  draws LCD frame
;Arguments
;  None
;Uses
;  MAIN_LOOPCOUNTER is the loop counter
;  X - animation counter 0-3
;Preconditions
;  lcd is intialized and setup for display, custom characters are loaded
;  expected to be cleared already
;Side Effects
;  Updates LCD
;  squishes A
;
  ; Expected LCD
  ;******************
  ;* B CCC AAAAAAAA *
  ;* D             E*
  ;******************
  ; AA - RTC_CLOCK counter as dword (32 bit) hex
  ; B - animated heart
  ; C - asciiz text
  ; D - custom character (dino!) that advances across the row, resetting when it exits screen
  ; E - custom character (cake!) that gets overwritten by dinosaur                  
  phx         
  lda MAIN_LOOPCOUNTER ; use the MAIN_LOOPCOUNTER to determine the animation counter
  and #$03
  tax
  lda heart_animation,x
  jsr lcd_send_byte  
  lda #' '
  jsr lcd_send_byte
  lcd_print_asciiz_macro tick_label
  lda RTC_CLOCK + 3 ; write RTC counter as hex, all four bytes
  jsr lcd_print_hex
  lda RTC_CLOCK + 2 ; write RTC counter as hex, all four bytes
  jsr lcd_print_hex
  lda RTC_CLOCK + 1 ; write RTC counter as hex, all four bytes
  jsr lcd_print_hex
  lda RTC_CLOCK ; write RTC counter as hex, all four bytes
  jsr lcd_print_hex     
  ; draw bottom line by drawing dinosaur to its specific location
  lda MAIN_LOOPCOUNTER ; get the dinosaur position from the bottom nibble of the counter (0-15)
  and #$0F
  ora #LCD_DDRAM2LN58CR ; put the dinosaur on the second row with this mask
  pha ; push dinosaur position to stack
  cmp #cake_location; compare dinosaur address against the cake position address
  beq @nocake ; do not display cake if dinosaur overlaps
  lda #cake_location; compare DINOSAUR_X_LOCATION against the cake position
  jsr lcd_instruction
  lda cake_animation,x
  jsr lcd_send_byte ; write cake
@nocake: 
  pla ; pull dinosaur position from stack
  jsr lcd_instruction
  lda dinorightchar ; write a dinosaur
  jsr lcd_send_byte
  plx
  rts

cake_location = LCD_DDRAM2LN58CR | $0F

cake_animation:
  .byte CAKECHAR
  .byte CAKECHAR
  .byte CAKEALT2CHAR
  .byte CAKEALT1CHAR

heart_animation:
  .byte EMPTYHEARTCHAR
  .byte FULLHEARTCHAR
  .byte FULLHEARTCHAR
  .byte FULLHEARTCHAR

tick_label: .asciiz "RTC : "

.endproc ; end draw_lcd_frame

.proc setup_lcd ; label &import
;Side Effects
;  * LCD is initialized
;  * LCD parameters are set
;  * customer characters are loaded
;  * A is squished
;Notes
;  the character loading is redundant, but I wanted to see if I could load character sets and single characters
  jsr lcd_init ; init the lcd in 4 bit mode
  lcd_foreach_instruction_macro instructions, jsr lcd_instruction; specify the lcd parameters for this program
  lcd_load_custom_character_list_macro customcharset
  rts

instructions:
; got this idea from Dawid Buchwald @ https://github.com/dbuchwald/6502/blob/master/Software/common/source/lcd4bit.s
  .byte LCD_INST_FUNCSET | LCD_FUNCSET_LINE ; #%00101000 ; Set 4-bit mode; 2-line display; 5x8 font
  .byte LCD_INST_DISPLAY | LCD_DISPLAY_DSON ; #%00001100 ; Display on; cursor off; blink off
  .byte LCD_INST_ENTRYMO | LCD_ENTRYMO_INCR ; #%00000110 ; Increment and shift cursor; don't shift display
  .byte LCD_INST_CLRDISP ; %00000001 ; Clear display
  .byte $00

.endproc