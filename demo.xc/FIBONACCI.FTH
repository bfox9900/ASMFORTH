\ FIBONACCI.FTH  test for ASMForth XC recursion     Aug 2023 

HOST 
: FIB ( x -- y )   \ RECURSIVE
	DUP 2 > 
    IF  DUP  1- RECURSE 
	    SWAP 2- RECURSE +  EXIT 
	THEN 
	DROP 1 ; \ 20 FIB  5.3 seconds 

\ slightly faster 
DECIMAL
: FIB1 ( N1 -- N2 )
    DUP 3 < IF DROP 1 EXIT THEN
    DUP  1- RECURSE
    SWAP 2- RECURSE  + ; \ 20 FIB1  5.26 seconds 

\ not recursive
: FIB2
  0 1 ROT 
  FOR
    BOUNDS \ OVER + SWAP 
  NEXT
  DROP ; \ itc 20 FIB .030 seconds !! 
