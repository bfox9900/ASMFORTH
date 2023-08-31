\ ASMFORTH XC makes stand alone programs .82 Aug  2023 Brian Fox
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

\
\                 Code comparisons VERSION 0.8
\ TI Assembler Syntax        ASMForth Syntax 
\ -------------------        ---------------
\               register to register 
\               --------------------
\       MOV  R1,R4                  R1 R4 ! 
\       MOV *R1,R4                  R1 @ R4 ! 
\       MOV *R1+,R4                 R1 @+ R4 ! 

\       memory to register/register to memory 
\       -------------------------------------
\ MEAT  EQU  >BEEF             HEX BEEF CONSTANT MEAT 
\ LABEL DATA 0000                  VARIABLE LABEL   
\ LABL2 DATA >DEAD                 CREATE LABL2   DEAD , 
\       LI  R0,MEAT                MEAT R0 #!
\       MOV @LABEL,R4              LABEL @ R4 ! 
\       MOV R3,@LABEL              R3 LABEL ! 

\                   memory to memory 
\                   ----------------
\       MOV @LABL2,@LABEL           LABL2 @ LABEL ! 


\ ************************************************************************
\ 10 registers are available for use as local data
\ The data stack can be used to save/restore register for nesting calls
\ The return stack can be alse be used to save/restore registers
\ BUT they must be restored before exiting a routine. 

\ /////////// REGISTER USAGE \\\\\\\\\\\
\ R0   temp
\ R1   temp
\ R2   temp
\ R3   temp 
\ R4   TOS Accumulator -or temp 
\ R5   temp
\ SP   data stack pointer
\ RP   return stack pointer
\ R8   temp 
\ R9   Forth interpreter pointer 
\ R10  holds NEXT address
\ R11  sub-routine linkage
\ R12  CRU I/O
\ R13  for BWLP -or- temp 
\ R14  for BWLP -or- temp 
\ R15  for BWLP -or- temp 


NEEDS DUMP       FROM DSK1.TOOLS
NEEDS MARKER     FROM DSK1.MARKER
NEEDS WORDSLIST  FROM DSK1.WORDLISTS
NEEDS DIR        FROM DSK1.DIR
NEEDS FORGET     FROM DSK1.FORGET
NEEDS TALLOT     FROM DSK7.MFORTHASM  

HERE

ONLY FORTH DEFINITIONS

\ hand word for later
: ALIAS  ( XT -- ) >R : R> COMPILE, POSTPONE ; ;

VOCABULARY COMPILERS  \ the cross-compiler's words 
VOCABULARY TARGETS    \ your program's words 

\ wordlist management 
: HOST      ONLY FORTH ALSO ASSEMBLER ALSO FORTH DEFINITIONS ;

\ compiler has words that are interpreted
: COMPILER  ONLY FORTH ALSO ASSEMBLER ALSO COMPILERS DEFINITIONS  ;

\ TARGET removes FORTH from the search order 
: TARGET    ONLY COMPILERS ALSO ASSEMBLER ALSO TARGETS DEFINITIONS ;

\ ==========================================================
\ Some wordlist magic here to make the first TARGETS word
\ Then a way to reset the TARGETS wordlist to that 1st word. 

COMPILER 

HEX 
: RESET  
    ['] TARGETS >BODY OFF  ( reset wordlist )
    NEW                                     ( reset HEAP ) 
    DEAD @@ BL, \ first address contains call to a TARGET word 
;    

\ ===========================================================
\ Cross-compiler variables,constants and relocation functions
COMPILER 
VARIABLE LORG     2000 LORG !   \ LORG is TI-99 load address

       2000 CONSTANT CDATA  \ CODE compiles to this buffer
CDATA CELL+ CONSTANT 'BOOT  \ holds program boot address

\ compute diff. between actual load-address and image buffer
: OFFSET   ( -- n)  LORG @ CDATA -  ;
: REL>TARG  ( relocated -- target)  OFFSET - ;
\ target image fetch and store take relocated addresses and convert them
: T!      ( n relocated -- ) REL>TARG ! ;
: T@      ( relocated -- n)  REL>TARG @ ;

\ ========================================================
\ steal some tools from HOST Forth for the COMPILER.
\ This lets us use these words in TARGET mode when we are cutoff
\ from the HOST FORTH. 

COMPILER 
: COMPILER COMPILER ;
: TARGET   TARGET   ;
: HEX   HEX ;
: DECIMAL DECIMAL ;

: \    POSTPONE \ ; IMMEDIATE 
: (    POSTPONE ( ; IMMEDIATE 
: DUMP   DUMP ;
: WORDS  WORDS ;
: .S     .S ;
: MARKER  MARKER ;

\ ========================================================
\ source and destination smarts 
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

CR .( TARGET sub-routine creator)
: SUB:   
    CREATE        \ create the name in the HOST dictionary 
    THERE ,       \ remember the entry address in the HOST dictionary 
    R11 RPUSH,    \ SUB-ROUTINE linkage register is R11. No native nesting
    DOES> @       \ Return stored address when name is invoked
; 

\ "exit sub-routine" ( 2 instructions)
: ;SUB   R11 RPOP,  RT,  ;

\ some simple Target data makers (rename them later )
: TCREATE  THERE CONSTANT  ;  \ just returns the TARGET address 
: TVAR     CREATE  THERE , 0 T, DOES> @ ; \ init to 0, return target address 
: TCONST ( n --) CREATE  THERE ,   T,  DOES> @ @ ;

\ These are the HOST Forth colon/semi-colon RENAMED
' : ALIAS H: 
' ; ALIAS ;H  IMMEDIATE 

\ Named stack items (in memory) in Assembler wordlist 
 : NOS   *SP  ;    \ Next on Stack register
 : NOS^  *SP+ ;    \ Use NOS and then pop it 
 : 3RD   2 (SP) ;
 : 4TH   4 (SP) ;
 : 5TH   6 (SP) ;
 : 6TH   8 (SP) ;

HEX
\ ======================================================
\ fetch previous instruction code
: LOOKBACK ( -- u)  HERE 2- @ ;

\ tail call optimizing ;SUB. USE ONLY IF LAST WORD IS SUB:
: -; ( --  )
    LOOKBACK   ( addr )   \ get entry address of sub-routine
    2 CELLS +  ( addr' )  \ move past the 2 sub-routine ENTRY instructions
    -04 ALLOT             \ erase BL @addr instruction
    ( addr') @@ B,        \ compile a branch to the NEW sub-routine (B @addr)
    COMPILER 
; 

\ load register with literal argument 
\ usage:   BEEF R1 #! 
\       02 BYTE R1 #!   \ load 02 as low bits of R1 
: #!     ( n REG -- )   ?REGISTER SWAP LI, ; \ n -> REG

\ addr literal to register 
: #+!    ( lit reg -- ) ?REGISTER SWAP  AI, ;

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
: PUSH ( arg)     ?REGISTER  PUSH, ;
: POP  ( arg --)  ?REGISTER  POP,  ;

\ =========================================================
\ Chucks' 'A' register from F21. Used for addresses

8 CONSTANT AR 

H: A    ( -- n) DUP   AR TOS ! ;H   \ A pushed to TOS 
H: @A   ( -- n) DUP   AR @ TOS ! ;H   \ Memory at A pushed to TOS  
H: @A+  ( -- n) DUP   AR @+ TOS ! ;H  \ fetch contents of A, push to TOS, inc A 

H: !A   ( n --) TOS   AR @ !  DROP ;H \ pop TOS to memory at address in A 
H: !A+  ( n --) TOS   AR @+ !  DROP ;H \ pop TOS to memory at address in A, inc A 
H: A!   ( n --) TOS   AR !  DROP ;H


CR .( Forth Intrinics)

\ inc/dec using Forth mnemonics 
: 1+   ( arg -- ) <DST> INC, ;
: 1-   ( arg -- ) <DST> DEC, ;

: 2+   ( arg -- ) <DST> INCT, ;
: 2-   ( arg -- ) <DST> DECT, ;

: ><   ( arg -- ) <DST> SWPB, ;

\ primitive addition and subtraction uses two args 
: ADD    ( arg arg ) <DST> ADD, ;
: SUB    ( arg arg ) <DST> SUB, ;


: C+     ( arg arg ) SWAP ><  SWAP <DST> ADDB, ;  \ add bytes 
: C-     ( arg arg ) SWAP ><  SWAP <DST> SUBB, ;


: OR     ( arg arg )  <DST> SOC, ;       
: XOR    ( n n -- n)  ?REGISTER XOR, ;
: AND    ( src dst --) SWAP INVERT  SWAP <DST> SZC, ;

: #      ( n -- )  TOS PUSH,  TOS #! ;  \ put literal into TOS

\ Immediate instructions compile a literal argument 

: #AND  ( reg lit -- ) >R ?REGISTER R> ANDI, ; 
: #OR   ( reg lit -- ) >R ?REGISTER R> ORI, ;

: DUP   ( n -- n n) TOS PUSH ;
: DROP  ( n -- )    TOS POP  ;

.(  return stack operators. Rstack cached in R11)
: RDROP          *RP+ R11 ! ; 
: RDUP    RP 2-   R11 *RP ! ;

: RPUSH  ( register --) ?REGISTER  RDUP ( Rx) R11 ! ; 
: RPOP   ( register --) ?REGISTER        R11 SWAP !  RDROP ;
: DUP>R ( n -- n) TOS RPUSH ;
: >R    ( n --)   DUP>R DROP ;
: R>    ( -- n)   TOS RPOP ;
: R@    ( -- n)   DUP  R11 TOS ! ;

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

: NOP    ( -- ) 0 JMP, ;

: ABS    ( arg -- ) <DST> ABS, ;
: NEGATE ( arg --)  <DST> NEG, ;
: INVERT ( n -- )   <DST> INV, ;
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

\ aliases for jump tokens 
: =      EQ ;
: <>     NE ; 
: <      LTE ;
: >      GTE ;
: U>     LO ;
: U<     HI ;
: U>=    HE ;
: U<=    LE ;

: NOT    ( -- )  R1 STST,  R1 2000 ANDI, ;  \ invert EQ flag in status arg.

\ 2 item comparisons. USE CMP or CMPB as required 
: CMP   ( reg gad) <DST> CMP, ;
: CMPB  ( reg gad) <DST> CMPB, ;
: #CMP  ( reg lit) SWAP ?REGISTER SWAP CI, ;

\ ********* ANS/ISO Forth, Stack operators ****************
: NIP   ( n1 n2 -- n2) SP 2+ ;
: OVER  ( n1 n2 -- n1 n2 n1)  DUP  3RD TOS ! ;
: 2DROP ( n n --)   DROP DROP ;

: 2DUP  ( a b -- a b a b ) 
    -4 SP #+!   \  make room for 2 cells
    4TH NOS !      
    TOS 3RD ! ;

: SWAP  ( n1 n2 -- n2 n1) 
      TOS W !  
      NOS TOS !  
      W NOS ! ; 

\  ****  ANS FORTH WORDS USE THE DATA STACK ****
: ALIGNED ( n -- n)    TOS 1+  TOS -2 #AND ;
: AND     ( w w -- w ) NOS INV,  NOS^ TOS SZC, ;
: 2@      ( addr -- d) 3RD PUSH,  *TOS TOS ! ;   \ fetch double integer
: 2!      ( d addr --) NOS^ *TOS !  NOS^ 3RD !  DROP ;


\      ////////////////////////////////////////////////////////
\      --------------  higher level constructs  --------------
\      \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

\ synonyms from Assembler 
: IF     IF, ; 
: THEN   ENDIF, ; 
: ELSE   ELSE, ; 
: BEGIN  BEGIN, ; 
: WHILE  WHILE, ;
: AGAIN  AGAIN, ; 
: UNTIL  UNTIL, ; 
: REPEAT REPEAT, ; 

CR .( FOR/NEXT *NEW* FASTER IN REGISTER )
\ Simple 'nestable' loop.
\ ARG is any valid cell argument, which is stored in R11
\ Use R11 as a loop index.  Use  nn RP @ 1-  to STEP down faster.
\ Use a register if you need an up-counter

: FOR   ( arg --) 
    R11 RPUSH 
    ( arg) R11 !  
    BEGIN ; 

\ Alternative using literal number, N goes thru TOS -> R11 
: #FOR  ( arg --)  
    R11 RPUSH      \ save R11  
    ( arg) R11 #!  \ LI R11,arg
    BEGIN ;

: NEXT  ( -- )   
    R11 1-      \ DEC  R11 
    NC UNTIL    \ JOC  BEGIN 
    R11 RPOP ;  \ MOV *RP+,R11  

: NEXT2  \ dect loop counter by 2 
    R11 2-  
    NC UNTIL 
    R11 RPOP ; 

\ -----------------------------------------------
\ Hi-level Forth word macros 

\ Forth style math using only the stack 
H: +  NOS^ TOS ADD ;
H: -  NOS^ TOS SUB NEGATE ;

H: COUNT  ( Caddr -- addr len )
    DUP
    NOS 1+
   *TOS TOS C!
    TOS 8 RSHIFT 
;H 

H: BOUNDS ( adr len -- adr2 adr1) 
    NOS R1 !  
    TOS NOS +  
    R1 TOS ! 
;H 

H: ?TERMINAL ( -- ?) 
HEX  0020 @@ BL,  NOT 
;H

H: /STRING ( addr len n -- addr' len' ) 
    TOS NOS -  
    TOS 3RD +  
    DROP 
;H

H: * ( n n -- n') \ multiply operator
    NOS^ R3 !
    TOS  R3 MPY,
;H

H: UM* ( n n -- d) \ unsigned mixed multiply  
    NOS TOS MPY, 
    R5  NOS ! 
;H 

H: * (  n n -- n)
    NOS^ R3 !    
    TOS  R3 MPY,     \ cool trick ! result goes to R4
;H 

H: UM/MOD ( d n -- n n)
    TOS  R0  !   
    NOS^ TOS !
    NOS  R5  !     
    R0   TOS DIV, 
    R5   NOS !    
;H 

H: U*/ ( n n n -- n )
    TOS  R0 !      \ move TOS cache register R0 (divisor)
    NOS^ R1 !      \ POP multiplier to R1
    NOS^ TOS !     \ multiplicand -> TOS
    R1  MPY,       \ 32 bit multiply
    R5  R3 !       \ low order word to R3
    R0  TOS DIV,   \ unsigned division
;H 

H: U/ ( n n -- n ) \ unsigned divide. FAST but be careful
    TOS  R0 MOV,       \ divisor->R0    
        TOS CLR,
    NOS^ R5 MOV,       \ MOVE low word to r5 
    R0  TOS DIV,       \ perform unsigned division 
;H 

COMPILER 
\ automatically compiles correct code for a register or an address 
H: CALL ( arg -- )  <SRC> BL, ;H 

\ run cross-compiled code from HOST Forth 
HEX 
CODE RUN  ( addr -- addr)  0694 ,  C136 ,   045A , ENDCODE 
\ ______________________________________________________________
\ Forth virtual machine setup directives
H: WORKSPACE ( addr --) LWPI, ;H        \ Forth workspace
H: DSTACK    ( addr --) SP SWAP LI, ;H  \ data stack
H: RSTACK    ( addr --) RP SWAP LI, ;H  \ return stack


\ cross-compiler memory compilers renamed to standard Forth
' T,     ALIAS , 
' TC,    ALIAS C, 
' TALLOT ALIAS ALLOT 
' THERE  ALIAS HERE 

' TCREATE ALIAS CREATE 
' TVAR    ALIAS VARIABLE 
' TCONST  ALIAS CONSTANT

\ : now sets TARGET more, ;  sets COMPILER mode 
H: :   TARGET SUB: ;H 
H: ;   ;SUB COMPILER ;H  

\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

COMPILER 
HEX
H: STARTUP
    WARM
    E4 7 VWTR
    INIT-WORDLISTS
    PAGE ." ASMForth XC  V0.82 Aug 20 2023"
    COMPILER 
    RESET 
    .FREE
    ORDER 
    ABORT ;H

HOST 
LOCK
INCLUDE DSK1.SAVESYS

COMPILER ' STARTUP SAVESYS DSK7.ASMFORTHXC
