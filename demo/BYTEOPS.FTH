\ BYTEOPS.FTH demo code 

\ The 9900 handles bytes in weird way. 
\ C! will swap the bytes if the destination argument is a register. 

HOST 
HEX 
CREATE X  AABB ,
CREATE Y  0000 ,

ASMFORTH 
CODE TEST-C! 
    DUP 
    X @@  TOS MOVB, CR .S

    DUP 
    X @@  TOS C!  CR .S 

    X @@  Y @@ C! 

    Y @@  TOS C!  CR .S 

;CODE      
    