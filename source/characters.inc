;PURPOSE - Imports needed symbols defined in characters.s

;import custom char set addresses
.global customcharset

;import custom char def addresses
.global dinorightchar
.global dinorightcharalt
.global fullheartchar
.global emptyheartchar
.global cakechar
.global cakealt1char
.global cakealt2char
.global cakealt3char

;declare custom char DDRAM symbols
CAKEALT3CHAR = $06
CAKEALT2CHAR = $05
CAKEALT1CHAR = $04
CAKECHAR = $03
EMPTYHEARTCHAR = $02
FULLHEARTCHAR = $01
DINORIGHTCHAR = $00
DINORIGHTCHARALT = $07