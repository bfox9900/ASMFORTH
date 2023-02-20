# ASMFORTH II Overview

## Background
ASMFORTH II is the result of experiments in creating a "machine Forth" for the TI-99. Machine Forth is an idea create by Charles Moore, the inventor of Forth, during the time that he was developing his own two-stack CPUs.

Machine Forth drives the simplicity of code generation to an extreme. The primitive operations of the Forth language like fetch, store or plus directly compile information into memory to make the program. There is little protection from error. It is analogous to an Assembly language except it can write native code into memory from the interpreter command line, one statement at a time. 

Machine Forth for a CPU designed with an instruction set that is one-to-one matched with the Forth language is relatively simple. ASMFORTH is an attempt to get that same language to architecture match, but for a machine that is not a stack machine. 

#### Why ASMFORTH
There is no way to extract the full performance out of the CPU without using the native architecture. ASMFORTH is just an Assembler that uses Forth naming conventions rather than the mnemonics provided by Texas Instruments. The goal is to reduce the distraction of moving from Forth to Assembler by keeping the nomeclature similar. Traditional Forth assemblers go half the way by using structured branching and looping so I just move farther in that direction. 

Early experiments with a machine Forth for 9900 kept the Forth environment and all computational operations required the use of the data stack. The RPN Forth Assembler was also available but they existed as two separate languages.

In ASMFORTH II we keep the Forth two stack architecture but add to it the ability to use the 9900 register system directly. 
In fact:

#### *ALL Registers must be explicitly reference in ASMFORTH*

This is a radical difference to conventional Forth Assemblers. 
The language then becomes something more akin to using Forth with local variables where the local variables are actually machine registers.  Since we need to reserve some registers for the Forth architecure and the 9900 CPU has R11 and R12 reserved for special purposes we are left with ten free registers. One of those ten is the top of data stack cache register which provides extra space "underneath" it in the data stack. 

## Examples

### Forth/9900 Memory Instruction Mapping

    Name    ASMForth       9900 
    -----   --------       -----
    Store    !              MOV 
    CStore  C!              MOVB 

    Fetch    @              signals indirect addressing on register argument
    Fetch++  @+             indirect addressing with auto-increment 


#### Register to Register 
    RO @ R5 !    \ get contents of address in R0 and store in R5 

#### Address in Register to Register     
    R0 @+ R8 !   \ get contents of address in R0 and store in R8
                 \ increment R0 by 2 due to use of !  

#### When @+ is used with C! the increment is 1 

    R1 @+ R2 C!  \ get contents of address in R0 and store in R8
                 \ increment R0 by 1 due to use of C!

#### Memory to Memory 
The 9900 is a memory to memory architecture and so ignoring that ability just uses more instruction needlessly. The double-fetch @@ lets us use this feature.

```
    VARIABLE X  VARIABLE Y

    X @@ R1 !       \ fetch from X store in R1  ie: MOV @X,R1 
    Y @@ X @@ !     \ move contents of Y into X 
```


#### Many 9900 instructions are one-to-one with ANS Forth

    Name   Forth        9900
    ----   -----        ----
    ABS     ABS         ABS 
    Invert  INVERT      INV 
    Plus    +           A 
    XOR     XOR         XOR 

The difference from Forth is that in ASMForth II we must provide the Register names.

    HEX
    01 R0 LD   \ load R0 with 1 
    R5 R0 XOR  

If we choose to use the DATA stack it would look like this:
( NOS is just an alias for the stack pointer register SP)

    01 # 65 #       \ two numbers on data stack. 65 is in TOS register 
    NOS @+ TOS XOR  \ XOR "next on stack" with TOS. 
                    \ @+ increments SP after XOR completes
                    \ result is in TOS register for future use 
                    \ Stack item in NOS is removed. 

#### Loops and Branches 

Conventional Forth words IF, THEN, BEGIN, UNTIL etc. are used in ASMFORTH with an important difference. The CPU status register is used by default on conditional branches like IF WHILE or UNTIL.  This means that if you decrement a register with 1-, perform another operation, the status register will contain bits that signal the result of the operation. Word like IF respond to the status bits with the following comparison tokens: 
-  =      equal 
-  <>     not equal 
-  <      signed
-  >      singed 
-  U>     unsigned  
-  U>=    unsigned 
-  U<     unsigned 
-  U<=    unsigned 

NOTE: Operators like '='  '<>' etc, are CPU specific here and test the EQ flag in the status register. To explicitly compare two registers we must use the compare instructions. (See further below)   

####  Example loop using CPU status register
```
    HEX
    CODE DOUNTIL 
      FFFF #   \ DUP R4 and put a number into R4
      BEGIN
        TOS 1-
      = UNTIL  \ loop until TOS gets to zero 
      DROP
    ;CODE

```

#### Register Comparisons

Two instructions allow us to for a comparison between registers, and/or memory locations.  CMP for 16 bits and CMPB for bytes.

We can also compare a register or memory location to a literal value with 
[CMP].  

* It is an ASMForth convention that word in square brackets accepts a literal argument ( see: [+] [OR] [AND] )

```    
    HEX
    CODE REGLOOP 
        88 R0 LD        \ load R0 with a limit value 
        FFFF #          \ push FFFF onto data stack 
        BEGIN
            TOS 1-      \ dec TOS 
            TOS R0 CMP  \ compare to limit 
        = UNTIL 
        DROP 
    ;CODE 

    HEX
    CODE LITLOOP  
        FFFF #           \ push FFFF onto data stack 
        BEGIN
            TOS 1-       \ dec TOS 
            TOS 88 [CMP] \ compare to LITERAL limit 
        = UNTIL 
        DROP 
    ;CODE 
```



