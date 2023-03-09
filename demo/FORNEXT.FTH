\ FORNEXT.FTH Demonstration for ASMFORTH II 

HOST  \ sets search order to Forth and Assembler, Forth definitions 
INCLUDE DSK1.ELAPSE

ASMFORTH  \ Adds ASMFORTH to the HOST search order 
DECIMAL
CODE FORNEXT  \ .9 seconds
      65535 #FOR  NEXT
;CODE
\ TYPE  ELAPSE FORNEXT 

CODE UPCOUNT \ 1.2 seconds
    0 #        ( counter in TOS register )
    65535 #FOR
      TOS 1+ 
    NEXT
    DROP
;CODE     

\ 1,000,000 iterations 
CODE FORNEST  \ 13.5 seconds
    1000 #FOR
      1000 #FOR
      NEXT
    NEXT
;CODE

\ 1,000,000 iterations 
CODE NESTED  \ 14.5 seconds
    100 #FOR
      100 #FOR
          100 #FOR
           NEXT
        NEXT
    NEXT
;CODE

\ 1,000,000 iterations 
CODE DEEPER  \ 35.1 seconds
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
;CODE
