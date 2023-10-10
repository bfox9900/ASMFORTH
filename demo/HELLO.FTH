\ tiny hello world in machine Forth
\ Translated from hello.c by Tursi for comparison

ASMFORTH
HEX
8C02 CONSTANT VDPWA   \ Write Address port 
8C00 CONSTANT VDPWD   \ Write Data port

\ define the string
CREATE TXT  S" Hello World!" S,

CODE MAIN 
    0 LIMI,        \ disable interrupts 
\ set the VDP address to >0000 with write bit set
    0040 #  
    TOS VDPWA C!  \ VDP address LSB character store 
    TOS >< 
    TOS VDPWA C!  \ VDP address MSB + "write" bit character store 
    DROP 

    TXT # 
    *TOS R0 C!     \ byte count -> R0
    R0 8 RSHIFT 
    R0 1-        \ for loop needs 1 less
    TOS 1+        \ skip past byte count 
    R0 FOR 
        *TOS+ VDPWD C! 
    NEXT
    DROP
    
    NEXT,
ENDCODE 

\ usage: PAGE MAIN 

