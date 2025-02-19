;PURPOSE - provide general utilities

;Code
.segment "UTIL_CODE"


.export delay_ms_1000
.export delay_ms_500
.export delay_ms_100
.export delay_ms_50

.include "util_macros.inc"


delay_ms_50:
  delay_macro #$6C, #$01 ;delay for 100001 cycles, which is ~50ms @ 1.843mhz
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
  ldx #$A0
delay_ms_1000_loop:
  jsr delay_ms_100
  dex
  bne delay_ms_1000_loop
  plx
  rts