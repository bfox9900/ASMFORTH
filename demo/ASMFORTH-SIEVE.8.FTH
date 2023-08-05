\ SIEVE in ASMFORTH for Camel99 Forth                 July 2023 Brian Fox
\ based on code by @Reciprocating Bill atariage.com 

\ Minor mods for Version 0.8 

\ Original notes by BIll.
\ * SIEVE OF ERATOSTHENES ------------------------------------------
\ * WSM 4/2022
\ * TMS9900 assembly adapted from BYTE magazine 9/81 and 1/83 issues
\ * 10 iterations 6.4 seconds on 16-bit console
\ * ~10 seconds on stock console

\ * ASMForth version runs in 10 seconds 
HOST 
DECIMAL 8190 CONSTANT SIZE
HEX     2000 CONSTANT FLAGS   \ array in Low RAM 

ASMFORTH 
: FILLW ( addr size U --)  
    R0 POP         \ size in TOS for FOR to pickup 
    R1 POP         \ Memory location in R1
    R0 FOR         \ FOR takes the R0 argument 
       TOS *R1+ !  \ write ones to FLAGS
    NEXT2          \ *NEW* counts down by 2 
    DROP 
;                 

HEX
CODE DO-PRIME ( -- n)  
  FLAGS # SIZE # 0101 # FILLW

\ inits 
  R0 OFF               \ 0 constant
  R3 OFF               \ clear loop index register

  FLAGS R5 #!          \ array base address 
  SIZE R8 #!           \ size of array 
  
  0 #                  \ counter on top of Forth stack (ie: in R4)
  R8 FOR               \ use R8 to load loop counter 
  R5 @+ R0 CMPB        \ FLAGS byte-compared to 0 
  <> IF                \ not equal to zero ? 
      R3 R1 !          \ I -> R1
      R1 2*  
      3 R1 #+!         \ R1 3+
      R3 R2 !          \ I -> R2 ( R2 is K index) 
      R1 R2 +          \ PRIME K +! 
      BEGIN  
        R2 R8 CMP      \ K SIZE compare 
      < WHILE  
        R0 FLAGS (R2) C! \ reset byte FLAGS(R2)
        R1 R2 +        \ PRIME K +! 
      REPEAT 
      TOS 1+           \ increment count of primes
    THEN 
    R3 1+              \ bump LOOP index register
  NEXT 
;CODE  

HOST   ( Switch back to Host Forth )
DECIMAL 
: PRIMES ( -- )
   PAGE ."  10 Iterations"
   10 0 DO   DO-PRIME  CR . ." primes"  LOOP
   CR ." Done!"
;
