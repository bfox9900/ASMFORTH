\ SIEVE in ASMFORTH V.81 for Camel99 Forth    Aug 2023 Brian Fox
\ based on code by @Reciprocating Bill atariage.com 

\ Minor mods for Version 0.8 

\ Original notes by BIll.
\ * SIEVE OF ERATOSTHENES ------------------------------------------
\ * WSM 4/2022
\ * TMS9900 assembly adapted from BYTE magazine 9/81 and 1/83 issues
\ * 10 iterations 6.4 seconds on 16-bit console
\ * ~10 seconds on stock console

\ * ASMForth II version runs in 9.5 seconds 
HOST 
NEEDS ELAPSE FROM DSK1.ELAPSE  \ for timing 

ASMFORTH  

DECIMAL 8190 CONSTANT SIZE
HEX     2000 CONSTANT FLAGS   \ array in Low RAM 

\ ** note: FILLW is an ASMFORTH colon definition. 
\ It is a native code subroutine that CANNOT be invoked by Forth,
\ only by another ASMFORTH colon word or by a CODE word. 

: FILLW ( addr size U --)  
                   \ u is in the top of stack cache register (TOS)
    NOS^ R0 !      \ POP "next on stack" into R0 (size) (MOV *SP+,RO)
    NOS^ R1 !      \ POP address into R1
    R0 FOR         \ FOR takes the R0 argument into loop index register
       TOS R1 @+ !  \ write U to addr in R1, bump addr by 2
    NEXT2          \ *NEW* counts down by 2 
    DROP           \ drop U which refills the TOS register
;                 

\ make register "variables" for code clarity 
R0 CONSTANT #0   \ numerical zero 
R1 CONSTANT X    \ temp register variable 
R2 CONSTANT K    \ inner loop register variable 
R3 CONSTANT i    \ outer LOOP index
R5 CONSTANT MEM  \ array base address 

\ (K) is defined in the HOST Forth namespace so it's a normal Forth word.
HOST  
: (K)   (R2) ;  \ use register K as indexed addresser 

ASMFORTH 
\ we use CODE here because it makes a word that can be called 
\ from Forth by name. ie: a regular "code" word.
CODE DO-PRIME ( -- n)  
  FLAGS # SIZE # 0101 # FILLW

\ inits 
  R0 OFF               \ 0 constant held in Register 0 
  i  OFF               \ clear I register
  FLAGS MEM #!         \ array base address 
  
  0 #                  \ prime # counter on Forth stack (ie: in R4)
  SIZE #FOR            \ load a constant directly to R8 loop counter 
  MEM @+ #0 CMPB       \ FLAGS byte-compared to 0, auto inc MEM
  <> IF                \ not equal to zero ? 
      i X !            \ I -> x
      X 2*  
      3 X #+!          \ this is a load immediate instruction
      i K !            \ MOV R3,R2 
      X K +            \ A   R1,R2  
      BEGIN  
        K SIZE #CMP    \ K SIZE compare ie: CI instruction
      < WHILE  
        #0 FLAGS (K) C! \ reset byte FLAGS(R2)
        X K +          \ PRIME K +! 
      REPEAT 
      TOS 1+           \ increment count of primes
    THEN 
    i 1+               \ bump LOOP index register
  NEXT 
;CODE

HOST   ( Switch back to Host Forth )
DECIMAL 
: PRIMES ( -- )
  PAGE ."  10 Iterations"
  10 0 
  DO   
    DO-PRIME  CR . ." primes"  
  LOOP
  CR ." Done!"
;


