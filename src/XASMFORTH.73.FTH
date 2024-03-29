\ ASMFORTH II   Feb 2023 Brian Fox
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

\                 Code comparisons
\ TI Assembler Syntax        ASMForth Syntax 
\ -------------------        ---------------
\               register to register 
\               --------------------
\       MOV  R1,R4                  R1 R4 ! 
\       MOV *R1,R4                  R1 @ R4 ! 
\       MOV *R1+,R4                 R1 @+ R4 ! 

\       memory to register/register to memory 
\       -------------------------------------
\ MEAT  EQU  >BEEF             HEX BEEF EQU MEAT 
\ LABEL DATA 0000                  VARIABLE LABEL   
\ LABL2 DATA >DEAD                 CREATE LABL2   DEAD , 
\       LI  R0,MEAT                MEAT  R0 LD 
\       MOV @LABEL,R4              LABEL @@ R4 ! 
\       MOV R3,@LABEL              R3 LABEL @@ ! 

\                   memory to memory 
\                   ----------------
\       MOV @LABL2,@LABEL           LABL2 @@ LABEL @@ ! 


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


NEEDS DUMP FROM DSK1.TOOLS
NEEDS MARKER FROM DSK1.MARKER
NEEDS WORDSLIST FROM DSK1.WORDLISTS

ONLY FORTH DEFINITIONS
VOCABULARY MFORTH

VOCABULARY ASSEMBLER
ONLY FORTH ALSO ASSEMBLER DEFINITIONS
INCLUDE DSK7.XASM9900

HERE

: HOST     
  ONLY FORTH ALSO ASSEMBLER ALSO MFORTH ALSO FORTH DEFINITIONS ; 

: ASMFORTH 
  ONLY FORTH ALSO ASSEMBLER ALSO MFORTH DEFINITIONS ;

\ compile forth words that will Assemble code when executed
ALSO ASSEMBLER DEFINITIONS 

: ;MACRO   POSTPONE ;  ;  IMMEDIATE
: MACRO:  :  ;

\ Named stack items (in memory) in Assembler wordlist 
 : NOS   *SP  ;    \ Next on Stack register
 : NOS^  *SP+ ;    \ Use NOS and then pop it 
 : 3RD   2 (SP) ;
 : 4TH   4 (SP) ;
 : 5TH   6 (SP) ;
 : 6TH   8 (SP) ;

DECIMAL
: REG?      ( n -- ?) 0 16 WITHIN ;
: ADDRESS?  ( n -- ?) 8191 > ; \ lowest RAM address is 8192 

: ?REGISTER ( n --) REG? 0= ABORT" Register expected" ;
HEX
: ?ADDR   ( n --)  2000 U< ABORT" Invalid memory address" ;
: SYMBOL? ( n --?) 20 = ; \ is ARG using symbolic addressing

: EQU   CONSTANT ; \ alias 

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

\ Add some smarts to C! 
: C!   ( c dst -- )  MOVB, ; 

\ Failed
 \   DUP SYMBOL? IF  MOVB,  EXIT THEN  \ do MOVB and get out 
\ dst must be a register    
\    DUP>R       \ save copy of DST register 
\    MOVB,       \ compile instruction 
\    R> 8 SRL,   \ perform swap byte on that register 
\ ;

ASMFORTH 
\ load register with immediate argument 
\ usage:   BEEF R1 #! 
\       02 BYTE R1 #!   \ load 02 as low bits of R1 
: #!    ( n REG -- ) DUP ?REGISTER SWAP LI, ; \ n -> REG
: BYTE   ( 0c --  0c00 )  ><  ; \ swap byte to other side of register 

\ add error checking to Assembler versions 
\ fetch 
: @    DUP ?REGISTER  ** ; \ indirect addressing alias 
: @+   DUP ?REGISTER  *+ ; \ indirect addressing, auto-increment alias 
: @@   DUP ?ADDR  @@ ;

\ store  
: !    ( src dst -- ) MOV, ; 
: +!   ( src mem -- ) ?ADDR  @@ + ; 

\ push/pop  any register 
: PUSH   PUSH, ;
: POP    POP,  ;

CR .( Forth Intrinics)

\ inc/dec using Forth mnemonics 
: 1+   ( arg -- )  INC, ;
: 2+   ( arg -- )  INCT, ;
: 1-   ( arg -- )  DEC, ;
: 2-   ( arg -- )  DECT, ;

: +      ( arg arg )  ADD, ;    
: -      ( arg arg )  SUB, ;

: OR     ( arg arg )  SZC, ;       
: XOR    ( n n -- n)  XOR, ;
: AND    ( src dst --) SWAP INV,  SWAP  SZC, ;

: #      ( n -- )  TOS PUSH,  TOS #! ;  \ put literal into TOS
: INVERT ( n -- )  INV, ;

\ Immediate instructions compile a literal argument 
: #AND  ( reg lit -- ) ANDI, ; 
: #OR   ( reg lit -- )  ORI, ;
: #+    ( reg lit -- )   AI, ;

\ ___________________________________________________________________
.(  return stack operators .)
: RPUSH  RPUSH, ; \ aliases from the assembler 
: RPOP   RPOP,  ;

\ ANS Forth operators use DATA stack.  
\ **Use RP register for Reg to Reg return stack access 
: DUP>R  TOS RPUSH ;
: >R    ( n --) DUP>R TOS POP, ;
: R>    ( -- n) TOS RPOP ;
: R@    ( -- n) TOS PUSH,  RP @ TOS ! ;

.( .)
: LSHIFT   SLA,  ;
: RSHIFT   SRA,  ;

: 2*     ( n -- n )  1 LSHIFT ;
: 4*                 2 LSHIFT ;
: 8*                 3 LSHIFT ;
: 2/     ( n -- n)   1 RSHIFT ;

: RDROP ( -- )  RP 2+ ;

: NOP    ( -- )     0 JMP, ;
: ABS    ( arg -- ) ABS, ;
: NEGATE ( n --)    NEG, ;
: OR     ( src dst -- ) SOC, ;
: ON     ( arg -- )  SETO, ;
: OFF    ( arg --)   CLR, ;
: ><     ( arg -- )  SWPB, ;

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
: CMP   ( reg reg) CMP, ;
: CMPB  ( reg reg) CMPB, ;
: #CMP  ( reg lit) CI, ;  \ compare immediate needs a preceding literal 

\ CR .( branching and looping) \ ** Now in ASM9900II 
\ ASMFORTH 
\ : IF     ( addr token -- 'jmp') IF, ;
\ : THEN   ( 'jmp addr --)  ENDIF, ;
\ : ELSE   ( -- addr ) ELSE, ;

\ : BEGIN  ( -- addr)  BEGIN,  ;
\ : WHILE  ( token -- *while *begin) WHILE,  ;
\ : AGAIN  ( *begin --) AGAIN, ;
\ : UNTIL  ( *begin token --) UNTIL, ;
\ : REPEAT ( *while *begin -- ) AGAIN, ENDIF, ;

\ ********* ANS/ISO Forth, Stack operators ****************
: DUP   ( n -- n n) TOS PUSH ;
: DROP  ( n -- )    TOS POP  ;
: NIP   ( n1 n2 -- n2) SP 2+ ;
: OVER  ( n1 n2 -- n1 n2 n1)  DUP  3RD TOS ! ;
: 2DROP ( n n --)   DROP DROP ;

: 2DUP  ( a b -- a b a b ) 
    SP -4 #+      \  make room for 2 cells
    4TH NOS !      
    TOS 3RD ! ;

\ ASMFORTH SWAP does not use another register. It uses Rstack.
: SWAP  ( n1 n2 -- n2 n1) DUP>R  NOS TOS !   RP @+  NOS ! ; 
\  ****  ANS FORTH WORDS USE THE DATA STACK ****
: ALIGNED ( n -- n)  TOS INC,  TOS -2 #AND ;
: AND     ( w w -- w ) NOS INV,  NOS^ TOS SZC, ;
: 2@      ( addr -- d) 3RD PUSH,  TOS @ TOS ! ; \ fetch double integer
: 2!      ( d addr -- ) NOS^ *TOS !  NOS^ 3RD !  DROP ;


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

CR .( FOR/NEXT)
\ Simple 'nestable' loop.
\ ARG is any valid cell argument, which is pushed onto Rstack 
\ Speed reduction is ~11% on 9900 VS index in a register.
\ Use  R@  as a loop index.  Use  nn RP @ 1-  to STEP down faster.
\ Use a register if you need an up-counter

: FOR   ( arg --) RPUSH BEGIN ; 
: #FOR  ( n --) # >R BEGIN ; \ literal goes thru TOS -> Rstack, DROP
: NEXT  ( -- )   RP @ 1-   NC UNTIL RDROP ;
: NEXT2          RP @ 2-   NC UNTIL RDROP ; 


CR .( sub-routine creator)
\ subs call themselves when invoked by compiling a BL instruction
\ into the program
MACRO: :
\ compile time action
   CREATE  !CSP
           R11 RPUSH,        \ compile "enter sub-routine" ( 2 instructions)
                             \ <--- your program code compiles here
   DOES> ( sub-addr) @@ BL,  \ Runtime: compile BL to this sub-routine
;MACRO 


\ "exit sub-routine" ( 2 instructions)
MACRO: ;   ?CSP  R11 RPOP,  RT, ;MACRO 

\ -----------------------------------------------
\ Hi-level Forth word macros 
ASMFORTH 
MACRO: COUNT  ( Caddr -- addr len )
    DUP
    NOS 1+
    TOS @ TOS C!
    TOS 8 RSHIFT 
;MACRO 

MACRO: BOUNDS ( adr len -- adr2 adr1) 
    NOS R1 !  
    TOS NOS +  
    R1 TOS ! 
;MACRO 

MACRO: ?TERMINAL ( -- ?) 
    0020 @@ BL,  NOT 
;MACRO

MACRO: /STRING ( addr len n -- addr' len' ) 
    TOS NOS -  
    TOS 3RD +  
    DROP 
;MACRO

MACRO: * ( n n -- n') \ multiply operator
    NOS^ R3 !
    TOS  R3 MPY,
;MACRO

MACRO: UM* ( n n -- d) \ unsigned mixed multiply  
    NOS TOS MPY, 
    R5  NOS ! 
;MACRO 

MACRO: * (  n n -- n)
    NOS^ R3 !    
    TOS  R3 MPY,     \ cool trick ! result goes to R4
;MACRO 

MACRO: UM/MOD ( d n -- n n)
    TOS  R0  !   
    NOS^ TOS !
    NOS  R5  !     
    R0   TOS DIV, 
    R5   NOS !    
;MACRO 

MACRO: U*/ ( n n n -- n )
    TOS  R0 !      \ move TOS cache register R0 (divisor)
    NOS^ R1 !      \ POP multiplier to R1
    NOS^ TOS !     \ multiplicand -> TOS
    R1  MPY,       \ 32 bit multiply
    R5  R3 !       \ low order word to R3
    R0  TOS DIV,   \ unsigned division
;MACRO 

MACRO: U/ ( n n -- n ) \ unsigned divide. FAST but be careful
    TOS  R0 MOV,       \ divisor->R0    
        TOS CLR,
    NOS^ R5 MOV,       \ MOVE low word to r5 
    R0  TOS DIV,       \ perform unsigned division 
;MACRO 

MACRO: CALL ( arg -- ) 
\ Use @ for call thru register 
\ Use @@ for call to an address 
    R11 RPUSH, 
    BL, 
    R11 RPOP, 
;MACRO 

MACRO: *MFORTHEND* ;MACRO 
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
    PAGE ." XASMForth II  V0.74 Mar 12 2023"
    ASMFORTH
    ABORT ;

LOCK
INCLUDE DSK1.SAVESYS

' STARTUP SAVESYS DSK7.XASMFORTH
