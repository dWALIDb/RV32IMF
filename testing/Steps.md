# General Steps:
This folder contains an example on how to run programs on the designed risc V processor.  
- Start by writing our assembly program in a text file.
- Compile the C++ assembler that we wrote to generate the machine code to initialize the memory by providing the assembly text file and the output machine code **file paths**.
- Generate the .mif file for synthesis.
- Change the instruction/data memory paths in the top level of the VHDL design, depending the desired operation(simulation/synthesis).
- Compile and the run the simulation/synthesis.

 # Applying the steps:
 We want to write an assembly program that takes values from the data memory and counts square root of a number using the 
 newton_raphson method,the first parameter is the number in floating point representation, second is the constant 0.5 in floating point 
 representation, and last the number of iterations that must be taken.  
 
 The program:  
The input number is 69 and the number of iterations is 7.
 
 ![program](/testing/assembly_program.png)  

 The C++ code to generate the machine code:  
 
 ![program](/testing/assembler.PNG)  

  The machine code:  
 
 ![program](/testing/machine_code.PNG)  
 
  Changing file path for simulation:  
 
 ![program](/testing/changing_file_path.PNG)  
  
  Simulation output:  
 
 ![program](/testing/simulation_output.PNG)  

after 7 itterations, the output is **01000001000001001110011111101110** which is **8.306623** in binary.
