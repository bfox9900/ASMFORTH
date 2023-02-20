# ASMFORTH II Overview

## Background
ASMFORTH II is the result of experiments in creating a "machine Forth" for the TI-99. Machine Forth is an idea create by Charles Moore, the inventor of Forth, during the time that he was developing his own two-stack CPUs.

Machine Forth drives the simplicity of code generation to an extreme. The primitive operations of the Forth language like fetch, store or plus directly compile information into memory to make the program. There is little protection from error. It is analogous to an Assembly language except it can write native code into memory from the interpreter command line, one statement at a time. 

Machine Forth for a CPU designed with an instruction set that is one-to-one matched with the Forth language is relatively simple. ASMFORTH is an attempt to get that same language to architecture match, but for a machine that is not a stack machine. 

Early experiments with a machine Forth for 9900 kept the Forth environment and all computational operations require the use the data stack. The RPN Forth Assembler was also available but they existed as two separate languages.

In ASMFORTH II we keep the Forth two stack architecture but add to it the ability to use the 9900 register system directly. In fact:

          *ALL Registers must be explicitly reference in ASMFORTH*

This is radical difference to conventional Forth Assemblers. 
The language then becomes something more akin to using Forth with local variables where the local variables are actually machine registers.  Since we need to reserve some registers for the Forth architecure and the 9900 CPU has R11 and R12 reserved for special purposes we are left with ten free registers. One of those ten is the top of data stack cache register provides extra space "underneath" it in the data stack. 

### Forth/9900 Memory Instruction Mapping

Name    ASMForth       9900 
-----   --------       -----
Store    !              MOV 
CStore  C!              MOVB 

Fetch    @              signals indirect addressing on register argument
Fetch++  @+             indirect addressing with auto-increment 


#### Examples
    RO @ R5 !    \ get contents of address in R0 and store in R5 
    
    R0 @+ R8 !   \ get contents of address in R0 and store in R8
                 \ increment R0 by 2 due to use of !  

* When @+ is used with C! the increment is 1 

    R1 @+ R2 C!  \ get contents of address in R0 and store in R8
                 \ increment R0 by 1 due to use of C!


   

#### Many 9900 instructions are one-to-one with ANS Forth

ABS     ABS             ABS 
Invert  INVERT          INV 
Plus    +               A 
XOR     XOR             XOR 

