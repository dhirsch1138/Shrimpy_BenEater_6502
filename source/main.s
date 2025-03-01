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
MAIN_LOOPCOUNTER:           .byte  $00
DINOSAUR_X_LOCATION:        .byte  $00
TIMERFLAG:        .byte  $00
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


;====================================================
;Defines

;update this for your oscillator
VIA_TIMER_LOW = VIA_TIMER_10MS_18432_LOW
VIA_TIMER_HIGH = VIA_TIMER_10MS_18432_HIGH



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
  bra main_loop ; jmp

setup_via_timers:
;Description
;  Defines and starts via interrupt timer(s)s
;Arguments
;  None
;Preconditions
;  None
;Side Effects
;  * Sets up the via timer T1 as a freerun generating interrupts @ 10ms
  lda #%01000000 ; timer 1 in continuous mode, not pulsing PB7
  sta VIA1_ACR
  nop ; TODO: research why this is needed further, via freaks out if I don't do this
  nop
  lda #%01111111 ; disable all interrupts
  sta VIA1_IER
  lda #%11000000 ; set interrupt - timer 1
  sta VIA1_IER
  lda #VIA_TIMER_LOW
  sta VIA1_T1LL
  lda #VIA_TIMER_HIGH
  sta VIA1_T1CH
  rts  

start_up: .asciiz "OK? "

interrupt:
;TODO: replace this with service calls lke below
  bit VIA1_T1CL ; clear
  bit TIMERFLAG
  bne @timertrue
  inc TIMERFLAG
 @timertrue: 
  rti


;service_via1:
;  bit VIA1_IFR
;  bpl @via_clear
;  bvc @via_clear
;  bit VIA1_T1CL
;@via_clear:
;  rts 

main_loop:
;Description
;  Loops forever updating lcd 
;Arguments
;  None100MS_CYCLES_HIGH
;Uses
;  DINOSAUR_X_LOCATION is the dinosaur location address
;  MAIN_LOOPCOUNTER is the loop counter
;  X delay counter
;Preconditions
;  lcd is intialized and setup for display, custom characters are loaded
;Side Effects
;  Updates LCD
  stz MAIN_LOOPCOUNTER ; lda #$00 ; sta MAIN_LOOPCOUNTER
  lda #LCD_DDRAM2LN58CR ; dino resets to the beginning of the second line of the display
  sta DINOSAUR_X_LOCATION
  lda #LCD_INST_CLRDISP ; clear the screen and reset pointers
  jsr lcd_instruction
@loop:
  jsr draw_lcd_frame
  ; update the dinosaur's location, resetting the position if it walked off the lcd
  lda DINOSAUR_X_LOCATION 
  inc
  cmp #(LCD_DDRAM2LN58CR | $10) ; IF the dinosaur's location puts it off the end of the display THEN reset it.
  bmi @skip_dino_reposition
  lda #LCD_DDRAM2LN58CR ; dino resets to the beginning of the second line of the display
@skip_dino_reposition:
  sta DINOSAUR_X_LOCATION
  ; delay and loop
  ldx #$64 ; delay for 100 timer events, which at 10ms a piece is 1 second
@delay:
  wai
  bit TIMERFLAG ; if the interrupt didn't flag the timer ignore it and continue waiting
  beq @delay
  dec TIMERFLAG ; else clear the timer flag
  dex ; decrement the counter
  bne @delay ;and continue waiting if we have more timer events
  lda #LCD_INST_CLRDISP; Clear display
  jsr lcd_instruction
  inc MAIN_LOOPCOUNTER ; increment the loop counter. 
  bra @loop ;jmp ; loop forever

.proc draw_lcd_frame
;Description
;  draws LCD frame
;Arguments
;  None
;Uses
;  DINOSAUR_X_LOCATION is the dinosaur location address
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
  ;*AA B CCCCCCCCCC *
  ;* D             E*
  ;******************
  ; AA - loop counter as hex
  ; B - animated heart
  ; C - asciiz text
  ; D - custom character (dino!) that advances across the row, resetting when it exits screen
  ; E - custom character (cake!) that gets overwritten by dinosaur                  
  phx         
  lda MAIN_LOOPCOUNTER ; use the MAIN_LOOPCOUNTER to determine the animation counter
  and #$03
  tax
  lda MAIN_LOOPCOUNTER ; write loop counter as hex
  jsr lcd_print_hex 
  lda #' '
  jsr lcd_send_byte 
  lda heart_animation,x
  jsr lcd_send_byte  
  lda #' '
  jsr lcd_send_byte
  lcd_print_asciiz_macro dinosaur_says
  ; draw bottom line by drawing dinosaur to its specific location
  lda DINOSAUR_X_LOCATION ; set the lcd cursor to the location of the dinosaur
  jsr lcd_instruction
  lda dinorightchar ; write a dinosaur
  jsr lcd_send_byte
  ; draw cake @ position 15 on second row
  lda #cake_location; compare DINOSAUR_X_LOCATION against the cake position
  cmp DINOSAUR_X_LOCATION
  beq @nocake
  jsr lcd_instruction
  lda cake_animation,x
  jsr lcd_send_byte ; write cake
@nocake:
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

dinosaur_says: .asciiz "Rwaaaar!"

.endproc ; end draw_lcd_frame

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

;custom character definitions:
;
;The datasheet says we get eight usuable custom character address that are in CGRAM (addressible in DDROM as $00 - $08)
;
;To make referencing these characters simple, I created a basic structure for 5x8 font custom character definitions
; * Offset 0    - DDRAM address
; * Offset 1-8  - bytes to write to CGRAM
;
;The primary benefit of this structure is that the program can simply reference the label when wanting to send the custom character,
;as offset 0 is the DDRAM that the custom character should be addressible at (if it was loaded)
;
;The lcd_load_custom_character_macro macro handles the translation of the DDROM address to the applicable CGRAM addresses that the character will be
;stored.
customcharset:
  .byte $06
dinorightchar:
DINORIGHTCHAR = $00 
  .byte DINORIGHTCHAR ;DDRAM address 
  .byte %00001111  ;b0
  .byte %00001010  ;b1
  .byte %00001111  ;b2
  .byte %00001100  ;b3
  .byte %00001110  ;b4
  .byte %00011100  ;b5
  .byte %00001010  ;b6
  .byte %00000000  ;b7

fullheartchar:
FULLHEARTCHAR = $01 
  .byte FULLHEARTCHAR  ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00001010  ;b1
  .byte %00011111  ;b2
  .byte %00011111  ;b3
  .byte %00001110  ;b4
  .byte %00000100  ;b5
  .byte %00000000  ;b6
  .byte %00000000  ;b7

emptyheartchar:
EMPTYHEARTCHAR = $02 
  .byte EMPTYHEARTCHAR  ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00001010  ;b1
  .byte %00010101  ;b2
  .byte %00010001  ;b3
  .byte %00001010  ;b4
  .byte %00000100  ;b5
  .byte %00000000  ;b6
  .byte %00000000  ;b7  

cakechar: 
CAKECHAR = $03
  .byte CAKECHAR  ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00000000  ;b1
  .byte %00000000  ;b2
  .byte %00001010  ;b3
  .byte %00011111  ;b4
  .byte %00010001  ;b5
  .byte %00011111  ;b6
  .byte %00000000  ;b7

cakealt1char:
CAKEALT1CHAR = $04 
  .byte CAKEALT1CHAR  ;DDRAM address 
  .byte %00000010  ;b0
  .byte %00000000  ;b1
  .byte %00000000  ;b2
  .byte %00001010  ;b3
  .byte %00011111  ;b4
  .byte %00010001  ;b5
  .byte %00011111  ;b6
  .byte %00000000  ;b7

cakealt2char:
CAKEALT2CHAR = $05 
  .byte CAKEALT2CHAR  ;DDRAM address 
  .byte %00000000  ;b0
  .byte %00000100  ;b1
  .byte %00000000  ;b2
  .byte %00001010  ;b3
  .byte %00011111  ;b4
  .byte %00010001  ;b5
  .byte %00011111  ;b6
  .byte %00000000  ;b7   