;PURPOSE - provide general utilities

;====================================================
;Exports
;nothing here

;====================================================
;Reserve RAM addresses

.segment "UTIL_RAM"
UTIL_SCRATCH_BYTE:        .res 1, $00

;====================================================
;Macros

;====================================================

;Defines

;Uncomment the appropriate delay timings for the implemented oscillator

;1 mhz
;delay for 10000 cycles, which is ~10ms @ 1 mhz
;DELAY10MS_A = $04
;DELAY10MS_B = $54

;1.843 mhz
;delay for 18430 cycles, which is ~10ms @ 1.843mhz
DELAY10MS_A = $07
DELAY10MS_B = $FD

;2 mhz
;delay for 20000 cycles, which is ~10ms @ 1 mhz
;DELAY10MS_A = $08
;DELAY10MS_B = $AB

;4 mhz
;delay for 40000 cycles, which is ~10ms @ 1 mhz
;DELAY10MS_A = $11
;DELAY10MS_B = $59

;====================================================

;Code
.segment "UTIL_CODE"


.export delay_ms_1000
.export delay_ms_500
.export delay_ms_100
.export delay_ms_50
.export delay_ms_10
.export util_joinnibbles

.include "util_macros.inc"

delay_ms_10:
;Description
;  Delays by 10 ms
;Arguments
;  None
;Preconditions
;  None
;Side Effects
;  Delays by 10ms
  phx
  ldx #$01
  bra delay_ms_deca

delay_ms_50:
;Description
;  Delays by 50 ms
;Arguments
;  None
;Preconditions
;  None
;Side Effects
;  Delays by 50ms
  phx
  ldx #$05
  bra delay_ms_deca

delay_ms_100:
;Description
;  Delays by 50 ms
;Arguments
;  None
;Preconditions
;  None
;Side Effects
;  Delays by 50ms
  phx
  ldx #$0A
  bra delay_ms_deca

delay_ms_500:
;Description
;  Delays by 500 ms
;Arguments
;  None
;Preconditions
;  None
;Side Effects
;  Delays by 50ms
  phx
  ldx #$32
  bra delay_ms_deca

delay_ms_1000:
;Description
;  Delays by 1000 ms
;Arguments
;  None
;Preconditions
;  None
;Side Effects
;  Delays by 50ms
  phx
  ldx #$64
  bra delay_ms_deca

delay_ms_deca:
;Description
;  Delays by a multiple of 10 ms
;Arguments
;  X - how many multiples of 10ms to delay
;Preconditions
;  top of the stack should be a X to pull
;Side Effects
;  Delaying for X * 10 ms
;  X is squished
  delay_macro #DELAY10MS_A, #DELAY10MS_B
  dex
  bne delay_ms_deca ; jmp
  plx
  rts

util_joinnibbles:
;Description
;  Joins two nibbles into a byte
;Arguments
;  X - low nibble as xxxx####
;  Y - high nibble as xxxx####
;Preconditions
;  none
;Side Effects
;  joined nibble put in accumulator
phx
phy
tya 
and #%00001111
swn_macro
sta UTIL_SCRATCH_BYTE
txa
and #%00001111
ora UTIL_SCRATCH_BYTE
ply
plx
rts
