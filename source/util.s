;PURPOSE - provide general utilities

;====================================================
;Exports
;nothing here

;====================================================
;Reserve RAM addresses

;====================================================
;Macros

;====================================================

;Defines

;Uncomment the appropriate timings to get delays for PHI2 frequence

;1.843
;delay for 18430 cycles, which is 10ms @ 1.843mhz
DELAY10MS_A = $07
DELAY10MS_B = $FD



;====================================================

;Code
.segment "UTIL_CODE"


.export delay_ms_1000
.export delay_ms_500
.export delay_ms_100
.export delay_ms_50
.export delay_ms_10

.include "util_macros.inc"

delay_ms_10:
  delay_macro #DELAY10MS_A, #DELAY10MS_B
  rts

delay_ms_50:
  jsr delay_ms_10
  jsr delay_ms_10
  jsr delay_ms_10
  jsr delay_ms_10
  jsr delay_ms_10
  rts

delay_ms_100:
  jsr delay_ms_50
  jsr delay_ms_50
  rts

delay_ms_500:
  jsr delay_ms_100
  jsr delay_ms_100
  jsr delay_ms_100
  jsr delay_ms_100
  jsr delay_ms_100
  rts

delay_ms_1000:
  phx
  ldx #$0A
delay_ms_1000_loop:
  jsr delay_ms_100
  dex
  bne delay_ms_1000_loop
  plx
  rts