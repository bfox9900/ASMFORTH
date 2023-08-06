\ BYTEOPS.FTH demo code 

\ The 9900 is little endian so bytes are on the right side.
\ C! is just a MOVB ( move byte) instruction.

HOST 
HEX 
\ create some variables 
CREATE X  AABB ,  
CREATE Y  0099 ,

ASMFORTH 
CODE TEST-C! ( -- n n n)
    DUP               \ free up TOS 
    TOS OFF           \ clr tos  

    X @@ TOS MOVB,    \ Forth Assembler code is still legal

\ ASMFORTH           Output in Forth Assembler 
    DUP            \  SP DECT,  TOS *SP MOV, 
    TOS OFF 
    X @  TOS C!    \  X @@ TOS MOVB, 

    X ><           \ swap bytes in memory at X
    X @ PUSH 
    Y @ PUSH       \ push the contents of Y into TOS  
  
    X @  Y @ C!    \  X @@  Y @@ MOVB, 
    Y @ PUSH   
;CODE      

TEST-C!
CR .( Results from the program are on the stack )
CR .S 


    