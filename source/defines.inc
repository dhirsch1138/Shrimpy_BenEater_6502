
;Utilty defines

;update this for your oscillator
DELAY10MS_A = DELAY10MS_1843_A
DELAY10MS_B = DELAY10MS_1843_B

;1 mhz
;delay for 10000 cycles, which is ~10ms @ 1 mhz
DELAY10MS_1000_A = $04
DELAY10MS_1000_B = $54

;1.843 mhz
;delay for 18430 cycles, which is ~10ms @ 1.843mhz
DELAY10MS_1843_A = $07
DELAY10MS_1843_B = $FD

;2 mhz
;delay for 20000 cycles, which is ~10ms @ 1 mhz
DELAY10MS_2000_A = $08
DELAY10MS_2000_B = $AB

;4 mhz
;delay for 40000 cycles, which is ~10ms @ 1 mhz
DELAY10MS_4000_A = $11
DELAY10MS_4000_B = $59


;VIA defines
;==========================

;update this for your oscillator
VIA_TIMER_10MS_LOW = VIA_TIMER_10MS_18432_LOW
VIA_TIMER_10MS_HIGH = VIA_TIMER_10MS_18432_HIGH

;1843000 / 100 = 18430 = $47FE
VIA_TIMER_10MS_18432_LOW = $FE
VIA_TIMER_10MS_18432_HIGH = $47