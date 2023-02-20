\ ASMFORTH LOOP TESTS

HEX
CODE  SIMPLE
      FFFF #   \ DUP R4 and put a number into R4
      BEGIN
        TOS 1-
        TOS 0= 
      UNTIL
      DROP
;CODE

HEX
CODE DOWHILE
      FFFF #
      BEGIN
        TOS 1- 
      NE WHILE 
        R5 2+  
      REPEAT
      DROP
;CODE
