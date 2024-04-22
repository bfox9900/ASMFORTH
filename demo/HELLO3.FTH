\ tiny hello world in ASMForth II
\ Translated from hello.c by Tursi for comparison

ASMFORTH
HEX
8C02 CONSTANT VDPWA   \ Write Address port 
8C00 CONSTANT VDPWD   \ Write Data port

\ define the string
CREATE TXT  S" Hello World!" S,

: VDPADDR!
    0 LIMI, 
    TOS ><        \ swap bytes 
    TOS VDPWA C!  \ VDP address LSB character store 
    TOS ><        \ swap bytes 
    TOS VDPWA C!  \ VDP address MSB + "write" bit character store 
    DROP 
;

\ character address and VDP address auto-increments
: C@EMIT+  ( addr -- addr++) TOS @+ VDPWD C!  ;

: TYPE  ( addr length -- )
    TOS R0 ! DROP   \ pop length into R0, address to TOS 
    R0 1-           \ for loop needs 1 less    
    R0 FOR   C@EMIT+   NEXT DROP    
;

CODE MAIN 
    \ VDP address set to >0000 with write bit set
    4000 # VDPADDR!
    TXT # COUNT TYPE 
 NEXT,
ENDCODE 

\ usage: PAGE MAIN CR

