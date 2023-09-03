\ Tursi's famous Sprite benchmark in ASMForth II  Sept 3 2023   Fox

ASMFORTH 
NEEDS VWRITE FROM DSK7.VDPLIBII 

HEX
300 CONSTANT $300
300 CONSTANT SAT   \ sprite attribute table 
301 CONSTANT $301
380 CONSTANT CTAB 

: PAGE   0 # 300 # 20 #  VFILL ;

: GRAPHICS
      0 # 380 # 0 # VFILL   \ clear screen and sprite table
      0E0 # DUP 83D4 C!
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
      300 #  VC!      \ set screen y position
      301 #  VC!      \ set screen x
      303 #  VC!    \ set the sprite color
      302 #  VC!      \ set the character pattern to use
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
       0 #   239 #FOR  DUP $301 # VC! 1+  NEXT DROP
       0 #   175 #FOR  DUP $300 # VC! 1+  NEXT DROP
             239 #FOR  R@  $301 # VC!  NEXT
             175 #FOR  R@  $300 # VC!  NEXT
      NEXT
     DROP
;CODE

