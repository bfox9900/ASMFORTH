\ tiny hello world in ASMForth II
\ Translated from hello.c by Tursi for comparison

ASMFORTH
HEX
8C02 CONSTANT VDPWA   \ Write Address port 
8C00 CONSTANT VDPWD   \ Write Data port

\ define the string
CREATE TXT  S" Hello World!" S,

: VDPADDR 
    TOS ><        \ swap bytes 
    TOS VDPWA C!  \ VDP address LSB character store 
    TOS ><        \ swap bytes 
    TOS VDPWA C!  \ VDP address MSB + "write" bit character store 
    DROP 
;

CODE MAIN 
    0 LIMI,        \ disable interrupts 
\ set the VDP address to >0000 with write bit set
    4000 # VDPADDR
    TXT # 
    *TOS R0 C!     \ byte count -> R0
    R0 8 RSHIFT 
    R0 1-          \ for loop needs 1 less
    TOS 1+         \ skip past byte count 
    R0 FOR         \ get argument from R0 
       TOS @+ VDPWD C! 
    NEXT
    DROP

    NEXT,
ENDCODE 

\ usage: PAGE MAIN CR

