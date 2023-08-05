\ ASMFORTH II memory tests for version 0.8     July 26 2023
\ COLD 

HEX 
VARIABLE X
VARIABLE Y 

CODE FORLOOP 
  R0 OFF         \ create an accumulator register  
  X R1 #!        \ address of X -> R1
  FF00 #FOR      \ FOR is a down counting loop using the Return stack  
       X 2+      \ inc X 
       X @ R0 +  \ fetch x  add to RO 
       R1 @+  Y +!  
  NEXT     
  DUP        
  Y @ TOS !       \ put number in TOS for Forth to use  
;CODE    

HEX
CODE DOWHILE
      X R5 #!  \ put address of X into R5 
      FFFF #   \ number onto the Forth data stack 
      BEGIN
        TOS 1- \ decrement top of data stack 
      <> WHILE \ while <> 0 
        
        \ inc X by 2 via a register 
        *R5 2+  \ means at the address in R5, inc by 2 
        
        \ OR do directly this way 
        X 2+  
      
      REPEAT
      R5 TOS !  \ put result in TOS register
;CODE