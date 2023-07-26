\ ASMFORTH LOOP TESTS

\ Type  COLD   to restart ASMFORTH II 

HEX
CODE DOUNTIL  \ smallest loop 
      FFFF #   \ DUP R4 and put a number into R4
      BEGIN
        TOS 1- \ decrement a register 
      = UNTIL  \ loop until TOS hits zero
      DROP     \ clean the stack 
;CODE

HEX
CODE DOWHILE
      FFFF #
      BEGIN
        TOS 1- 
      <> WHILE 
        R5 2+  
      REPEAT
      DROP
;CODE

\ for/next gives you a nestable loop structure that is a simple downcounter. 
\ put the number of interations into the TOS register (or use #) 
\ It will run unto TOS<0 (*it runs until tos= -1 * )
\ It does not consume a register while running because 
\ the counter is on the return stack
CODE FORNEXT 
     FFFF #FOR 
        
         RP @  R0 !   \ get the loop index via the RP register
                      \ store it in R0 
      NEXT 
;CODE       
         
\ alternative: Load a number in a register, pass register to FOR
\ In this example we use the TOS cache  (ie: R4) 

CODE FORNEXTREG
      FFFF #        \ push number onto data stack, (goes in TOS register)
      TOS FOR 
       ( loop payload goes here )
      NEXT 
;CODE 


\ nesting is simple because of the return stack
ASMFORTH 
: INNER               \ ASMFORTH colon makes a nestable sub-routine with return stack
     1000 # 
     TOS FOR          \ FOR NEXT also uses return stack for downcounter
  
     NEXT 
;

: OUTER     \ code words can be called from HOST Forth 
   1000 # 
   TOS FOR 
       INNER   \ call the inner loop.
   NEXT 
;

CODE  RUN     OUTER  ;CODE   \ code words are callable from HOST Forth
    

