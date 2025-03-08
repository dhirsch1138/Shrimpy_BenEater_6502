;PURPOSE - implement a basic bit-bang SPI interface

;TODO NONE OF THIS HAS BEEN IMPLEMENTED OR TESTED, I JUST SLAPPED THE CODE HERE AS A PLACEHOLDER

;Awesome algorithm by Jeff Laughton (http://forum.6502.org/viewtopic.php?p=45555#p45555), with tweaks
;by Paul Dorish (https://www.youtube.com/watch?v=siKiNMOqcDA https://github.com/dourish/mitemon/blob/master/apps/spiv.a65)

;this has been adapted and modified from the originals by github.com/dhirsch1138

.segment "SPI_CODE"

;Includes
.include "via.inc"

;;;Paul Dorish's wiring
;;; Wiring details:
; Uses PORT B of VIA1
;;;   CLK is PA0, ie 1
;;;   MOSI is PA1, ie 2
;;;   CS is PA2, ie 4
;;;   RESET      PA5, ie 32
;;;   MISO is PA7, which maps onto S flag on BIT (test with BPL and BMI)
;;;
;;; MISO, MOSI, and CS all have pull-up resisters, so they are high in
;;; the idle/unused state, except when pulled low by active circuitry.


SPI_CLK  =     %00000001 ;1
SPI_MOSI =     %00000010 ;2
SPI_CS =       %00000100 ;4
;8 (nc)
;16 (nc)
SPI_RESET =    %00100000 ;32
SPI_MISO =     %10000000 ;128

SPI_PORT = VIA1_PORTA

SPI_INIT:
  ;;; set up data direction for SPI_PORT -- bits 0, 1, 2, and 5 are
  ;;; outputs and bits 3(nc), 4, 6 (nc), and 7 are inputs.
;TODO:Review the DDR & define mask, currenly conflicting w/ LCD
  lda #%01100111
  sta VIA1_DDRB
  lda #SPI_MOSI|SPI_RESET|SPI_CS
  sta SPI_PORT
  rts

SPI_BYTEIN:
  LDA #1          ;LDA #1 is for counting

INPUTLOOP:
  STZ SPI_PORT  ;set Ck=0, mosi=0
  INC SPI_PORT  ;set Ck=1    INC DOES 2 THINGS (sets Ck; also updates N flag per MISO)
  BPL MISO_IS_0

  SEC             ;MISO is =1
  ROL A
  BCC INPUTLOOP   ;more bits?
  RTS

MISO_IS_0:
  ASL A           ;MISO is =0
  BCC INPUTLOOP   ;more bits?
  RTS

SPI_BYTEOUT:
  phy
  phx
  LDY #SPI_MOSI ;Y is used to hold MOSI 1
  LDX $00 ;X is used to hold MOSI 0
  SEC             ;SEC / ROL A is for counting
  ROL A
OUTPUTLOOP:
  ;command pulse would go here, IF A = 128 (%100000000) THEN all this is the last bit & the command pulse should fire
  BCS MOSI_1
  STX SPI_PORT ;STZ SPI_PORT ;ck=0, mosi=0  STX updates both Ck & mosi
  INC SPI_PORT ;ck=1
  ASL A
  BNE OUTPUTLOOP  ;more bits?
  RTS

MOSI_1:
  STY SPI_PORT  ;ck=0, mosi=1  STY updates both Ck & mosi
  INC SPI_PORT  ;ck=1
  ASL A
  BNE OUTPUTLOOP ;more bits?
  plx
  ply
  RTS  