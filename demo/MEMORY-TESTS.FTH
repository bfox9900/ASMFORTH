\ ASMFORTH LOOP TESTS



COLD 

HEX 

VARIABLE X
VARIABLE Y 

CODE FORLOOP 
  R0 OFF       \ empty an accumulator register  
  FFFF # FOR   \ FOR is a down counting loop using the Return stack  
       RP @ Y @@ !  \ read loop index from top of return stack RP register 
       X @@ 1+    \ inc X 
       Y @@ R0 +  \ add y to R0 
       X @@ R0 +  \ add x to RO 
  NEXT     
  DUP        
  R0 TOS !   \ put number in TOS for Forth to use  
;CODE    

HEX
CODE DOWHILE
      X R5 #!  \ put address of X into R5 
      FFFF #   \ number onto the Forth data stack 
      BEGIN
        TOS 1- \ decrement top of data stack 
      <> WHILE \ while <> 0 
        
        \ inc X by 2 via a register 
        R5 @ 2+  \ means at the address in R5, inc by 2 
        
        \ OR do directly this way 
        X @@ 2+  
      
      REPEAT
      R5 TOS !  \ put result in TOS register
;CODE
