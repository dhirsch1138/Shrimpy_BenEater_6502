;PURPOSE - provide general utilities

;Code
.segment "UTIL_CODE"

.include "util.inc"
.include "defines.inc"


.if .not .defined(DEFINE_OSCILLATOR)
.error "DEFINE_OSCILLATOR must be defined in defines.inc"
.endif

;Define the VIA 10MS timer high and low constants based on the oscillator

.if DEFINE_OSCILLATOR = 1000
;1 mhz
;delay for 10000 cycles, which is ~10ms @ 1 mhz
DELAY10MS_A = $04
DELAY10MS_B = $54
.elseif  DEFINE_OSCILLATOR = 1843
;1.843 mhz
;delay for 18430 cycles, which is ~10ms @ 1.843mhz
DELAY10MS_A = $07
DELAY10MS_B = $FD
.elseif  DEFINE_OSCILLATOR = 2000
;2 mhz
;delay for 20000 cycles, which is ~10ms @ 1 mhz
DELAY10MS_A = $08
DELAY10MS_B = $AB
.elseif  DEFINE_OSCILLATOR = 4000
;4 mhz
;delay for 40000 cycles, which is ~10ms @ 1 mhz
DELAY10MS_A = $11
DELAY10MS_B = $59
.else
.error "DEFINE_OSCILLATOR defined is not recognized, check defines.inc"
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
  jmp delay_ms_deca

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
  jmp delay_ms_deca

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
  jmp delay_ms_deca

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
  jmp delay_ms_deca

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
