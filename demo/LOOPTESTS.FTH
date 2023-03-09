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
         
       
