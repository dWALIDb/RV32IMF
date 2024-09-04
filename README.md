# RISC V
RISC V is an open Instruction Set Architecture used for the developement of custom processors.  
It is the **fifth** generation of developement hence, the V (in risv-V).  
The architecture is well documented by the RISC V organization, where the ISA is discussed.  
It has a base instruction set named RV32I containing all instructions necessary for a fully fledged 32-bit cental processing unit. It still
offers other extensions for more implementations depending on the manufacturers.  
  
In this implementation, 2 extensions are considered:  
**First**,the floating point extension (F) that provides a floating point register file, and instructions that handel floating point operands.  
**Second**,the integer multiply divide (M) that provides integer multiplication and division instructions.  

The naming convension specified in the *RISV V SPEC 2.2* specifies that using extensions requires using the letters corresponding to each extension with a specific ordering, hence, 
the top level of the design is named **RV32IMF**, it specifies that the CPU is 32-bit riscv soft core that provides base instructions, floating point instructions, and integer multiply 
devide instructions.  

# INTERNAL ARCHITECTURE  
The design is split into *five* stages to boost performance, and after implementation it turned out to be not as complicated as it seems.  
the stages are fetch,decode,execute,memory and write back.  

# FETCH STAGE
The module contains a RAM for instructions, a register that holds the program counter value and it outputs the instruction's op code, functionality fields, read/write addresses and 
immediate values. it always output PC+4 for next instruction.  
**NOTE THAT WE ADD 4 BECAUSE MEMORY IS LITTLE ENDIAN AND ALL INSTRUCTIONS ARE 32 BITS**  

# DECODE STAGE 
The module contains two 32x32 bit register files that are used for integer and floating point operations, the integer register file has the address *ZERO* as a hardwired zero that is 
very usefull, it also sign extends the encoded values in instructions that use immediate values.
