\ ASMFORTH XC LOOP TESTS

\ Type  FORTH COLD   to restart ASMFORTH XC 

COMPILER HEX
HERE 
: DOUNTIL    \ smallest loop 
    FFFF #   \ DUP R4 and put a number into R4
    BEGIN
      TOS 1- \ decrement a register 
    = UNTIL  \ loop until TOS hits zero
    DROP     \ clean the stack 
;
HERE  
HOST SWAP - DECIMAL  . .( bytes)

COMPILER HEX 
TARGET VARIABLE X
HERE 
: DOWHILE
    FFFF #
    BEGIN
      TOS 1- 
    <> WHILE 
       R0 1+  \ modify some registers 
       R1 1-
       R2 2+  
       R3 2- 
       X  1-  \ these operators also work with variables 
    REPEAT
    DROP
;

HERE  
HOST SWAP - DECIMAL . .( bytes)


