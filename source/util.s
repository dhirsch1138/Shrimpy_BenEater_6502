;PURPOSE - provide general utilities

;====================================================
;Exports
;nothing here

;====================================================
;Reserve RAM addresses

;====================================================
;Macros

;====================================================

;Code
.segment "UTIL_CODE"


.export delay_ms_1000
.export delay_ms_500
.export delay_ms_100
.export delay_ms_50

.include "util_macros.inc"

;$39 $FC = 50ms @ 1.843 mhz

delay_ms_50:
  delay_macro #$39, #$FC ;delay for 92150 cycles, which is ~50ms @ 1.843mhz
  rts

delay_ms_100:
  jsr delay_ms_50
  jsr delay_ms_50
  rts

delay_ms_500:
  phx
  ldx #$05
delay_ms_500_loop:
  jsr delay_ms_100
  dex
  bne delay_ms_500_loop
  plx
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