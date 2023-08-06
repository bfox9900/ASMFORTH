\ BYTEOPS.FTH demo code 

\ The 9900 handles bytes in weird way. 
\ C! will shift the bytes if the destination argument is a register. 

HOST 
HEX 
\ create some variables 
CREATE X  AABB ,  
CREATE Y  0000 ,

ASMFORTH 
CODE TEST-C! ( -- n n n)
    DUP               \ free up TOS 
    TOS OFF           \ clr tos  

    X @@ TOS MOVB,   \ assembler version 

\ ASMFORTH           Output in Forth Assembler 
    DUP            \  SP DECT,  TOS *SP MOV, 
    X @  TOS C!    \  X @@ TOS MOVB, 

    X @  Y @ C!    \  X @@  Y @@ MOVB, 
  
;CODE      

TEST-C!
.S 

X ?
CR Y ? 
    