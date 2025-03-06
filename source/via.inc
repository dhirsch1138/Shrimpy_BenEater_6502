;PURPOSE - Imports needed symbols defined in via.s
;

  .global VIA1_DDRB
  .global VIA1_PORTB
  .global VIA1_DDRA
  .global VIA1_PORTA
  .global VIA1_T1CL
  .global VIA1_T1CH
  .global VIA1_T1LL
  .global VIA1_T1LH
  .global VIA1_T2CL
  .global VIA1_T2CH
  .global VIA1_SR
  .global VIA1_ACR
  .global VIA1_PCR
  .global VIA1_IFR
  .global VIA1_IER
  .global VIA1_PANH

  .global via_init
  .global via1_init_timer_1


;VIA defines
;==========================

;*** update this for your oscillator
VIA_TIMER_10MS_LOW = VIA_TIMER_10MS_18432_LOW
VIA_TIMER_10MS_HIGH = VIA_TIMER_10MS_18432_HIGH

;1 mhz
;1000000 / 100 = 10000 = $2710
VIA_TIMER_10MS_10000_LOW = $10
VIA_TIMER_10MS_10000_HIGH = $27

;1.843 mhz
;1843000 / 100 = 18430 = $47FE
VIA_TIMER_10MS_18432_LOW = $FE
VIA_TIMER_10MS_18432_HIGH = $47

;2 mhz
;2000000 / 100 = 20000 = $4E20
VIA_TIMER_10MS_20000_LOW = $20
VIA_TIMER_10MS_20000_HIGH = $4E