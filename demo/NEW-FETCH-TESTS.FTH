\ new fetch tests exercises smart @ operator   July 23 2023  BF

\ @ (fetch) is smart in V0.8 and detects a register or a valid address

FORTH 

VARIABLE Y  
VARIABLE Z 

CREATE X  99 , 100 , 101 , 102 , 103 , 104 , 105 , 106 , 

ASMFORTH 
\ @ compiles symbolic addressing operation 
CODE TEST1  ( -- n)   
    0 #  
    X @ TOS !  
;CODE   

\ @ compiles a register indirect operation 
CODE TEST2   ( -- n)  
    X R1 #!         \ address of X -> R1 
    0 #             \ Put zero on top of Forth stack 
    R1 @ TOS !      \ fetch address in R1 -> TOS 
;CODE 
      
CODE TEST3 ( -- n1 n2)       
    X R1 #!         \ address of X -> R1 
    0 #             \ Put zero on top of Forth stack 
    R1 @+ TOS !     \ fetch address in *R1+ -> TOS 
    DUP 
    R1 @+ TOS !
;CODE     

