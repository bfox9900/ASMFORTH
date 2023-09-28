\ Tursi's famous Sprite benchmark in ASMForth II Sept 27 2023 Fox

HOST
HEX
8800 CONSTANT VDPRD
8802 CONSTANT VDPSTS
8C00 CONSTANT VDPWD
8C02 CONSTANT VDPWA

HEX
300 CONSTANT SP.Y
301 CONSTANT SP.X
302 CONSTANT SP.CHAR 
303 CONSTANT SP.COLOR 

300 CONSTANT SAT   \ sprite attribute table 
380 CONSTANT CTAB 


ASMFORTH 

\ VDPA! takes arg from TOS but leaves it on the stack 
: VDPA! ( Vaddr -- Vaddr) \ set vdp address (read mode)
    R1 STWP,
    0 LIMI,
    9 (R1)  VDPWA C!  \ write odd byte from TOS (ie: R4)
    TOS     VDPWA C!  \ MOV writes the even byte to the port address
;

: VC! ( c Vaddr -- )
    TOS 4000 #OR VDPA! 
    9 (R1) VDPWD C!    \ Odd byte R4, write to screen
    DROP               \ refill TOS
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
    TOS ><         \ swap char bytes 
    TOS R5 !       \ R5 = CHAR
    R0  POP        \ cnt to R0
    TOS POP        \ Vaddr to TOS 
    TOS 4000 #OR VDPA! 
    VDPWD R3 #! 
    R0 FOR
        R5 R3 ** C!
    NEXT
    DROP 
;

: PAGE   0 # 300 # 20 # VFILL ;

: GRAPHICS
      0 # 380 # 0 # VFILL   \ clear screen and sprite table
      0E0 # DUP 83D4 # C!
             1 # VWTR
        0 #  2 # VWTR      \ set VDP screen page
        0E # 3 # VWTR
        01 # 4 # VWTR
        06 # 5 # VWTR
        01 # 6 # VWTR
      CTAB # 17 # 10 # VFILL  \ charset colors
        17 # 7 # VWTR      \ BLACK on CYAN
      PAGE ;

: SPRITE0  ( char colr x y -- ) \ create a SPRITE, sp# = 0..31
      SP.Y #  VC!      \ set screen y position
      SP.X #  VC!      \ set screen x
      SP.COLOR #  VC!      \ set the sprite color
      SP.CHAR #  VC!       \ set the character pattern to use
;

CODE TEST    
     GRAPHICS       
     42 # 6 #  0 # 0 # SPRITE0  
;CODE 
 
DECIMAL
CODE TURSI    \ ~15 seconds
     GRAPHICS 
\    char clr    x    y  
      42 # 6 #   0 #  0 #   SPRITE0

      100 #FOR
       0 #   239 #FOR  DUP SP.Y # VC! 1+  NEXT DROP
       0 #   175 #FOR  DUP SP.X # VC! 1+  NEXT DROP
             239 #FOR  R@  SP.Y # VC!  NEXT
             175 #FOR  R@  SP.X # VC!  NEXT
      NEXT
     DROP
;CODE

