# ASMFORTH
 
 This is an experimental Machine Forth for the TI-99. It uses Forth-like syntax but is really an Assembler. Many of the words are just aliases of the Forth assembler in Camel99 Forth. Although the syntax looks like Forth the significant difference is that registers are reference explicity for maximum performance.  The data stack and return stack are still available to the programmer however.

 Self-calling nestable sub-routines can be created with the SUB: ;SUB pair. 

This Assembler was created when comparing the performance on the Byte Magazine
Sieve of Erasthones benchmark using conventional Forth and an 9900 Assembly language version.  Camel99 Forth performed ten iterations in 120 seconds.
Using a "just-in-time" compiler and a number of other optimizations the fastest speed I could achieve with Forth was 38 seconds. 

An Assembly language version of program did the same job in 10 seconds. 

So the stack VM paradigm just adds too many instructions to really fly on the old 9900.  When each instruction can use 14 to 28 clock cycles, every extra instruction is a killer. 

See the demo folder for an example of the sieve benchmark in Camel99 Forth and in ASMForth. 

