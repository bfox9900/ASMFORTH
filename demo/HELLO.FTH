\ tiny hello world in machine Forth
\ Translated from hello.c by Tursi for comparison

ASMFORTH
HEX
8C02 CONSTANT VDPWA   \ Write Address port 
8C00 CONSTANT VDPWD   \ Write Data port

\ define the string
CREATE TXT  S" Hello World!" S,

: MAIN 
\ set the VDP address to >0000 with write bit set
     0  VDPWA C!  \ VDP address LSB character store 
    40  VDPWA C!  \ VDP address MSB + "write" bit character store 

    TXT # COUNT
    FOR
        COUNT VDPWD C!  
    NEXT
    DROP
;

