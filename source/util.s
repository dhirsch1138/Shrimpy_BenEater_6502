;PURPOSE - provide general utilities

;====================================================
;Exports
;nothing here

;====================================================
;Reserve RAM addresses

.segment "UTIL_RAM"
;====================================================
;Macros

;====================================================

;Defines

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
.include "defines.inc"

;default - if not otherwise defined default to 1 mhz timings
;delay for 10000 cycles, which is ~10ms @ 1 mhz
.if     .defined(DELAY10MS_A)
.else
DELAY10MS_A = $04
.endif
.if     .defined(DELAY10MS_B)
.else
DELAY10MS_B = $54
.endif


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
  ; continue executing into delay_ms_deca ; bra delay_ms_deca

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
@loop:
  delay_macro #DELAY10MS_A, #DELAY10MS_B
  dex
  bne @loop ; jmp
  plx
  rts

util_joinnibbles:
;Description
;  Joins two nibbles into a byte
;Arguments
;  A - high nibble as xxxx####
;  X - low nibble as xxxx####
;Preconditions
;  none
;Side Effects
;  joined nibble put in accumulator
  pha
  txa ; accumulator - xxxx####
  sec ; set sentinel bit in carry flag
  rol ; rotate it into the accumulator, which is now xxx####1
  asl ; accumulator -  xx####10
  asl ; accumulator -  x####100
  asl ; accumulator -  ####1000
  asl ; shift the highest bit into carry flag
@loop:
  tax ; carry flag not impacted by tax
  pla ; carry flag not impacted by pla
  rol ; rotate carry bit into least bit of what was previous the high nibble
  pha
  txa
  asl ; shift the highest bit into carry flag, also sets the zero flag if appropriate.
  bne @loop ; if the accumulator has the zero flag, that means we've shifted the sentinel bit into carry and we're done
  pla
  rts
