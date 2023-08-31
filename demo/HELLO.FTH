\ tiny hello world in machine Forth
\ Translated from hello.c by Tursi for comparison

ASMFORTH
HEX
8C02 CONSTANT VDPWA   \ Write Address port 
8C00 CONSTANT VDPWD   \ Write Data port

\ define the string
CREATE TXT  S" Hello World!" S,

CODE MAIN 
\ set the VDP address to >0000 with write bit set
    0 # 
    TOS VDPWA C!   \ VDP address LSB character store 
    DROP 
    40 #
    TOS VDPWA C!  \ VDP address MSB + "write" bit character store 
    DROP 
    TXT # 
    TOS R0 C!     \ byte count -> R0
    TOS INC,      \ skip past byte count 
    R0 8 SRA,     \ shift the byte to low side 
    R0 FOR 
        *TOS+ VDPWD C! 
    NEXT
    DROP
NEXT,
ENDCODE 


