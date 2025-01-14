# PROJECT
In this project RISC-V ISA was implemented for a CPU in VHDL to be synthesized,***VHDL version 2008***
because it offers great flexibility for syntax that is very useful in such projects.  

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

In this implementation, i found a word addressable memory to be easier to work with, hence, i just ignore the 
2 LSB bits of the instruction memory to make it so it can work with word abressable memory without changing hardware.  
This works because it increments by 4 and 4 bytes are a word(32-bits) so address 4 points to location 4 on byte addressable 
memory, and at the same time it points to address 1 on word addressable.  
00100   -> 00001 
considering bytes ->considering words  (this means we just ignore 2 LSB bits)  

this doesn't mean that the internal architecture is altered, the internal architecture are made as if memory is 
byte addressable. It is the way that im using it is as word addressable, this makes work easier and more intuitive 
for me. :)  
The followed architecture is **HARVARD ARCHITECURE** where data and instructions are separated.
# FETCH STAGE
The module contains a RAM for instructions, a register that holds the program counter value and it outputs the instruction's op code, functionality fields, read/write addresses and 
immediate values. it always output PC+4 for next instruction.  
**NOTE THAT WE ADD 4 BECAUSE MEMORY IS LITTLE ENDIAN AND ALL INSTRUCTIONS ARE 32 BITS**  

# DECODE STAGE 
The module contains two 32x32 bit register files that are used for integer and floating point operations, the integer register file has the address *ZERO* as a hardwired zero that is 
very usefull, it also sign extends the encoded values in instructions that use immediate values.

# EXECUTE STAGE
The module handles all calculations and comparisons necessary for out instructions, it has three big modules that handle the majority of computations, namely arithmetic logic unit and 
multiply divide unit for integer operations and floating point unit for floating point operations, it calculates addresses depending on the different immediate fields generating by each 
format, finally it has comparators to generate flags used for conditional branch instructions that affect next instruction's address.

# MEMORY STAGE
The module contain the data ram that is used to store and load data and also set up the next incoming instruction depending on the flow of the program, **NORMALLY** the program counter 
gets the address of current instruction incremented by four, but due to some instructions the program counter may have different values such as an 12-bit offset, a totally different 
address or interrupt service routine address, for branches, control unit generates the desired flags and compares them to flags generated by the ALU, if they are equal the the branch 
address is taken, else we load the next instruction.  

# WRITE BACK STAGE 
This stage desides what data to write back to registers of the decode stage along with the address or it writes to the output register that may be used by the user.

# INTERRUPTS AND MY CUSTOM INSTRUCTIONS
Interrupts are not discussed widely in this ISA *(at least i didn't find information)* so i decided to design my own instructions for that.  

**INTERRUPT ENABLE INSTRUCTION:** it enables interrupt flag in control unit to accept interrupts, it is incoded as the JALR instruction but has different opcode. RD is used to store the 
address of the program counter of the interrupted instruction, RS1 and 12-bit immediate are used to generate the *INTERRUPT SERVICE ROUTINE* that is stored in MEMORY STAGE to be used 
uppon interrupting.  

If the internal interrupt flag is high and an interrupt is issued, it won't be acknowledged untill the instruction is executed and interrupt signal is still high, then the control unit 
enters the interrupt state where interrupt_acknoledged signal is high to enable the following :  
-PC recieves the interrupt service routine.  
-The interrupted instruction is stored in the register address specified in the interrupt enable instruction.  
-Internal interrupt flag is disabled.
After that the ISR is executed normally.  

**INTERRUPT DISABLE INSTRUCTION:** it disables interrupts so the signal will not affect the program flow.  

**INPUT DATA INSTRUCTION:** it is enoded as a load instruction but has different opcode and has source address1 as 0 because it reads user data into the ram.  

**OUTPUT DATA INSTRUCTION:** it is encoded as a store instruction but has different opcode and write address is 0 because it outputs data to the user.  
# RISC V ASSEMBLER 
The assembler is written in C++, the header file *"assembler_class"* provides the **assembler** class and the methods for converting 
assembly to machine code. The instruction can have no operands up to 3 operands.

*Labels* can be used to simplify branches and offset calculation, they have the following syntax:  
                .label   

**For Branches and jumps**: the program counter would be already incremented, so the calculation is different when the offset is negative or prositive  
for example:  
lui x1,2  
.loop  
addi x1,x0,-1  
out_data x1,0  
bneq x0,x1,loop  
nop  
In this case the program decrements and outputs untill 0, the branch offset is calculated considering that the program already points to nop, then we must include the branch instruction 
in the offset, so **OFFSET IS -3**.  
But for the next example: 
lui x1,2
.loop1
out_data x1,0
bneq x0,x1,loop2
addi x1,x0,-1  
out_data x1,0   
jal x0,loop1  
.loop2  
nop  
In this case the program still does the same but the offset is different because the branch is not included in the calculation,so **OFFSET IS 4**.  

*Origins* are used to specify the address of a special subroutine to load in a desired address, for exaple we want a subroutine on address 20 in decimal:  
#20  
--rest of subroutine--  

*Comments* are used to better understand programs, the syntax is as follows:       ;this is a comment :)  

the following table organizes all the instructions:
| INSTRUCTION | ASSEMBLY FORMAT | DESCRIPTION |
|:-----------:|:---------------:|:-----------:|
|INTERRUPT_DISABLE|INTERRUPT_DISABLE|NO INTERRUPTS ARE CONSIDERED|
|NO OPERANTION|NOP|ENCODED AS ADD x0,x0,x0|
|JUMP AND LINK|JAL rd,20_bit_offset|rd=pc+4 , pc=pc+4+20_bit_OFFSET|
|ADD UPPER IMMEDIATE TO pc|AUIPC rd,upper_20_bit_offset|rd=pc+upper_20_bit_offset|
|LOAD UPPER IMMEDIATE|LUI rd,upper_20_bit_immediate|rd=upper_20_bit_immediate|
|MOVE INT TO FLOAT|FMV.W.X rd,rs|MOVE rs int REGISTER ADDRESS TO rd fp REGISTER ADDRESS WITHOUT CONVERSION |
|MOVE FLOAT TO INT|FMV.X.W rd,rs|MOVE rs fp REGISTER ADDRESS TO rd int REGISTER ADDRESS WITHOUT CONVERSION |
|CONVERT FLOAT TO INT|FMV.W.S rd,rs|CONVERT rs fp REGISTER ADDRESS TO rd signed int REGISTER ADDRESS|
|CONVERT INT TO FLOAT|FMV.S.W rd,rs|CONVERT rs signed int REGISTER ADDRESS TO rd fp REGISTER ADDRESS|
|MOVE fp VALUE|FMV rd,rs|MOVE FLOAT VALUE FROM rs FLOAT REGISTER ADDRESS to rd FLOAT REGISTER ADDRESS|
|GET NEGATIVE OF fp register|FNEG rd,rs|NEGATIVE VALUE OF FLOAT rs AND PUT IN rd IF ALREADY NEGATIVE, IT DOESN'T AFFECT|
|GET ABSOLUTE VALUE OF fp register|FABS rd,rs|ABSOLUTE VALUE OF FLOAT rs AND PUT IN rd|
|INPUT DATA FROM USER|IN_DATA rs,12_bit_offset|PUT READ DATA FROM USER IN RAM ADDRESS POINTER BY INTEGER rs+12_bit_offset|
|OUTPUT DATA TO USER|OUT_DATA rs,12_bit_offset|READ FROM RAM ADDRESS POINTER BY INTEGER rs+12_bit_offset TO USER|
|ADD INTEGERS|ADD rd,rs1,rs2|ADD rs1 AND rs2 THEN PUT IN rd|
|SUB INTEGERS|SUB rd,rs1,rs2|SUB rs1 AND rs2 THEN PUT IN rd|
|LOGICAL OR INTEGERS|OR rd,rs1,rs2|LOGICAL OR rs1 AND rs2 THEN PUT IN rd|
|LOGICAL AND INTEGERS|AND rd,rs1,rs2|LOGICAL AND rs1 AND rs2 THEN PUT IN rd|
|LOGICAL XOR INTEGERS|XOR rd,rs1,rs2|LOGICAL XOR rs1 AND rs2 THEN PUT IN rd|
|SHIFT LEFT LOGICAL|SLL rd,rs1,rs2|shift rs1 BY lower 5 bits of rs2 THEN PUT IN rd|
|SHIFT RIGHT LOGICAL|SRL rd,rs1,rs2|shift rs1 BY lower 5 bits of rs2 THEN PUT IN rd|
|SHIFT RIGHT ARITHMETIC|SRA rd,rs1,rs2|shift rs1 BY lower 5 bits of rs2 THEN PUT IN rd|
|SET LESS THAN|SLT rd,rs1,rs2|rd=1 when rs1<rs2 else rd=0 |
|SET LESS THAN UNSIGNED|SLTU rd,rs1,rs2|rd=1 when rs1<rs2 else rd=0 |
|ADD INTEGERS|ADDI rd,rs1,12_bit_immediate|ADD rs1 AND 12_bit_immediate THEN PUT IN rd|
|LOGICAL OR INTEGERS|ORI rd,rs1,12_bit_immediate|LOGICAL OR rs1 AND 12_bit_immediate THEN PUT IN rd|
|LOGICAL AND INTEGERS|ANDI rd,rs1,12_bit_immediate|LOGICAL AND rs1 AND 12_bit_immediate THEN PUT IN rd|
|LOGICAL XOR INTEGERS|XORI rd,rs1,12_bit_immediate|LOGICAL XOR rs1 AND 12_bit_immediate THEN PUT IN rd|
|SHIFT LEFT LOGICAL|SLLI rd,rs1,5_bit_immediate|SHIFT rs1 BY 5_bit_immediate THEN PUT IN rd|
|SHIFT RIGHT LOGICAL|SRLI rd,rs1,5_bit_immediate|SHIFT rs1 BY 5_bit_immediate THEN PUT IN rd|
|SHIFT RIGHT ARITHMETIC|SRAI rd,rs1,5_bit_immediate|SHIFT rs1 BY 5_bit_immediate THEN PUT IN rd|
|SET LESS THAN|SLTI rd,rs1,5_bit_immediate|rd=1 when rs1<5_bit_immediate else rd=0 |
|SET LESS THAN UNSIGNED|SLTIU rd,rs1,5_bit_immediate|rd=1 when rs1<5_bit_immediate else rd=0 |
|MULTIPLY INTEGER|MUL rd,rs1,rs2|MULTIPLY INTEGER AND PUT lower 32 BITS IN rd|
|MULTIPLY INTEGER|MULH rd,rs1,rs2|MULTIPLY INTEGER AND PUT UPPER 32 BITS IN rd|
|MULTIPLY INTEGER|MULHSU rd,rs1,rs2|MULTIPLY INTEGER rs1 SIGNED AND rs2 UNSIGNED AND PUT UPPER 32 BITS IN rd|
|MULTIPLY INTEGER|MULHU rd,rs1,rs2|MULTIPLY INTEGER UNSIGNED AND PUT UPPER 32 BITS IN rd|
|DIVIDE INTEGER|DIV rd,rs1,rs2|DIVIDE INTEGER  AND PUT IN rd|
|DIVIDE INTEGER|DIVU rd,rs1,rs2|DIVIDE INTEGER UNSIGNED AND PUT IN rd|
|REMAINDER INTEGER|REM rd,rs1,rs2|REMAINDER INTEGER  AND PUT IN rd|
|REMAINDER INTEGER|REMU rd,rs1,rs2|REMAINDER INTEGER UNSIGNED AND PUT IN rd|
|ADD FLOATS|FADD rd,rs1,rs2|ADD FLOATS rs1 AND rs2 AND PUT IN rd|
|MULTIPLY FLOATS|FMUL rd,rs1,rs2|MUL FLOATS rs1 AND rs2 AND PUT IN rd|
|DIVIDE FLOATS|FDIV rd,rs1,rs2|DIV FLOATS rs1 AND rs2 AND PUT IN rd|
|MAX OF FLOATS|FMAX rd,rs1,rs2|MAX OF FLOATS rs1 AND rs2 AND PUT IN rd|
|MIN OF FLOATS|FMAX rd,rs1,rs2|MIN OF FLOATS rs1 AND rs2 AND PUT IN rd|
|LOAD FLOAT|FLW rd,rs1,12_bit_offset|LOAD FLOAT FROM ADDRESS rs1+12_bit_offSet AND PUT IN rd|
|STORE FLOAT|FSW rd,rs1,12_bit_offset|STORE FLOAT IN ADDRESS rs1+12_bit_offSet AND PUT IN rd|
|BRANCH IF EQUAL|BEQ rs1,rs2,12_bit_offset|BRANCH IF rs1=rs2|
|BRANCH IF NOT EQUAL|BNEQ rs1,rs2,12_bit_offset|BRANCH IF rs1!=rs2|
|BRANCH IF LESS THAN|BLT rs1,rs2,12_bit_offset|BRANCH IF rs1<rs2|
|BRANCH IF LESS THAN|BLTU rs1,rs2,12_bit_offset|BRANCH IF rs1<rs2 UNSIGNED|
|BRANCH IF GREATER OR EQUAL|BGE rs1,rs2,12_bit_offset|BRANCH IF rs1>=rs2|
|BRANCH IF GREATER OR EQUAL|BGEU rs1,rs2,12_bit_offset|BRANCH IF rs1>=rs2 UNSIGNED|
|JUMP AND LINK REGISTER|JALR rd,rs1,12_bit_offset|rd=pc+4;pc=rs1+12_bit_offset|
|LOAD WORD|LW rd,rs1,12_bit_offset|PUT CONTENT OF ADDRESS RS1+12_bit_offset IN rd|
|STORE WORD|SW rs1,rs2,12_bit_offset|PUT rs1 IN ADDRESS=rs2+12_bit_offset|
|ENABLE INTERRUPT|INTERRUPT_ENBALE rd,rs1,12_bit_offset|PUT INTERRUPTED ADDRESS IN rd AND ISR=rs1+12_bit_offset|  


**NOTES :** 
- All register references must have lower case 'x' before them example register 0 is x0.  
- All addresses and immediate values are referenced in decimal.
- assemble(input_file_path,output_file_path) is the main method, it takes the assembly program and converts it to machine code to write in output file.
- generate_byte_mif(output_file_path,mif_path,depth) generates byte addressable initialization of memory.

*output_file_path:* is the file that has the machine code of the program that we want to assemble.

**SOME UPDATES :**
After some time (2 monthes :o) i changed a lot of stuff.
-**FIRST:** Architecture was changed to have the instruction and data memories to be outside the cpu, this makes the 
architecture able to be interfaced with memories outside of the FPGA.  
-**SECOND:** Input/Output for CPU are different from instruction/data inputs and outputs, now cpu has data from user and data from 2 other memories.

**WEIRD BEHAVIOUR**
I noticed that when i set the CPU after compilation, the timing reports have different ranges for maximum frequency.  
Some times the operating frequency is 7 Mhz and it can shoot upto 165 Mhz this is confusing.  
Maybe in the next months i can explore more into it after synthesis and uploading the design, if the frequency still holds up then synthesiser is trying to optimize away some logic.
