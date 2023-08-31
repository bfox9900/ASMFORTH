\ FORNEXT.FTH Demonstration for ASMFORTH II 

HOST  \ sets search order to Forth and Assembler, Forth definitions 
INCLUDE DSK1.ELAPSE

COMPILER 
DECIMAL

TARGET 
: FORNEXT     65535 #FOR  NEXT ;

: UPCOUNT \ 1.2 seconds
    0 #        ( counter in TOS register )
    65535 #FOR
      TOS 1+ 
    NEXT
    DROP
;   

\ 1,000,000 iterations 
: FORNEST  \ 13.5 seconds
    1000 #FOR
      1000 #FOR
      NEXT
    NEXT
;

\ 1,000,000 iterations 
\ V .73 14.51 seconds  
\ V .81 10.11 seconds 
: NESTED  
    100 #FOR
      100 #FOR
          100 #FOR
           NEXT
        NEXT
    NEXT
;

: FASTER  \ 14.18 seconds
    100 R0 #! \ loop limit in a register 
    R0 FOR    \ pass Register to FOR :-) 
      R0 FOR
          R0 FOR
           NEXT
        NEXT
    NEXT
;

\ 1,000,000 iterations 
\ v .73 35.1 seconds   
\ V.81  23.8 seconds 
: DEEPER  
    10 #FOR
      10 #FOR
        10 #FOR
          10 #FOR
            10 #FOR
              10 #FOR
              NEXT
            NEXT
          NEXT
        NEXT
      NEXT
    NEXT
;
