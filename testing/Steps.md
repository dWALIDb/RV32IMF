# General Steps:
This folder contains an example on how to run programs on the designed risc V processor.  
- Start by writing our assembly program in a text file.
- Compile the C++ assembler that we wrote to generate the machine code to initialize the memory by providing the assembly text file and the output machine code **file paths**.
- Generate the .mif file for synthesis.
- Change the instruction/data memory paths in the top level of the VHDL design, depending the desired operation(simulation/synthesis).
- Compile and the run the simulation/synthesis.

 # Applying the steps:
 The program:
  ![program](RISC-V-CORE-WITH-VHDL/testing/assembly_proram.png)
