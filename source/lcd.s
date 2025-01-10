;PURPOSE - defines the static register references & lcd functions 
;  interface as provided by Ben Eater's videos https://eater.net/6502


.export LCD_4BIT_E
.export LCD_4BIT_RW
.export LCD_4BIT_RS

LCD_4BIT_E  = %01000000
LCD_4BIT_RW = %00100000
LCD_4BIT_RS = %00010000
