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
the top level of the design is named **RV32IMF**, it specifies that the CPU is 32-bit riscv soft core that provides base instructions, floating point instructions, and integer multiply devide instructions.  
