\ ASMFORTH II  .81  July 2023 Brian Fox
\ Alternative Assembler use Forth syntax with registers and stacks 

\ *********************************************************************
\ AsmForth concept:
\ - Used Forth mnemonics to replaced specific Assembler names.
\ - Forth CREATE VARIABLE, CONSTANT etc are used for data managment

\ Syntax conventions 
\ 1. Registers are explicity referenced in code
\ 2. !  replaces MOV, 
\ 3. C! replaces MOVB, 
\ 3. @  replaces the ** indirect addressing word to fetch via registers
\ 4. @+ replaces the *+ indirect addressing word with auto-increment
\ 5. @@ operator is used for symbolic addressing
\ 6. Registers in brackets are indexed addressing:  (R1) (R2) etc.
\ 7. TOS register can as the accumulator for computation 
\ 8. DATA stack is available with PUSH POP DUP DROP SP Register
\ 9. Return stack is available with RPUSH RPOP R@   RP register
\ Mar 1 2023
\ 10. Changed LD to #! to be consistent with other immediate instructions
\ 11. .80  Added <src> AND <DST> to make @ and ! smart 
\ 12. .81 Changed FOR NEXT to use R11 as the loop index
\ 13  2024: ;.82  made R8 the for/next loop index

\                Code comparisons VERSION 0.83

\   TI Assembler                ASMForth Equivalent  
\ -------------------         -------------------------
\ * n/a                         HEX 
\       MOV  R1,R4                  R1 R4 ! 
\       MOV *R1,R4                  R1 @ R4 ! 
\       MOV *R1+,R4                 R1 @+ R4 ! 

\ data 
\ MEAT  EQU  >BEEF              BEEF CONSTANT MEAT 
\ LABEL DATA 0000               VARIABLE LABEL   
\ LABL2 DATA >DEAD              CREATE LABL2 DEAD , 
\ TABL  BSS  >100               CREATE TABL  100 ALLOT 

\       LI  R0,MEAT             MEAT R0 #!
\       AI  R0,7                   7 R0 #+!
\       MOV @LABEL,R4           LABEL @ R4 ! 
\       MOV R3,@LABEL           R3 LABEL ! 
\       MOV @LABL2,@LABEL       LABL2 @ LABEL ! 


\ ************************************************************************
\ 10 registers are available for use as local data
\ The data stack can be used to save/restore register for nesting calls
\ The return stack can be alse be used to save/restore registers
\ BUT they must be restored before exiting a routine. 

\ /////////// REGISTER USAGE \\\\\\\\\\\
\ R0   scratch
\ R1   scratch
\ R2   scratch
\ R3   scratch 
\ R4   TOS Accumulator -or scratch 
\ R5   scratch
\ SP   data stack pointer
\ RP   return stack pointer
\ R8   FOR/NEXT loop index register  
\ R9   Forth interpreter pointer 
\ R10  holds NEXT address
\ R11  sub-routine linkage
\ R12  CRU I/O
\ R13  for BWLP -or- scratch 
\ R14  for BWLP -or- scratch 
\ R15  for BWLP -or- scratch 


NEEDS DUMP FROM DSK1.TOOLS
NEEDS MARKER FROM DSK1.MARKER
NEEDS WORDSLIST FROM DSK1.WORDLISTS

HERE

ONLY FORTH DEFINITIONS
VOCABULARY MFORTH

VOCABULARY ASSEMBLER
ONLY FORTH ALSO ASSEMBLER DEFINITIONS
INCLUDE DSK7.ASM9900II  ( CHANGE DSK to where you put this file)

DECIMAL
: ADDRESS?  ( n -- ?) 8191 U> ; \ lowest RAM address is 8192 

HEX
: REG?      ( n -- ?)   0 10 WITHIN ;
: MODE?     ( n -- ?)  1F 30 WITHIN ;

: <SRC>  ( n -- n | n 20)  \ used with fetch operators
    DUP ADDRESS? IF  @@  EXIT   THEN 
    DUP REG?     IF  **  EXIT   THEN 
    MODE? ABORT" Cannot fetch indexed or indirect register"   
;

: <DST>  ( n -- n | n 20)  \ used with store operators
    DUP ADDRESS? IF  @@  THEN 
;

\ aborting error detection words 
: ?ADDR     ( addr -- addr) DUP ADDRESS? 0= ABORT" Valid address expected" ;
: ?REGISTER ( reg --reg)    DUP REG? 0= ABORT" Register expected" ;

DECIMAL 
: HOST     
  ONLY FORTH ALSO ASSEMBLER ALSO MFORTH ALSO FORTH DEFINITIONS ; 

: ASMFORTH 
  ONLY FORTH ALSO ASSEMBLER ALSO MFORTH DEFINITIONS ;

\ compile forth words that will Assemble code when executed
ALSO ASSEMBLER DEFINITIONS 

: ;NATIVE   POSTPONE ;  ;  IMMEDIATE
: NATIVE:  :  ;

\ Named stack items (in memory) in Assembler wordlist 
 : NOS   *SP  ;    \ Next on Stack register
 : NOS^  *SP+ ;    \ Use NOS and then pop it 
 : 3RD   2 (SP) ;
 : 4TH   4 (SP) ;
 : 5TH   6 (SP) ;
 : 6TH   8 (SP) ;

HEX
\ ======================================================
ASMFORTH  
\ fetch previous instruction code
: LOOKBACK ( -- u)  HERE 2- @ ;

\ tail call optimizing ;SUB. USE ONLY IF LAST WORD IS SUB:
: -; ( --  )
    LOOKBACK   ( addr )   \ get entry address of sub-routine
    2 CELLS +  ( addr' )  \ move past the 2 sub-routine ENTRY instructions
    -04 ALLOT             \ erase BL @addr instruction
    ( addr') @@ B,        \ compile a branch to the NEW sub-routine (B @addr)
; 


ASMFORTH 
\ load register with literal argument 
\ usage:   BEEF R1 #! 
\       02 BYTE R1 #!   \ load 02 as low bits of R1 
: #!     ( n REG -- )   ?REGISTER SWAP LI, ; \ n -> REG

\ add literal no. to register 
: #+!    ( lit reg -- ) ?REGISTER SWAP  AI, ;


: EQU   
  CREATE  ,                  \ remember the number 
  DOES> @  TOS PUSH,   #! ;  \ compile code to push onto stack 

: BYTE   ( 0c --  0c00 )  ><  ; \ swap byte to other side of register 

\ \\\\\\\\\\\\\\\\\\\ [ @ AND ! HAVE NEW MEANING ] ///////////////////////
\ SMART fetch operator 
: @     ( addr|reg -- u | Rx n) <SRC> ;
: C@    ( addr|reg -- u | Rx n) <SRC> ;

\ Fetch indirect with auto-increment
: @+    ( reg -- Rx n) ?REGISTER  *+ ;

\ Add some smarts to store
: !    ( src dst -- )  <DST> MOV, ; 
: +!   ( src mem -- )  <DST> ADD, ; 
: C!   ( c dst -- )    <DST> MOVB, ; 

\ push/pop  any register 
: PUSH ( arg)        PUSH, ;
: POP  ( arg --)     POP,  ;

CR .( Forth Intrinics)

\ inc/dec using Forth mnemonics 
: 1+   ( arg -- ) <DST> INC, ;
: 1-   ( arg -- ) <DST> DEC, ;

: 2+   ( arg -- ) <DST> INCT, ;
: 2-   ( arg -- ) <DST> DECT, ;

: ><   ( arg -- ) <DST> SWPB, ;


: +      ( arg arg ) <DST> ADD, ;  
: -      ( arg arg ) <DST> SUB, ;

: C+     ( arg arg ) SWAP ><  SWAP <DST> ADDB, ;  \ add bytes 
: C-     ( arg arg ) SWAP ><  SWAP <DST> SUBB, ;

: INVERT ( n -- ) <DST> INV, ;

: OR     ( arg arg )  <DST> SOC, ;       
: XOR    ( n n -- n)  ?REGISTER XOR, ;
: AND    ( src dst --) SWAP INVERT  SWAP <DST> SZC, ;

: #      ( n -- )  TOS PUSH,  TOS #! ;  \ put literal into TOS

\ Immediate instructions compile a literal argument 

: #AND  ( reg lit -- ) >R ?REGISTER R> ANDI, ; 
: #OR   ( reg lit -- ) >R ?REGISTER R> ORI, ;

.(  return stack operators .)
: RPUSH   RPUSH, ; \ aliases from the assembler 
: RPOP    RPOP,  ;

\ *********************************************
\ *           ANS Forth Extensions            *
\ *********************************************
.( .)
: LSHIFT ( reg n --) >R ?REGISTER R>  SLA,  ;
: RSHIFT ( reg n --) >R ?REGISTER R>  SRA,  ;

: 2*     ( n -- n )  1 LSHIFT ;
: 4*     ( n -- n )  2 LSHIFT ;
: 8*     ( n -- n )  3 LSHIFT ;
: 2/     ( n -- n)   1 RSHIFT ;

\ **Use RP register for Reg to Reg return stack access 
: DUP>R    TOS RPUSH ;
: >R    ( n --) DUP>R TOS POP, ;
: R>    ( -- n) TOS RPOP ;
: R@    ( -- n) TOS PUSH,  *RP TOS ! ;

: RDROP ( -- )  RP 2+ ;

: NOP    ( -- ) 0 JMP, ;

: ABS    ( arg -- ) <DST> ABS, ;
: NEGATE ( arg --)    <DST> NEG, ;
: OR     ( src dst -- ) <DST> SOC, ;
: ON     ( arg -- ) <DST> SETO, ;
: OFF    ( arg --)  <DST> CLR,  ;

CR .( ASSEMBLER jump tokens)
HEX                  
                      \ Action if TRUE
\ 01 CONSTANT GTE     \ JLT to ENDIF, *signed
\ 02 CONSTANT HI      \ JLE to ENDIF,
\ 03 CONSTANT NE      \ JEQ to ENDIF,
\ 04 CONSTANT LO      \ JHE to ENDIF,
\ 05 CONSTANT LTE     \ JGT to ENDIF, *signed
\ 06 CONSTANT EQ      \ JNE to ENDIF,
\ 07 CONSTANT OC      \ JNC to ENDIF,  ON carry. Use as is 
\ 08 CONSTANT NC      \ JOC to ENDIF,  No carry. Use as is
\ 09 CONSTANT OO      \ JNO to ENDIF,  On overflow. Use as is
\ 0A CONSTANT HE      \ JLO to ENDIF,
\ 0B CONSTANT LE      \ JH  to ENDIF,
\ 0C CONSTANT NP      \ JOP to ENDIF,  No parity. Use as is

\ ASMFORTH aliases for jump tokens 
: =      EQ ;
: <>     NE ; 
: <      LTE ;
: >      GTE ;
: U>     LO ;
: U<     HI ;
: U>=    HE ;
: U<=    LE ;

: NOT    ( -- )  R1 STST,  R1 2000 ANDI, ;  \ invert EQ flag in status arg.

\ 2 item stack comparisons. USE CMP or CMPB as required 
: CMP   ( reg gad) <DST> CMP, ;
: CMPB  ( reg gad) <DST> CMPB, ;
: #CMP  ( reg lit) SWAP ?REGISTER SWAP CI, ;


\ ********* ANS/ISO Forth, Stack operators ****************
: DUP   ( n -- n n) TOS PUSH ;
: DROP  ( n -- )    TOS POP  ;
: NIP   ( n1 n2 -- n2) SP 2+ ;
: OVER  ( n1 n2 -- n1 n2 n1)  DUP  3RD TOS ! ;
: 2DROP ( n n --)   DROP DROP ;

: 2DUP  ( a b -- a b a b ) 
    -4 SP #+!   \  make room for 2 cells
    4TH NOS !      
    TOS 3RD ! ;

: SWAP  ( n1 n2 -- n2 n1) 
      TOS R5 !  
      NOS TOS !  
      R5 NOS ! ; 

\  ****  ANS FORTH WORDS USE THE DATA STACK ****
: ALIGNED ( n -- n)    TOS 1+  TOS -2 #AND ;
: AND     ( w w -- w ) NOS INV,  NOS^ TOS SZC, ;
: 2@      ( addr -- d) 3RD PUSH,  *TOS TOS ! ;   \ fetch double integer
: 2!      ( d addr --) NOS^ *TOS !  NOS^ 3RD !  DROP ;


\      ////////////////////////////////////////////////////////
\      --------------  higher level constructs  --------------
\      \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

: ;CODE    NEXT,  ENDCODE ; \ returns to Forth

\ synonyms from Assembler 
: IF     IF, ; 
: THEN   THEN, ; 
: ELSE   ELSE, ; 
: BEGIN  BEGIN, ; 
: WHILE  WHILE, ;
: AGAIN  AGAIN, ; 
: UNTIL  UNTIL, ; 
: REPEAT REPEAT, ; 

\ "not until"  From Charles Moore Machine Forth 
: -UNTIL    NC UNTIL ;  

CR .( FOR/NEXT *NEW* FASTER IN REGISTER )
\ Simple 'nestable' loop.
\ ARG is any valid cell argument, which is stored in R8, loop index.  
\ Use  nn RP @ 1-  to STEP down faster.
\ Use another  register if you need an up-counter

: FOR   ( arg --) 
    R8 RPUSH 
    ( arg) R8 !  
    BEGIN ; 

\ Alternative using literal number, N goes thru TOS -> R8
: #FOR  ( arg --)  
    R8 RPUSH      \ save R8 
    ( arg) R8 #!  \ LI R11,arg
    BEGIN ;

: NEXT  ( -- )   
    R8 1-       \ DEC  R8
    -UNTIL      \ JOC  BEGIN 
    R8 RPOP ;   \ MOV *RP+,R11  

: NEXT2         \ dect loop counter by 2 
    R8 2-  
    -UNTIL 
    R8 RPOP ; 

: #NEXT ( n --)  \ dect loop counter by 2 
    R8 #+!  
    -UNTIL 
    R8 RPOP ; 


CR .( NATIVE: to create native sub-routines)


\ these NATIVE words compile the enter code to save the R11
\ At runtime these sub-routines compile a BL to themselves 
: NATIVE:     \ asmforth COLON creates a native sub-routine 
\ compile time action
   CREATE                 
        !CSP                \ remember data stack position. error detection
        R11 RPUSH,          \ compile "enter sub-routine" ( 2 instructions)
                            \ <--- your program code compiles here
   DOES> ( sub-addr) @@ BL, \ Runtime: compile BL to this sub-routine
;

\ "exit sub-routine" ( 2 instructions)
: ;NATIVE   ?CSP   R11 RPOP,  RT,   ; 

\ -----------------------------------------------
\ Hi-level Forth word compiled as native sub-routines 
ASMFORTH 

NATIVE: 0=     TOS 0 CI, EQ  ;NATIVE

NATIVE: COUNT  ( Caddr -- addr len )
    DUP
    NOS 1+
   *TOS TOS C!
    TOS 8 RSHIFT 
;NATIVE 

NATIVE: BOUNDS ( adr len -- adr2 adr1) 
    NOS R1 !  
    TOS NOS +  
    R1 TOS ! 
;NATIVE 

NATIVE: ?TERMINAL ( -- ?) 
    0020 @@ BL,  NOT   \ calls ROM code to test BREAK key
;NATIVE

NATIVE: /STRING ( addr len n -- addr' len' ) 
    TOS NOS -  
    TOS 3RD +  
    DROP 
;NATIVE

NATIVE: * ( n n -- n') \ multiply operator
    NOS^ R3 !
    TOS  R3 MPY,
;NATIVE

NATIVE: UM* ( n n -- d) \ unsigned mixed multiply  
    NOS TOS MPY, 
    R5  NOS ! 
;NATIVE 

NATIVE: * (  n n -- n)
    NOS^ R3 !    
    TOS  R3 MPY,     \ cool trick ! result goes to R4
;NATIVE 

NATIVE: UM/MOD ( d n -- n n)
    TOS  R0  !   
    NOS^ TOS !
    NOS  R5  !     
    R0   TOS DIV, 
    R5   NOS !    
;NATIVE 

NATIVE: U*/ ( n n n -- n )
    TOS  R0 !      \ move TOS cache register R0 (divisor)
    NOS^ R1 !      \ POP multiplier to R1
    NOS^ TOS !     \ multiplicand -> TOS
    R1  MPY,       \ 32 bit multiply
    R5  R3 !       \ low order word to R3
    R0  TOS DIV,   \ unsigned division
;NATIVE 

NATIVE: U/ ( n n -- n ) \ unsigned divide. FAST but be careful
    TOS  R0 !          \ divisor->R0    
    TOS OFF 
    NOS^ R5 !          \ MOVE low word to r5 
    R0 TOS DIV,        \ perform unsigned division 
;NATIVE 
 
NATIVE: CALL ( arg -- ) 
\ Use @ for call thru register 
\ Use @@ for call to an address 
    R11 RPUSH, 
    BL, 
    R11 RPOP, 
;NATIVE 

NATIVE: *MFORTHEND* ;NATIVE 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

ASMFORTH ALSO FORTH DEFINITIONS 
: NEW.  \ erases the MFORTH definitions AFTER '*MFORTHEND*'
    ['] *MFORTHEND* CFA>NFA  ['] MFORTH >BODY ! ;

HOST 
HEX
: STARTUP
    WARM
    INIT-WORDLISTS
    NEW.  
    E4 7 VWTR
    PAGE ." ASMForth II  V0.84 Apr 29 2024"
    ASMFORTH
    ABORT ;

LOCK
INCLUDE DSK1.SAVESYS

' STARTUP SAVESYS DSK7.ASMFORTHII

