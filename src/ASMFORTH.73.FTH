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
INCLUDE DSK7.ASM9900

HERE

: HOST     
  ONLY FORTH ALSO ASSEMBLER ALSO MFORTH ALSO FORTH DEFINITIONS ; 

: ASMFORTH 
  ONLY FORTH ALSO ASSEMBLER ALSO MFORTH DEFINITIONS ;

\ compile forth words that will Assemble code when executed
ALSO ASSEMBLER DEFINITIONS 
: ;MACRO   POSTPONE ;  ;  IMMEDIATE
: MACRO:  :  ;

\ Named stack items (in memory)
: NOS   *SP  ;    \ Next on Stack register
: NOS^  *SP+ ;    \ Use NOS and then pop it 
: 3RD   2 (SP) ;
: 4TH   4 (SP) ;
: 5TH   6 (SP) ;
: 6TH   8 (SP) ;

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

DECIMAL
: REG?      ( n -- ?) 0 16 WITHIN ;
: ADDRESS?  ( n -- ?) 8191 > ; \ lowest RAM address is 8192 

: ?REGISTER ( n --) REG? 0= ABORT" Register expected" ;
HEX
: ?ADDR   ( n --)  2000 < ABORT" Invalid memory address" ;

: EQU   CONSTANT ; \ alias 

\ load register with immediate argument 
\ usage:   BEEF R1 #! 
\       02 BYTE R1 #!   \ load 02 as low bits of R1 
: #!    ( n REG -- ) DUP ?REGISTER SWAP LI, ; \ n -> REG
: BYTE   ( 0c --  0c00 )  ><  ; \ swap byte to other side of register 

\ fetch 
: @       ** ;  \ indirect addressing alias 
: @+      *+ ;  \ indirect addressing, auto-increment alias 

\ store  
: !    ( src dst -- ) MOV, ; 
: C!   ( c  ARG -- )  MOVB, ;

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

\ Not really needed but Forth consistent
: +!  ( src mem -- ) ?ADDR  @@ + ; 

: RDROP ( -- )  RP 2+ ;

: NOP    ( -- )     0 JMP, ;
: ABS    ( arg -- ) ABS, ;
: NEGATE ( n --)    NEG, ;
: OR     ( src dst -- ) SOC, ;
: ON     ( arg -- )  SETO, ;
: OFF    ( arg --)   CLR, ;
: ><     ( arg -- )  SWPB, ;

\ STACK SPECIFIC operators 

: ALIGNED ( n -- n)  TOS INC,  TOS -2 #AND ;
: AND   ( w w -- w ) NOS INV,  NOS @+ TOS SZC, ;
: 2@    ( addr -- d) 2 (TOS) PUSH,  *TOS TOS MOV, ; \ fetch double integer


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

: NOT    ( -- )  R1 STST,  R1 2000 ANDI, ;  \ invert EQ flag in status arg.

\ 2 item stack comparisons. USE CMP or CMPB as required 
: CMP   ( reg reg) CMP, ;
: CMPB  ( reg reg) CMPB, ;
: #CMP  ( reg lit) CI, ;  \ compare immediate needs a preceding literal 


\ ASMFORTH aliases for jump tokens 
: =      EQ ;
: <>     NE ; 
: <      LTE ;
: >      GTE ;
: U>     LO ;
: U>=    HE ;
: U<     HI ;
: U<=    LE ;

CR .( branching and looping)
ASMFORTH 
: IF     ( addr token -- 'jmp') IF, ;
: THEN   ( 'jmp addr --)  ENDIF, ;
: ELSE   ( -- addr ) ELSE, ;

: BEGIN  ( -- addr)  BEGIN,  ;
: WHILE  ( token -- *while *begin) WHILE,  ;
: AGAIN  ( *begin --) AGAIN, ;
: UNTIL  ( *begin token --) UNTIL, ;
: REPEAT ( *while *begin -- ) AGAIN, ENDIF, ;

\ ********* ANS/ISO Forth, Stack operators ****************
: DUP   ( n -- n n) TOS PUSH ;
: DROP  ( n -- )    TOS POP  ;
: NIP   ( n1 n2 -- n2) SP 2+ ;
: OVER  ( n1 n2 -- n1 n2 n1)  DUP  3RD TOS ! ;
: 2DROP ( n n --)   DROP DROP ;

\ ASMFORTH SWAP does not use another register. It uses Rstack.
: SWAP  ( n1 n2 -- n2 n1) DUP>R  NOS TOS !   RP @+  NOS ! ; 

\ ..................................................................

\      ////////////////////////////////////////////////////////
\      --------------  higher level constructs  --------------
\      \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\
: BOUNDS ( adr len -- adr2 adr1) NOS R1 MOV,  TOS NOS ADD,  R1 TOS MOV, ;
: ?TERMINAL ( -- ?) 0020 @@ BL,  NOT ;

\ CUT n characters from left side of STRING (addr,len)
: /STRING ( addr len n -- addr' len' ) TOS NOS SUB,  TOS 2 (SP) +  DROP ;

: ;CODE    NEXT,  ENDCODE ; \ returns to Forth

CR .( FOR/NEXT)
\ Simple 'nestable' loop.
\ Uses return stack for index because registers are in short supply.
\ Speed reduction is ~11% on 9900 VS index in a register.
\ Use  R@  as a loop index.  Use  nn RP @ 1-  to STEP down faster.
\ Use a register if you need an up-counter

: FOR   ( n --)  >R  BEGIN, ; \ n must be in TOS register 
: NEXT  ( -- )   RP @ 1-   NC UNTIL, RDROP ;
: NEXT2          RP @ 2-   NC UNTIL, RDROP ; 


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
    *TOS TOS C!
    TOS 8 RSHIFT 
;MACRO 

MACRO: * ( n n -- n') \ multiply operator
    NOS @+ R3 !
    TOS R3 MPY,
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
    TOS  R0 !     \ move TOS cache register R0 (divisor)
    NOS^ R1 !     \ POP multiplier to R1
    NOS^ TOS !    \ multiplicand -> TOS
    R1  MPY,      \ 32 bit multiply
    R5  R3 !      \ low order word to R3
    R0  TOS DIV,   \ unsigned division
;MACRO 

MACRO: U/ ( n n -- n ) \ unsigned divide. FAST but be careful
    TOS  R0 MOV,     \ divisor->R0    
        TOS CLR,
   *SP+  R5 MOV,     \ MOVE low word to r5 
    R0  TOS DIV,     \ perform unsigned division 
;MACRO 


MACRO: CALL ( arg -- ) 
\ Use @ for call thru register 
\ Use @@ for call to an address 
    R11 RPUSH, 
    BL, 
    R11 RPOP, 
;MACRO 

CODE MIN    ( n1 n2 -- n)
            *SP TOS CMP,    \ compare n1 & n2
            @@1 JLT,       \ if n1 < n2 goto @@1:
            SP INCT,       \ otherwise NIP n1
            NEXT,
+CODE MAX   ( n1 n2 -- n)
            *SP  TOS CMP,   \ compare n1 & n2
            @@2 JGT,       \ if n1 > n2 goto @@1:
            SP INCT,       \ otherwise NIP n1
            NEXT,
@@1: @@2:   TOS POP,       \ DROP n1, refill TOS


MACRO: *MFORTHEND* ;MACRO 
\ \\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\\

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
    PAGE ." ASMForth II  V0.73 Mar 3 2023"
    ASMFORTH
    ABORT ;

LOCK
INCLUDE DSK1.SAVESYS

' STARTUP SAVESYS DSK7.ASMFORTHII
