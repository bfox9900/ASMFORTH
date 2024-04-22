\ SIEVE in ASMFORTH V.81 for Camel99 Forth    Aug 2023 Brian Fox
\ based on code by @Reciprocating Bill atariage.com 

\ Minor mods for Version 0.8 

\ Original notes by BIll.
\ * SIEVE OF ERATOSTHENES ------------------------------------------
\ * WSM 4/2022
\ * TMS9900 assembly adapted from BYTE magazine 9/81 and 1/83 issues
\ * 10 iterations 6.4 seconds on 16-bit console
\ * ~10 seconds on stock console

\ * ASMForth II .81 version runs in 9.26 seconds 
HOST 
NEEDS ELAPSE FROM DSK1.ELAPSE  \ for timing 

ASMFORTH  

DECIMAL 8190 CONSTANT SIZE
HEX     2000 CONSTANT FLAGS   \ array in Low RAM 

\ ** note: FILLW is an ASMFORTH colon definition. 
\ It makes a native code subroutine that CANNOT be invoked by Forth,
\  only by another ASMFORTH colon word or by a CODE word. 

: FILLW ( addr size U --)  
    R0 POP         \ size in R0 for FOR to pickup 
    R1 POP         \ Memory location in R1
    R0 FOR         \ FOR takes the R0 argument 
       TOS *R1+ !  \ write U to addr, bump addr by 2
    NEXT2          \ *NEW* counts down by 2 
    DROP 
;                 

\ We can make register "variables" for clarity 
\ some might say it's unnecessary

R0 CONSTANT #0  \ numerical zero 
R3 CONSTANT i    \ LOOP index 
R5 CONSTANT F[]  \ array 
R1 CONSTANT X    \ temp register variable 
R2 CONSTANT Y    \ temp register variable 

HOST 
: (Y)   (R2) ;  \ use register Y as indexed addresser 

ASMFORTH 
\ we use CODE here because it makes a word that can be called 
\ from Forth by using its name.
CODE DO-PRIME ( -- n)  
  FLAGS # SIZE # 0101 # FILLW

\ inits 
  R0 OFF               \ 0 constant
  i  OFF               \ clear I register
  FLAGS F[] #!         \ array base address 
  
  0 #                  \ prime # counter on Forth stack (ie: in R4)

  SIZE #FOR            \ load a constant directly to R8 loop counter 
  F[] @+ #0 CMPB       \ FLAGS byte-compared to 0, auto inc F[]
  <> IF                \ not equal to zero ? 
      i X !           \ I -> x
      X 2*  
      3 X #+!         \ X 3+
      i Y !           \ I -> R2 ( R2 is K index) 
      X Y +           \ PRIME K +! 
      BEGIN  
        Y SIZE #CMP  \ K SIZE compare 
      < WHILE  
        #0 FLAGS (R2) C! \ reset byte FLAGS(R2)
        X Y +        \ PRIME K +! 
      REPEAT 
      TOS 1+           \ increment count of primes
    THEN 
    i 1+              \ bump LOOP index register
  NEXT 
;CODE

HOST   ( Switch back to Host Forth )
DECIMAL 
: PRIMES ( -- )
   PAGE ."  10 Iterations"
   10 0 DO   DO-PRIME  CR . ." primes"  LOOP
   CR ." Done!"
;


