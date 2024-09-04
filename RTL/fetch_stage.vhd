--fetch stage 
--the next_PC input is determined in memory stage to know what address to use, the offset or the next instruction 
-- the generic simulation is a boolean is used to determine what ram to use for the data operands 
--for S format take the immediate value and replace lower bit with write arrdess :) no need to 
-- give it special outputs and inputs and registers

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tools.all;

entity fetch_stage is 
generic(
	data_width:integer:=32;
	memory_address_width:integer:=6;
	address_width:integer:=5;
	--simulation file must be .txt file 
	simulation_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.txt";
	--synthesis file must be .mif file 
	synthesis_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.mif";
	simulation:boolean:=true
);
port(
	clk,rst,enable_pc:in std_logic;
	next_pc:in std_logic_vector(data_width-1 downto 0);
	immediate_value:out std_logic_vector(11 downto 0);
	upper_immediate_value:out std_logic_vector(19 downto 0);
	read_address1,read_address2,write_address:out std_logic_vector(address_width-1 downto 0);
	func3:out std_logic_vector(2 downto 0);
	func7:out std_logic_vector(6 downto 0);
	pc_outplus4:out std_logic_vector(data_width-1 downto 0);
	opcode:out std_logic_vector(6 downto 0)
);
end fetch_stage;

architecture arch of fetch_stage is  

component generic_reg is 
generic(data_width:integer :=8);
port (
	clk,rst,ld:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component; 

component RAM_synthesis is 
generic(data_width:integer :=32 ;
		address_width:integer:=5;
		synthesis_file_directory: string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.mif"
);
port(
		clk,RD,wd:in std_logic;
		address:in std_logic_vector(address_width-1 downto 0);
		D:in std_logic_vector(data_width-1 downto 0);
		Q:out std_logic_vector(data_width-1 downto 0)
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

constant ZERO:std_logic_vector(data_width-1 downto 0):=(others=>'0');
signal PC_out,new_PC,ram_out,chosen_pc:std_logic_vector(data_width-1 downto 0);
begin
--instantiation of ram module depending on the usage
GENERATE_SIM_RAM:if(simulation=true) generate
SIMULATION_INSTRUCTION_MEMORY:RAM_simulation generic map (data_width,memory_address_width,simulation_file_directory)
port map(clk,'1','0',PC_out(memory_address_width-1 downto 0),(others=>'0'),ram_out);
end generate GENERATE_SIM_RAM;

GENERATE_SYNTH_RAM: if(simulation=false) generate
SYNTHESIS_INSTRUCTION_RAM:RAM_synthesis generic map (data_width,memory_address_width,synthesis_file_directory)
port map(clk,'1','0',PC_out(memory_address_width-1 downto 0),(others=>'0'),ram_out);
end generate GENERATE_SYNTH_RAM;

--calculation of next PC  we add 4 because all instructions are 4 bytes and little endian
pc_outplus4<=std_logic_vector(unsigned(PC_out)+4);

--control unit inputs 
opcode<=ram_out(opcode_length-1 downto 0);

func7<=ram_out(data_width-1 downto data_width-7);

func3<=ram_out(14 downto 12);

-- the register pipeline 

RS1:generic_reg generic map(address_width) port map(clk,rst,'1',ram_out(19 downto 15),read_address1);

RS2:generic_reg generic map(address_width) port map(clk,rst,'1',ram_out(24 downto 20),read_address2);

RD:generic_reg generic map(address_width) port map(clk,rst,'1',ram_out(11 downto 7),write_address);

IMMDIATE_FIELD:generic_reg generic map(12) port map(clk,rst,'1',ram_out(data_width-1 downto 20),immediate_value);

UPPER_IMMEDIATE_FIELD:generic_reg generic map(20) port map(clk,rst,'1',ram_out(data_width-1 downto 12),upper_immediate_value);

PROGRAM_COUNTER:generic_reg generic map(data_width) port map(clk,rst,enable_pc,next_pc,PC_out);

end arch;