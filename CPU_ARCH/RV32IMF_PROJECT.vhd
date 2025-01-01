-- this file is used for synthesis,and is providing PC,SEVEN SEGMENT DISPLAY
-- the synthesis file directories are used to initialize the memories
-- more outputs are provided to prevent the synthesizer from omitting logic :)
library ieee;
use ieee.std_logic_1164.all;

entity RV32IMF_PROJECT is
generic(
data_width:integer:=32;
address_width:integer:=5;
instruction_memory_address_width:integer:=6;
data_memory_address_width:integer:=6;

instruction_simulation_file_directory:string:= 
"C:\Users\DELL\Desktop\fpga\RISC-V-CORE-WITH-VHDL-main\RISC-V-CORE-WITH-VHDL-main\assembler\output_file.txt";

data_simulation_file_directory:string:= 
"C:\Users\DELL\Desktop\fpga\RISC-V-CORE-WITH-VHDL-main\RISC-V-CORE-WITH-VHDL-main\assembler\data_init.txt";

data_synthesis_file_directory0:string:=
"C:\Users\DELL\Desktop\playTest\RISC-V-CORE-WITH-VHDL-main\assembler\MIF0.mif";
data_synthesis_file_directory1:string:=
"C:\Users\DELL\Desktop\playTest\RISC-V-CORE-WITH-VHDL-main\assembler\MIF1.mif";
data_synthesis_file_directory2:string:=
"C:\Users\DELL\Desktop\playTest\RISC-V-CORE-WITH-VHDL-main\assembler\MIF2.mif";
data_synthesis_file_directory3:string:=
"C:\Users\DELL\Desktop\playTest\RISC-V-CORE-WITH-VHDL-main\assembler\MIF3.mif";

instruction_synthesis_file_directory0:string:=
"C:\Users\DELL\Desktop\playTest\RISC-V-CORE-WITH-VHDL-main\assembler\MIF0.mif";
instruction_synthesis_file_directory1:string:=                          
"C:\Users\DELL\Desktop\playTest\RISC-V-CORE-WITH-VHDL-main\assembler\MIF1.mif";
instruction_synthesis_file_directory2:string:=                          
"C:\Users\DELL\Desktop\playTest\RISC-V-CORE-WITH-VHDL-main\assembler\MIF2.mif";
instruction_synthesis_file_directory3:string:=                          
"C:\Users\DELL\Desktop\playTest\RISC-V-CORE-WITH-VHDL-main\assembler\MIF3.mif"

);
port (
--"rd" must be '1' and "wd" must be '0'
	clk,rst,int:in std_logic;
	IN_DATA:in std_logic_vector(31 downto 0);
	OUT_DATA:out std_logic_vector(31 downto 0);
	sev_seg1,sev_seg2,sev_seg3,sev_seg4,sev_seg5,sev_seg6,sev_seg7,sev_seg8:out std_logic_vector(6 downto 0)--MSB iS a
);end RV32IMF_PROJECT;
architecture arch of RV32IMF_PROJECT is 

component RV32IMF is 
generic(
data_width:integer:=32;
address_width:integer:=6;
instruction_memory_address_width:integer:=6;
data_memory_address_width:integer:=6;
mantissa_width:integer:=23;
exponent_width:integer:=8;
opcode_length:integer:=7
);
port(
--could use "go" signal that is used to rst control unit and to rst whole pipeline :)
	clk,rst,int:in std_logic;
	I_DATA,current_instruction,data_toread:in std_logic_vector(data_width-1 downto 0);
	RD,WD:out std_logic;
	O_DATA,instruction_pointer,data_pointer,data_towrite:out std_logic_vector(data_width-1 downto 0)
	
);
end component;

component RAM_simulation is 
generic(data_width:integer :=32 ;
		address_width:integer:=5;
		simulation_file_directory: string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.txt"
);
port(
		clk,RD,wd:in std_logic;
		address:in std_logic_vector(address_width-1 downto 0);
		D:in std_logic_vector(data_width-1 downto 0);
		Q:out std_logic_vector(data_width-1 downto 0)
);
end component;


component byteAddressable_32bitRam is 
generic(
		address_width: integer:=6;
		mif0:string:="C:\Users\DELL\Desktop\fpga\RISC-V-CORE-WITH-VHDL-main\RISC-V-CORE-WITH-VHDL-main\assembler\d_mif0.mif";
		mif1:string:="C:\Users\DELL\Desktop\fpga\RISC-V-CORE-WITH-VHDL-main\RISC-V-CORE-WITH-VHDL-main\assembler\d_mif0.mif";
		mif2:string:="C:\Users\DELL\Desktop\fpga\RISC-V-CORE-WITH-VHDL-main\RISC-V-CORE-WITH-VHDL-main\assembler\d_mif0.mif";
		mif3:string:="C:\Users\DELL\Desktop\fpga\RISC-V-CORE-WITH-VHDL-main\RISC-V-CORE-WITH-VHDL-main\assembler\d_mif0.mif"
);
port(
	clk,rd,wd,cs:in std_logic;
	address:in std_logic_vector(address_width -1 downto 0);
	D:in std_logic_vector(31 downto 0);
	Q:out std_logic_vector(31 downto 0)
);end component;

component sevseg is 
port(
	input: in std_logic_vector(3 downto 0);
	output: out std_logic_vector(6 downto 0)
);
end component;



signal CPU_output,current_instruction,data_toread,data_towrite,data_pointer,instruction_pointer:std_logic_vector(31 downto 0);
signal RD,WD:std_logic;
begin

Instruction_mem:byteAddressable_32bitRam generic map (instruction_memory_address_width,instruction_synthesis_file_directory0,
instruction_synthesis_file_directory1,instruction_synthesis_file_directory2,instruction_synthesis_file_directory3)
port map(clk,not rst,'0','0',instruction_pointer(instruction_memory_address_width-1 downto 0),(others=>'0'),current_instruction);
--here memory is alwais enabled
DATA_mem:byteAddressable_32bitRam generic map (data_memory_address_width,data_synthesis_file_directory0,
data_synthesis_file_directory1,data_synthesis_file_directory2,data_synthesis_file_directory3)
port map(clk,RD,WD,'0',data_pointer(data_memory_address_width-1 downto 0),data_towrite,data_toread);
--SAME HERE CS IS ENABLED TO ENABLE MORE MEMORIES TO BE INTERFACED



--****************************************************************************************************************
--* TO DO: STUDY THE ARCHITECTURE TO INTERFACE A TRANSMITTER AND A RECIEVER (UART) IT SHOULD BE 2 STACKS FOR DATA*
--* THIS MAKES THE INTERFACING OF MEMORY REALLY SIMPLE WITH ENABLED MEMORY MODELS                                *
--****************************************************************************************************************



--Instruction_mem:RAM_simulation generic map(32,instruction_memory_address_width,instruction_simulation_file_directory)
--port map(clk,not rst,'0',instruction_pointer(instruction_memory_address_width-1 downto 0),(others=>'0'),current_instruction);

--DATA_mem:RAM_simulation generic map(32,data_memory_address_width,data_simulation_file_directory)
--port map(clk,RD,WD,data_pointer(data_memory_address_width-1 downto 0),data_towrite,data_toread);


THE_CORE:RV32IMF 
generic map(32,address_width,instruction_memory_address_width,data_memory_address_width,23,8,7)
port map(clk,rst,int,IN_DATA,current_instruction,data_toread,RD,WD,CPU_output,instruction_pointer,data_pointer,data_towrite);

--seven segment display set up, but outputs must be assigned
SEVSEG1:sevseg port map(CPU_output(3 downto 0),sev_seg1);
SEVSEG2:sevseg port map(CPU_output(7 downto 4),sev_seg2);
SEVSEG3:sevseg port map(CPU_output(11 downto 8),sev_seg3);
SEVSEG4:sevseg port map(CPU_output(15 downto 12),sev_seg4);
SEVSEG5:sevseg port map(CPU_output(19 downto 16),sev_seg5);
SEVSEG6:sevseg port map(CPU_output(23 downto 20),sev_seg6);
SEVSEG7:sevseg port map(CPU_output(27 downto 24),sev_seg7);
SEVSEG8:sevseg port map(CPU_output(31 downto 28),sev_seg8);

OUT_DATA<=CPU_output;

end arch;
