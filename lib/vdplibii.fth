\ VDPLIB.FTH library  for ASMForth II           2023 Mar Brian Fox

HOST
HEX
8800 EQU VDPRD
8802 EQU VDPSTS
8C00 EQU VDPWD
8C02 EQU VDPWA

ASMFORTH  
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
;

: VC! ( c Vaddr -- )
    TOS 4000 #OR VDPA! 
    9 (R1) VDPWD @@ C!    \ Odd byte R4, write to screen
    DROP                  \ refill TOS
;

HEX
\ * VDP write to register. Kept the TI name
: VWTR   ( c reg -- )   \ Usage: 5 7 VWTR
    TOS ><  +         \ combine 2 bytes to one cell
    TOS 8000 #OR  VDPA!
    DROP 
;

: VFILL ( Vaddr cnt char -- )
    TOS R5 !      \ R5 = CHAR
    R5 ><
    NOS^ R1 !      \ cnt to temp 
    NOS^ TOS C! 
    TOS 4000 #OR VDPA! 
    R1 TOS ! 
    FOR
        R5 VDPWD @@ C!
    NEXT
    DROP 
;

: VREAD ( Vaddr addr n --)
    TOS  R0 !
    NOS^ R5 !
    NOS^ TOS ! VDPA!  \ TOS is refilled after this call
    VDPRD R3 #! 
    R5 TOS C! 
    FOR
        R3 ** R5 *+ C!
    NEXT
;

: VWRITE ( addr Vaddr len -- )
        [ TOS R0 MOV,
         *SP+ TOS MOV,    \ TOS = Vaddr
          TOS 4000 ORI, ]
          VDPA!           \ TOS = addr (sub-routine does a DROP)
        [ BEGIN
           *TOS+ VDPWD @@ MOVB,
            R0 DEC,
         -UNTIL
         DROP ]
;
