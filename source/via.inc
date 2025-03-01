;PURPOSE - Imports needed symbols defined in via.s
;

  .import VIA1_DDRB
  .import VIA1_PORTB
  .import VIA1_DDRA
  .import VIA1_PORTA
  .import VIA1_T1CL
  .import VIA1_T1CH
  .import VIA1_T1LL
  .import VIA1_T1LH
  .import VIA1_T2CL
  .import VIA1_T2CH
  .import VIA1_SR
  .import VIA1_ACR
  .import VIA1_PCR
  .import VIA1_IFR
  .import VIA1_IER
  .import VIA1_PANH

  .import via_init


  ;Timer values
;==========================
;1843000 / 100 = 18430 = $47FE
VIA_TIMER_10MS_18432_LOW = $FE
VIA_TIMER_10MS_18432_HIGH = $47