;PURPOSE - defines the static register references for the via interface as provided by Ben Eater's videos https://eater.net/6502
;
;This file was based on https://github.com/dbuchwald/cc65-tools/blob/main/tutorial/03_blink/blink.s (aside from the comments)

;====================================================
;Exports
  .import __VIA1_START__

  .export VIA1_PORTB
  .export VIA1_PORTA
  .export VIA1_DDRB
  .export VIA1_DDRA
  .export VIA1_T1CL
  .export VIA1_T1CH
  .export VIA1_T1LL
  .export VIA1_T1LH
  .export VIA1_T2CL
  .export VIA1_T2CH
  .export VIA1_SR
  .export VIA1_ACR
  .export VIA1_PCR
  .export VIA1_IFR
  .export VIA1_IER
  .export VIA1_PANH

  .export via_init

  .export via1_init_timer_1

VIA_REGISTER_PORTB = $00
VIA_REGISTER_PORTA = $01
VIA_REGISTER_DDRB  = $02
VIA_REGISTER_DDRA  = $03
VIA_REGISTER_T1CL  = $04
VIA_REGISTER_T1CH  = $05
VIA_REGISTER_T1LL  = $06
VIA_REGISTER_T1LH  = $07
VIA_REGISTER_T2CL  = $08
VIA_REGISTER_T2CH  = $09
VIA_REGISTER_SR    = $0a
VIA_REGISTER_ACR   = $0b
VIA_REGISTER_PCR   = $0c
VIA_REGISTER_IFR   = $0d
VIA_REGISTER_IER   = $0e
VIA_REGISTER_PANH  = $0f

VIA1_PORTB = __VIA1_START__ + VIA_REGISTER_PORTB
VIA1_PORTA = __VIA1_START__ + VIA_REGISTER_PORTA
VIA1_DDRB  = __VIA1_START__ + VIA_REGISTER_DDRB
VIA1_DDRA  = __VIA1_START__ + VIA_REGISTER_DDRA
VIA1_T1CL  = __VIA1_START__ + VIA_REGISTER_T1CL
VIA1_T1CH  = __VIA1_START__ + VIA_REGISTER_T1CH
VIA1_T1LL  = __VIA1_START__ + VIA_REGISTER_T1LL
VIA1_T1LH  = __VIA1_START__ + VIA_REGISTER_T1LH
VIA1_T2CL  = __VIA1_START__ + VIA_REGISTER_T2CL
VIA1_T2CH  = __VIA1_START__ + VIA_REGISTER_T2CH
VIA1_SR    = __VIA1_START__ + VIA_REGISTER_SR
VIA1_ACR   = __VIA1_START__ + VIA_REGISTER_ACR
VIA1_PCR   = __VIA1_START__ + VIA_REGISTER_PCR
VIA1_IFR   = __VIA1_START__ + VIA_REGISTER_IFR
VIA1_IER   = __VIA1_START__ + VIA_REGISTER_IER
VIA1_PANH  = __VIA1_START__ + VIA_REGISTER_PANH

;====================================================
;Reserve RAM addresses
;nothing here

;====================================================
;Includes
  .include "defines.inc"

;====================================================
;Macros
;nothing here

;====================================================
;Code
.segment "VIA_CODE"

;default - if not otherwise defined default to 1 mhz timings
;1000000 / 100 = 10000 = $2710
.if     .defined(VIA_TIMER_10MS_LOW)
.else
VIA_TIMER_10MS_LOW = $10
.endif
.if     .defined(VIA_TIMER_10MS_HIGH)
.else
VIA_TIMER_10MS_HIGH = $27
.endif

via_init:
;Description
;  sets all the known via to input states
;Arguments
;  None
;Preconditions
;  None, but via should be awake
;Side Effects
;  * all known via ports are set to input
;Notes
;  Decided on input as the default as it might prevent us from accidentally setting the wrong pin high and creating
;  magic smoke
  lda #%00000000
  sta VIA1_DDRA
  sta VIA1_DDRB
  lda #%00000000 ; set the ACR to a known starting state
  sta VIA1_ACR
  nop ; TODO: research why this is needed further, via freaks out if I don't do this
  nop
  lda #%01111111 ; disable all interrupts
  sta VIA1_IER
  rts

via1_init_timer_1:
;Description
;  sets up timer 1
;Arguments
;  Accumulator lowest two bits as T1 ACR values
;   $00 = %00 = Timed interrupt each time T1 is loaded. PB7 disabled
;   $01 = %01 = Continuous interrupts. PB7 disabled
;   $02 = %10 = Timed interrupt each time T1 is loaded. One shot PB7
;   $03 = %11 = Continuous interrupts. Square wave output
;  (reference page 16 of w65c22 datasheet)
;Preconditions
;  None, but via should be awake
;Uses
;  X - argument
;Side Effects
;  * timer is loaded & started by updating the top two bits of the ACR with the argument
  phx
  tax ; put argument in X - %xxxxxxAB
  lda VIA1_ACR ; load ACR
  asl ; shift ACR left pulling off D7 %6543210x
  asl ; shift ACR left pulling off D6 %543210xx
  pha ; push ACR onto stack
  txa ; get argument %xxxxxxAB
  ror ; rotate right to put lowest argument bit into carry bit - %xxxxxxxA - B
  tax ; put argument back into x
  pla ; pull ACR onto stack
  ror ; rotate the carry bit onto the ACR - %B543210x
  pha ; push the ACR onto stack
  txa ; put the remaining argument back into x
  ror ; rotate right to put the higher argument bit into the carry bit - %xxxxxxxx - A
  pla ; pull the ACR onto the stack
  ror ; rotate the carry bit onto the ACR - %AB543210
  sta VIA1_ACR ; store the new ACR
  nop ; TODO: research why this is needed further, via freaks out if I don't do this
  nop
  lda #%11000000 ; set interrupt - timer 1
  sta VIA1_IER
  lda #VIA_TIMER_10MS_LOW
  sta VIA1_T1LL
  lda #VIA_TIMER_10MS_HIGH
  sta VIA1_T1CH
  plx
  rts
