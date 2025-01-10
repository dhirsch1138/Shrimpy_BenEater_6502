;PURPOSE - This is the code which will written to ROM at $0000 (but will be referenced by the Ben Eater 6502 as $8000)
;
;adaptation of https://github.com/dbuchwald/cc65-tools/blob/main/tutorial/03_blink/blink.s by dbuchwald
;
;The first difference we'll see is the inclusion of other source files (note they do not have .s extensions, we do not want
;them assembled as their own objects). 
; ca65 documentaiton: https://cc65.github.io/doc/ca65.html#ss11.66
;It works like you'd expect an include, the assembler will combine the included files with the source before assembling.
;
;Include the via import file (defining the imports there and keeping this source clean)
  .include "via.s_imports"
 ;
 ;BE AWARE THAT LOCATION MATTERS FOR INCLUDED CONTENT, YOU MAY BE BETTER SERVED ADDING YOUR INCLUDED CONTENT ELSEWHERE
 ;LIKE AT THE END OF THE CODE.
 ;
 ;The reset vector will be included at the end of the
 ;
 ;
 ;
 ;Aside from the obvious inclusion of the included files, the next big difference we'll see is that
 ;the ".org $8000" is gone and replaced with just ".code"
 ;
 ;This is another thing we get from cc65 https://cc65.github.io/doc/ca65.html#.CODE
 ;
 ;It is basically a hard coded SEGMENT https://cc65.github.io/doc/ca65.html#.SEGMENT that always gets created for the code.
 ;
 ;What does the compiler do with all this? Let me take a bit from the generated build\output\output.map
 ;file that the compiler creates for us when we do a "make all" (do it yourself on this example to see the full file)
 
 ;Segment list:
 ;-------------
 ;Name                   Start     End    Size  Align
 ;----------------------------------------------------
 ;CODE                  008000  008010  000011  00001
 ;VECTORS               00FFFA  00FFFF  000006  00001

 ;We can see that the CODE address space starts at 08000 (and for this program, ends at 008010). But where
 ;are we, as the programmer, defining this? The linker configuration files <filename>.cfg
 ; reference: https://cc65.github.io/doc/ld65.html
 ;  
 ;MEMORY
 ;{
 ; VIA:       start=$6000, size=$0010, type=rw, define=yes;
 ; ROM:       start=$8000, size=$8000, type=ro, define=yes, fill=yes,   fillval=$00, file=%O;
 ;}

 ;SEGMENTS
 ;{
 ; CODE:      load=ROM,       type=ro,  define=yes;
 ; VECTORS:   load=ROM,       type=ro,  define=yes,   offset=$7ffa, optional=yes;
 ;}
 ;
 ;So we can see that CODE is a memory segment, that we tell the linker is read only (cause it is rom). The linker will now try to help us and yell
 ;if it thinks we are going to try to write to an address in CODE.
 ;
 ;CODE says it is loading from the ROM segment. It says define true (yes) so that it could be imported and used as an address in source.
 ;
 ;The ROM segment has other useful parameters
 ;* It is starting at $8000. Remember Ben's 2nd 6502 video? that is where our addressable ROM starts. This is good.
 ;* We see that it is $8000 in size, thus we have 16384 addressable bytes or 16KB. Again, this conforms with what Ben said
 ;* It says define true (yes) so that it could be imported and used as an address in source.
 ;* This is read only space. This makes sense as it is rom. The linker will also try to yell if it thinks we are going to try and write to that ro space
 ;* We also define a fill, and a fillvall of $00. So we'll fill the empty space with $00
 ;* And "file" parameter without a type looks like it is just asserting (even though this is default) that binary output (.bin) is desired
 ;
 ;In short, what does this mean? This is a dynamic shorthand for:
 ;  .segment CODE
 ; or
 ;  .org $8000
 ;
 ; The code segment is special, it gets its own optional segment marker https://cc65.github.io/doc/ca65.html#ss11.13
  .code

reset:
  ;We want to set all pins on port B of the via adapter to output. Load that state to the accumulator (a)
  ;$ff = %11111111 = 255
  lda #$ff
  ;Now we want to write the value in the accumulator (a) to Data Direction Register for via port B (DDRB)
  ;
  ;We have access to the exported values VIA_DDRB & VIA_PORTB because:
  ;* It is imported in the included via.s.inc
  ;* It is exported (and defined) in via.s file
  ;* The via.s file knows what address to use as the starting VIA address because it is defined in firmware.cfg
  ;
  ;See the chain? We can define memory segments in the firmware (with the static values) and have the the code just 
  ;reference that instead of storing those constants. This makes the code so much more future proof, if the segments
  ;ever need to move we just update the firmware.cfg
  sta VIA_DDRB

;Turn tell the via to set pins 1 and 3 (index started at 0) to true
;$50 = %01010000 = 80
  lda #$50
  sta VIA_PORTB

loop:
  ;rotate the value in the accumulator (a) right
  ;so 01010000 will become 00101000
  ror
  ;write the rotated accumulator (a) to via port B
  sta VIA_PORTB
  ;jump back to the loop reference. We are now looping forever and ever and ever
  jmp loop
