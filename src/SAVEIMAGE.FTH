\ SAVEIMAGE.FTH saves ASMForth program in EA5 format   B Fox Aug 2023
 
ONLY FORTH DEFINITIONS 
NEEDS LOAD-FILE FROM DSK1.LOADSAVE  \ we use SAVE-FILE from this library
 
ONLY FORTH ALSO ASSEMBLER ALSO COMPILERS ALSO FORTH DEFINITIONS 

HEX
\ 2000 CONSTANT 'ORG   \ start of program
1000 CONSTANT VDPBUFF  \ Programs write to file from VDP Ram
2000 CONSTANT 8K
\ 13 CONSTANT PROG     \ file mode for Program files
 
\ define the file header fields *THESE ARE VDP ADDRESSES*
VDPBUFF  CONSTANT MULTIFLAG
VDPBUFF  1 CELLS + CONSTANT PROGSIZE
VDPBUFF  2 CELLS + CONSTANT LOADADDR
VDPBUFF  3 CELLS + CONSTANT CODEORG     \ COPY 8K program chunks to here
 
\ words to compute Forth system properties
: SYS-SIZE    ( -- n) CDATA THERE SWAP - ;
 
: #FILES      ( -- n)  SYS-SIZE 8K /MOD SWAP IF  1+ THEN ;
 
: CODECHUNK   ( n -- addr)
              DUP 8K * ( -- n addr)
              SWAP IF          \ if n <> 0 ie: 2nd, 3rd, chunks
                  3 CELLS  -   \ subtract header space
              THEN CDATA REL>TARG + ;
 
: CHUNKSIZE   ( n -- n )
              THERE REL>TARG SWAP CODECHUNK -   \ compute size
              3 CELLS +                \ add 6 bytes for header
              8K MIN  ;                \ take lesser of size or 8K
 
: LASTCHAR++  ( Caddr --) COUNT 1- +  1 SWAP C+! ;
 
: ?PATH    ( addr len -- addr len )
            2DUP  [CHAR] . SCAN NIP 0= ABORT" Path expected" ;
 
( Note: 13 is ti-99 file mode for a program file)
: SAVE-PROG  ( path$ len Vaddr size -- ) 13 SAVE-FILE ;
 
COMPILER
: SAVE  ( -- <textpath> )
        BL PARSE-WORD  ?PATH  PAD PLACE
        #FILES 0
        DO
           CR ." Writing file " I . ." of " #FILES .
           CR ." Init file header " I  . ." : "
           I 1+ #FILES <> DUP U.  MULTIFLAG V!
           I CHUNKSIZE    DUP U.  PROGSIZE V!
           I CODECHUNK    DUP U.  LOADADDR V!
 
           CR ." Copy to VDP & write to disk"
           CODEORG  8K 0 VFILL
           LOADADDR V@  CODEORG  PROGSIZE V@  VWRITE
           PAD COUNT  VDPBUFF PROGSIZE V@ SAVE-PROG
 
           PAD LASTCHAR++   \ Update file name
           CR
        LOOP
        CR ." System size=" DECIMAL SYS-SIZE U. ." bytes"
        CR ." Saved in " #FILES .  ." EA5 files"
        CR
;
 
