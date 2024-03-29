\ SIEVE in ASMFORTH for Camel99 Forth                 Mar 1 2023 Brian Fox
\ based on code by @Reciprocating Bill atariage.com 

\ Original notes by BIll.
\ * SIEVE OF ERATOSTHENES ------------------------------------------
\ * WSM 4/2022
\ * TMS9900 assembly adapted from BYTE magazine 9/81 and 1/83 issues
\ * 10 iterations 6.4 seconds on 16-bit console
\ * ~10 seconds on stock console

\ *****************************************
\ *** code to test asmforth II Ver. 0.8 ***
\ *****************************************

\ This version uses the Camel99 Forth FILLW rather than coding it in ASMForth 

HOST 
DECIMAL 8190 CONSTANT SIZE
HEX     2000 CONSTANT FLAGS   \ array in Low RAM 

ASMFORTH 
CODE DO-PRIME ( -- n)  
\ inits 
   R0 OFF        \ clear loop index 
   R3 OFF        \ 0 constant
   FLAGS R5 #!   \ array base address 

   0 #           \ counter on top of Forth stack 
   SIZE #FOR 
    R5 @+ R3 CMPB       \ FLAGS C@+ byte-compared to R3 (ie: 0)
    <> IF               \ not equal to zero ? 
          R0 R1 !       \ I -> R1
          R1 2*  
          R1 3 #+ \ R1 3+
          R0 R2 !       \ I -> R2 ( R2 is K index) 
          R1 R2 +       \ PRIME K +! 
          BEGIN  
            R2 SIZE #CMP  \ K SIZE compare 
          < WHILE  
            R3 FLAGS (R2) C! \ reset byte FLAGS(R2)
            R1 R2 +     \ PRIME K +! 
          REPEAT 
          TOS 1+         \ increment count of primes
    THEN 
    R0 1+                \ bump index register
  NEXT 
;CODE  

HOST
INCLUDE DSK1.FILLW 

DECIMAL 
: PRIMES ( -- )
   PAGE ."  10 Iterations"
   10 0 DO  
   [ HEX ]
        FLAGS SIZE  0101 FILLW 
   [ DECIMAL ]
        DO-PRIME  CR . ." primes"  
    LOOP
   CR ." Done!"
;
