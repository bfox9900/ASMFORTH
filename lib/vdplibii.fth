\ VDPLIB.FTH library  for ASMForth II           2023 Mar Brian Fox

HOST
HEX
8800 EQU VDPRD
8802 EQU VDPSTS
8C00 EQU VDPWD
8C02 EQU VDPWA

ASMFORTH  
\ VDPA! takes arg from TOS but leaves it on the stack 
: VDPA! ( Vaddr -- Vaddr) \ set vdp address (read mode)
    R1 STWP,
    0 LIMI,
    9 (R1)  VDPWA @@ C!  \ write odd byte from TOS (ie: R4)
    TOS     VDPWA @@ C!  \ MOV writes the even byte to the port address
;

: VC@   ( addr -- c)
    VDPA! 
    TOS OFF
    VDPRD @@  9 (R1) C!  \ read data into odd byte of R4
    DROP 
;

: VC! ( c Vaddr -- )
    TOS 4000 #OR VDPA! 
    9 (R1) VDPWD @@ C!    \ Odd byte R4, write to screen
    DROP                  \ refill TOS
;

HEX
\ * VDP write to register. Kept the TI name
: VWTR   ( c reg -- )   \ Usage: 5 7 VWTR
    TOS ><             \ swap bytes in TOS register
    NOS^ TOS +         \ combine 2 bytes to one cell
    TOS 8000 #OR VDPA!
    DROP 
;

: VFILL ( Vaddr cnt char -- )
    TOS R5 !       \ R5 = CHAR
    R5 ><
    R0 POP         \ cnt to R0
    TOS POP        \ Vaddr to TOS 
    TOS 4000 #OR  VDPA! 
    VDPWD R3 #! 
    R0 FOR
        R5 *R3 C!
    NEXT
    DROP 
;

: VREAD ( Vaddr addr n --)
    TOS R0 !
    R5 POP
    TOS POP  VDPA!  
    VDPRD R3 #! 
    R0 FOR
        *R3 *R5+ C!
    NEXT
    DROP 
;

: VWRITE ( addr Vaddr len -- )
    TOS R0 !
    TOS POP       \ Vaddr in TOS 
    TOS 4000 #OR VDPA! \ set write address 
    TOS POP       \  pop RAM addr into TOS 
    VDPWD R3 #! 
    R0 FOR 
        *TOS+ *R3 C!
    NEXT    
    DROP
;

\ test code 

HEX 
\ high level words 
: READSCR       0 # 2000 #  3C0 # VREAD ; 
: WRITESCR   2000 #    0 #  3C0 # VWRITE ;
: CLS           0 #  3C0 #   BL #  VFILL ;
: DELAY      TOS FOR NEXT DROP ;

CODE TEST-R/W
    READSCR 
    CLS  
    FFFF # DELAY 
    WRITESCR 
;CODE     