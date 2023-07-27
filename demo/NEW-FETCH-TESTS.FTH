\ new fetch tests exercises smart @ operator   July 23 2023  BF

\ @ (fetch) is smart in V0.8 and detects a register or a valid address


HOST
VARIABLE Y  
VARIABLE Z 

CREATE X  99 , 100 , 101 , 102 , 103 , 104 , 105 , 106 , 
CREATE Q   8 CELLS ALLOT 

ASMFORTH 
\ @ compiles symbolic addressing operation to register
CODE TEST1  ( -- n)   
    DUP          \ free up top of stack cache register   
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

CODE MEM2MEM  \ moves memory to memory in one instruction
    Z @ Y ! 
;CODE     

ASMFORTH 

\ CODE word that can be called from Forth 
CODE MOVECELLS ( src dst n -- ) \ tos=n NOS=DST  3rd=src 
    NOS^ R1 !             \ POP dst into a register for auto-incrementing 
    NOS^ R0 !             \ POP source into a register  
    TOS FOR               \ FOR takes n from TOS register and pushes it onto Rstack
       R0 @+  R1 @+ !     \ store a cell and auto-increment both registers
    NEXT 
    DROP                  \ refill TOS register from data stack memory  
;CODE    

