\ BYTEOPS.FTH demo code 

\ The 9900 handles bytes in weird way. 
\ C! will swap the bytes if the destination argument is a register. 

HOST 
HEX 
CREATE X  AABB ,
CREATE Y  0000 ,

ASMFORTH 
CODE TEST-C! ( -- n n n)
    DUP               \ free up TOS 
    TOS OFF           \ clr tos  

    X @@  TOS MOVB,   \ assembler version 

    DUP 
    X @@  TOS C!     \ C! has bit shifting

    X @@  Y @@ C!    \ C! has no bit shifting X->Y 
    
    DUP 
    Y @@  TOS C!  

;CODE      

TEST-C!
.S 
    