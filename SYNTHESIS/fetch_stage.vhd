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
	instruction_synthesis_file_directory0:string:=
	"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_0.mif";
	instruction_synthesis_file_directory1:string:=
	"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_1.mif";
	instruction_synthesis_file_directory2:string:=
	"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_2.mif";
	instruction_synthesis_file_directory3:string:=
	"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_3.mif";
	simulation:boolean:=false
);
port(
	clk,rst,rd,wd,enable_pc:in std_logic;
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

component byteAddressable_32bitRam is 
generic(
		address_width: integer:=6;
		mif0:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RAM TEST/MIF0.mif";
		mif1:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RAM TEST/MIF1.mif";
		mif2:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RAM TEST/MIF2.mif";
		mif3:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RAM TEST/MIF3.mif"
);
port(
	clk,rd,wd:in std_logic;
	address:in std_logic_vector(address_width -1 downto 0);
	D:in std_logic_vector(31 downto 0);
	Q:out std_logic_vector(31 downto 0)
);end component;


constant ZERO:std_logic_vector(data_width-1 downto 0):=(others=>'0');
signal PC_out,new_PC,ram_out,chosen_pc:std_logic_vector(data_width-1 downto 0);
begin
--instantiation of ram module depending on the usage
GENERATE_SIMULATION_INSTRUCTION_MEMORY:if(simulation=true) generate
SIMULATION_INSTRUCTION_MEMORY:RAM_simulation generic map (data_width,memory_address_width,simulation_file_directory)
port map(clk,'1','0',PC_out(memory_address_width-1 downto 0),(others=>'0'),ram_out);
end generate;

GENERATE_SYNTHESIS_INSTRUCTION_MEMORY:if(simulation=false) generate
SYNTHESIS_INSTRUCTION_MEMORY: byteAddressable_32bitRam generic map(memory_address_width,instruction_synthesis_file_directory0,instruction_synthesis_file_directory1,instruction_synthesis_file_directory2,instruction_synthesis_file_directory3)
port map(clk,rd,wd,"00"&PC_out(memory_address_width-1 downto 2),(others=>'0'),ram_out);
--RAM_synthesis generic map (data_width,memory_address_width,synthesis_file_directory)
--port map(clk,'1','0',PC_out(memory_address_width-1 downto 0),(others=>'0'),ram_out);
end generate;
--calculation of next PC  we add 4 because all instructions are 4 bytes and little endian
pc_outplus4<=std_logic_vector(unsigned(PC_out)+4);

--control unit inputs 
opcode<=ram_out(opcode_length-1 downto 0);

func7<=ram_out(data_width-1 downto data_width-7);

func3<=ram_out(14 downto 12);

-- the register pipeline 

process(clk,rst)
begin 
if(rst='1') then read_address1<=(others=>'0');
read_address2<=(others=>'0');
write_address<=(others=>'0');
immediate_value<=(others=>'0');
upper_immediate_value<=(others=>'0');

elsif(clk'event and clk='1')then 
read_address1<=ram_out(19 downto 15);
read_address2<=ram_out(24 downto 20);
write_address<=ram_out(11 downto 7);
immediate_value<=ram_out(data_width-1 downto 20);
upper_immediate_value<=ram_out(data_width-1 downto 12);
end if;

end process;
--RS1:generic_reg generic map(address_width) port map(clk,rst,'1',ram_out(19 downto 15),read_address1);
--
--RS2:generic_reg generic map(address_width) port map(clk,rst,'1',);
--
--RD:generic_reg generic map(address_width) port map(clk,rst,'1',
--
--IMMDIATE_FIELD:generic_reg generic map(12) port map(clk,rst,'1',
--
--UPPER_IMMEDIATE_FIELD:generic_reg generic map(20) port map(clk,rst,'1',

PROGRAM_COUNTER:generic_reg generic map(data_width) port map(clk,rst,enable_pc,next_pc,PC_out);

end arch;