\ BYTEOPS.FTH demo code 

\ The 9900 is little endian so bytes are on the right side.
\ C! is just a MOVB ( move byte) instruction.
\ Study the output on the data stack after the program runs
\ to correlate the instructions to the results

HOST 
HEX 
\ create some variables 
CREATE X  AABB ,  
CREATE Y  0099 ,

ASMFORTH 
CODE TEST-C! ( -- n n n)
\ ASMFORTH              Output in Forth Assembler 
    DUP              \  SP DECT,  TOS *SP MOV,
    TOS OFF          \  TOS CLR, 

    X @@ TOS MOVB,   \ Forth Assembler code is still legal

    DUP           
    TOS OFF 
    X @  TOS C!      \  X @@ TOS MOVB,  (right side only)
    X ><             \  X @@ SWPB,  swap bytes in memory
    X @ PUSH         \  DUP  X @@ TOS MOV, 

    Y @ PUSH         \  DUP  X @@ TOS MOV, 
  
    X @  Y @ C!      \  X @@  Y @@ MOVB, right side only 
    Y @ PUSH         \  DUP   Y @@ TOS MOV, 
;CODE      

TEST-C!
CR .( Results from the program are on the stack )
CR .S 


    