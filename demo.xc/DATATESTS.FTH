HEX
RESET

TARGET


: FILLSEQ ( addr len )
  TOS OFF 
  *SP+ AR MOV, 
  *SP+ FOR 
      TOS !A+
      TOS 1+ 
  NEXT2
;

800 CONSTANT SIZE 
CREATE Q[]  SIZE ALLOT 

\ looping on a array 
: DATATEST 
    Q[] #  SIZE #  OVER OVER FILLSEQ
;


VARIABLE X
VARIABLE Y 




    BEGIN  
       NOS TOS CMP  \ fastest comparison: 2DUP = 
    <> WHILE 
       DUP TOS @ X ! 
       TOS 2+ 
    REPEAT 
;
