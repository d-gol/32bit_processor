# 32-bit Processor #

## What is it about? ##

The project is the implementation of a 32-bit general purpose processor. The processor is connected with data memory and instruction memory. 

Processor characteristics:
* Interface for the environment contains connections to data memory and instruction memory, RESET signal and CLOCK signal.
* Addressing unit is a word. The word is 4 bytes long.
* RISC architecture.
* Contains register file.
* Load/Store architecture.
* Constant instruction word, 32 bits.
* Pipeline with 5 layers.
* Resolving hazards in hardware by forwarding, using branch predictor or stopping the pipeline.
* Stopping pipeline only when forwarding is not possible and data hazards exist.
* 32 general purpose registers. PC (Program Counter) and SP (Stack Pointer) registers.
* 5 phases of instruction processing: Instruction Fetch, Instruction Decode, Instruction Execution, Memory Access, Write Back.
* 2-bit cache branch predictor for predicting the result of a branch instruction.

## How is it implemented? ##

The project is implemented in VHDL. Every phase of instruction processing is implemented as a separate module. The module containing all 5 phases is the module representing the CPU. Additional modules for register file, predictor, data and instruction memory, hardware stack, hazard unit. 

Modules:
* InstrFetch
* InstrDecode
* InstrExec
* InstrMem
* InstrWB
* RegisterFile
* Predictor
* DataMemory
* IntsructionMemory
* Stack
* HazardUnit
* CPU

Testing is done by executing programs for this specific processor.
That included testing every instruction separetely, and as a part of a program.
Every unit is tested for separately as well.
After these checks, complex recursion programs were written and tested.
