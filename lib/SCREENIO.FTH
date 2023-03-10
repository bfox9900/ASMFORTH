\ ASMFORTH SCREENIO library  Mar 9 2023  Brian Fox

HOST NEEDS VWTR  FROM DSK7.VDPLIB

\ VARIABLE ROW
\ VARIABLE COL
\ VARIABLE C/L    \ chars per line
\ VARIABLE C/SCR  \ chars per screen
\ VARIABLE VPG    \ VDP page
\ VARIABLE MEM    \ pointer to end of program memory
\ VARIABLE VMODE

CODE HERE    DUP    DP @@ TOS ! ;CODE

CODE AT-XY  ( col row --)  
    TOS VROW @@ ! 
    DROP  
    TOS VCOL @@ ! 
    DROP 
;CODE

CODE VPOS   ( -- Vaddr) 
    DUP 
    VROW @@ TOS !  
    DUP 
    C/L @@ TOS ! 
    NOS^ TOS *    
    VCOL @@ TOS + 
;CODE

: PAGE   ( -- ) 
    0 # 0 # AT-XY  
    VPOS  
    DUP  C/SCR @@ TOS ! 
    BL # VFILL -;  \ tail call optimize

DECIMAL
: SCROLL ( Vaddr -- Vaddr)
      VPG @  DUP>R
      [ C/L @] +  HERE    [ C/SCR @]  [ C/L @]  - VREAD \ get 2nd line & below
      HERE R>  [ C/SCR @] [ C/L @] - VWRITE  \ write to 1st line
      0 23 AT-XY
      VPOS  [ C/L @] BL VFILL -; \ tail call

TARGET
: CR    ( -- )
        COL OFF
        ROW DUP 1+! @ 23 >IF SCROLL THEN DROP ;

: EMIT  ( c --)
        COL DUP 1+! @ [ C/L @] >IF CR THEN DROP \ needs DROP for >IF
        VPOS VC! -; \ tail call

: SPACE ( -- ) BL EMIT -; \ tail call

: TYPE   ( addr len --) 1- FOR  COUNT EMIT  NEXT DROP ;

: SPACES ( n -- ) 1- FOR  SPACE  NEXT ;

\ FAST type, no protection!!
\ : VTYPE  ( addr len --) DUP>R  VPOS SWAP VWRITE  R> [ COL +!] ;

[CC] HEX
TARGET
: SCREEN  ( n -- )  7 VWTR -;
: OUTPUT  ( n -- )  2 VWTR -;

: TEXT  ( -- )
         0F0 DUP 1 VWTR  [ 83D4 C!]
          0 OUTPUT
         17 SCREEN
         28 [ C/L !]
        3C0 [ C/SCR !]
          2 [ VMODE !]   \ 2=ID for 40 column "TEXT" mode
;
\ 771 bytes with VDPLIB

\ =================================
\ *COMPILER DIRECTIVE to set MEM  variable MUST be used at end of program
COMPILER ALSO TARGETS ALSO FORTH

\ set program mem variable to compiler
H: CONCUR. ( -- ) THERE REL>TARG MEM T! ;H
\ =================================

COMPILER
