\ ASMForthII RPN Assembler                       Mar 8 2023  Brian Fox 

\ Meant to be used with a separate wordlist
\ Based on TI-FORTH ASSEMBLER modified by Mark Wills, Turboforth
\ Simplfied branching and looping by Brian Fox

\ *NOTES:
\     Compare instruction has been changed to CMP,
\     Changed  A, and S, to ADD, SUB,
 
WARNINGS OFF
 
CR .( CAMEL99 Assembler V2.2 Dec 2020)
 
HERE   \ save the dictionary pointer for size calc. at end

\ target memory management
VARIABLE TDP   \ target dictionary pointer

\ set where the Cross-assembler puts its code
HEX
: ORG   ( addr -- ) TDP ! ;
: NEW   2000 2000 FF FILL   1FFF H ! ; \ allocate the entire HEAP

\ Target versions of HERE and ALLOT
: THERE  ( -- addr) TDP @ ;
: TALLOT ( n -- )   TDP +! ;

\ integer and byte "Target" compilers
: T,     ( n -- )   THERE !  2 TALLOT ;
: TC,    ( c -- )   THERE C! 1 TALLOT ; 


HEX
CR .( Loading Assembler @ ) HERE U.
DECIMAL
 0 CONSTANT  R0    1 CONSTANT  R1
 2 CONSTANT  R2    3 CONSTANT  R3
 4 CONSTANT  R4    5 CONSTANT  R5
 6 CONSTANT  R6    7 CONSTANT  R7
 8 CONSTANT  R8    9 CONSTANT  R9
10 CONSTANT R10   11 CONSTANT R11
12 CONSTANT R12   13 CONSTANT R13
14 CONSTANT R14   15 CONSTANT R15

HEX
\ Wycove assembler register syntax:
: @@        020    ;  \ symbolic addressing
: **        010 +  ;  \ indirect addressing
: *+        030 +  ;  \ indirect addressing, auto-increment
: ()        20  +  ;  \ indexed addressing

\ INDIRECT addressing register names 
: *R0    R0 ** ; 
: *R1    R1 ** ;    : *R2    R2 ** ;   : *R3    R3 ** ;
: *R4    R4 ** ;    : *R5    R5 ** ;   : *R6    R6 ** ;
: *R7    R7 ** ;    : *R8    R8 ** ;   : *R9    R9 ** ;
: *R10   R10 ** ;   : *R11  R11 ** ;   : *R12  R12 ** ;
: *R13   R13 ** ;   : *R14  R14 ** ;   : *R15  R15 ** ;

\ INDIRECT addressing, auto-increment register names 
: *R0+    R0 *+ ; 
: *R1+    R1 *+ ;    : *R2+    R2 *+ ;   : *R3+    R3 *+ ;
: *R4+    R4 *+ ;    : *R5+    R5 *+ ;   : *R6+    R6 *+ ;
: *R7+    R7 *+ ;    : *R8+    R8 *+ ;   : *R9+    R9 *+ ;
: *R10+   R10 *+ ;   : *R11+  R11 *+ ;   : *R12+  R12 *+ ;

\ indexed addressing register names 
: (R0)    TRUE ABORT" R0 cannot be indexed" ; 
: (R1)    R1 () ;   : (R2)    R2 () ;   : (R3)    R3 () ;
: (R4)    R4 () ;   : (R5)    R5 () ;   : (R6)    R6 () ;
: (R7)    R7 () ;   : (R8)    R8 () ;   : (R9)    R9 () ;
: (R10)  R10 () ;   : (R11)  R11 () ;   : (R12)  R12 () ;
: (R13)  R13 () ;   : (R14)  R14 () ;   : (R15)  R15 () ;

 \ ============================================================
CR .( CAMEL99 Forth named registers)
R4 CONSTANT TOS   R6 CONSTANT SP    R8 CONSTANT W    
R7 CONSTANT RP    R9 CONSTANT IP

: *TOS     TOS ** ;  : *TOS+    TOS *+ ;  : (TOS)    TOS () ; 
: *SP       SP ** ;  : *SP+      SP *+ ;  : (SP)      SP () ; 
: *RP       RP ** ;  : *RP+      RP *+ ;  : (RP)      RP () ;
: *W        W **  ;  : *W+       W *+  ;  : (W)       W ()  ;
: *IP       IP ** ;  : *IP+      IP *+ ;  : (IP)      IP () ;  

HEX
: ADR? ( n -- ? ) DUP 1F > SWAP 30 < AND ;  \ address or register?
: GOP' ( arg instr --)
       OVER ADR?
       IF   + T, T,                    \ compile instruction & address
       ELSE + T,                      \ compile register
       THEN ;
 
: GOP ( instr --) CREATE , DOES> @ GOP' ;
 
0440 GOP B,    0680 GOP BL,   0400 GOP BLWP,
04C0 GOP CLR,  0700 GOP SETO, 0540 GOP INV,
0500 GOP NEG,  0740 GOP ABS,  06C0 GOP SWPB,
0580 GOP INC,  05C0 GOP INCT, 0600 GOP DEC,
0640 GOP DECT, 0480 GOP X,
 
: GROP     CREATE , DOES> @ SWAP 40 * + GOP' ;
 
2000 GROP COC,  2400 GROP CZC,  2800 GROP XOR,
3800 GROP MPY,  3C00 GROP DIV,  2C00 GROP XOP,
 
: GGOP     CREATE ,
           DOES> @ SWAP DUP ADR?
                 IF   40 * + SWAP >R GOP' R> ,
                 ELSE 40 * + GOP'  THEN ;
HEX
A000 GGOP ADD,  B000 GGOP ADDB, 8000 GGOP CMP, 9000 GGOP CMPB,
6000 GGOP SUB,  7000 GGOP SUBB, E000 GGOP SOC, F000 GGOP SOCB,
4000 GGOP SZC,  5000 GGOP SZCB, C000 GGOP MOV, D000 GGOP MOVB,
 
: 0OP     CREATE ,  DOES> @ T, ;
 
0340 0OP IDLE,   0360 0OP RSET,  03C0 0OP CKOF,
03A0 0OP CKON,   03E0 0OP LREX,  0380 0OP RTWP,
 
: ROP     CREATE , DOES> @ + T, ;
02C0 ROP STST,
02A0 ROP STWP,
 
: IOP     CREATE , DOES> @ T, T, ;
02E0 IOP LWPI,
0300 IOP LIMI,
 
: RIOP    CREATE , DOES> @ ROT + T, T, ;
0220 RIOP AI,
0240 RIOP ANDI,
0280 RIOP CI,
0200 RIOP LI,
0260 RIOP ORI,
 
: RCOP    CREATE , DOES> @ SWAP 10 * + + T, ;
0A00 RCOP SLA,
0800 RCOP SRA,
0B00 RCOP SRC,
0900 RCOP SRL,
 
CR .( jump instructions)
: DOP     CREATE , DOES> @ SWAP 00FF AND OR T, ;
 1000 DOP JMP,  1100 DOP JLT,  1200 DOP JLE,  1300 DOP JEQ,
 1400 DOP JHE,  1500 DOP JGT,  1600 DOP JNE,  1700 DOP JNC,
 1800 DOP JOC,  1900 DOP JNO,  1A00 DOP JL,   1B00 DOP JH,
 1C00 DOP JOP,
 
\ cru bit instructions
 1D00 DOP SBO,
 1E00 DOP SBZ,
 1F00 DOP TB,
 
CR .( Jump tokens)
HEX                  \ Action if TRUE
 01 CONSTANT GTE     \ JLT to ENDIF,
 02 CONSTANT HI      \ JLE to ENDIF,
 03 CONSTANT NE      \ JEQ to ENDIF,
 04 CONSTANT LO      \ JHE to ENDIF,
 05 CONSTANT LTE     \ JGT to ENDIF,
 06 CONSTANT EQ      \ JNE to ENDIF,
 07 CONSTANT OC      \ JNC to ENDIF,
 08 CONSTANT NC      \ JOC to ENDIF,
 09 CONSTANT OO      \ JNO to ENDIF,
 0A CONSTANT HE      \ JLO to ENDIF,
 0B CONSTANT LE      \ JH  to ENDIF,
 0C CONSTANT NP      \ JOP to ENDIF,
 
: GCOP    CREATE , DOES> @ SWAP 000F AND 40 * + GOP' ;
3000 GCOP LDCR,
3400 GCOP STCR,
 
 
CR .( Simplified branching and looping)
: AJUMP,  ( token --) >< 1000 + T, ;   \ >1000+token makes a jump instruction
: RESOLVE ( 'jmp offset --)  2- 2/ SWAP 1+ C! ; \ compile offset into 'jmp'
: <<BACK   ( addr addr' -- ) TUCK -  RESOLVE ;
 
: IF,     ( addr token -- 'jmp') HERE SWAP AJUMP, ;
: THEN,   ( 'jmp addr --)  HERE OVER -  RESOLVE ;
: ELSE,   ( -- addr ) HERE 0 JMP, SWAP THEN, ;
 
: BEGIN,  ( -- addr) HERE ;
: WHILE,  ( token -- *while *begin) IF, SWAP ;
: AGAIN,  ( *begin --)  HERE  0 JMP, <<BACK ;
: UNTIL,  ( *begin token --) HERE SWAP AJUMP, <<BACK ;
: REPEAT, ( *while *begin -- ) AGAIN, THEN, ;
 
CR .( Pseudo instructions)
: RT,     ( -- )  R11 ** B, ;
: NOP,    ( -- )  0 JMP, ;
 
\ PUSH & POP for both stacks
: PUSH,   ( src -- )  SP DECT,  *SP  MOV, ;  \ 10+18 = 28  cycles
: POP,    ( dst -- ) *SP+       SWAP MOV, ;  \ 22 cycles
 
: RPUSH,  ( src -- ) RP DECT,  *RP   MOV, ;
: RPOP,   ( dst -- ) *RP+      SWAP  MOV, ;
 
WARNINGS ON
 
CR CR .( Assembler loaded)
CR HERE SWAP - DECIMAL .  .( BYTES used)
HEX
 
