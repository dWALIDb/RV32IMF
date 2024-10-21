--little endian 
--memory is byte addressable but outputs 4 bytes of memory
--example 
--0A0B0C0D in little endian is stored as follows "0D" at i "0C" at i+1 "0B" at i+2 "0A" at i+3
--one architecture is used for synthesis(mif file) and the other for simulation(txt file)
--used for instruction memory and for data memory 
--variable in process used to run the for-loop because the loops are kinda weird with signals
--used for synthesis because attributes are synthesisable but not simulatable for some reason
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tools.all;

entity RAM_synthesis is 
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
end RAM_synthesis;
architecture synthesis of RAM_synthesis is

signal ram_data: std_logic_vector_array(2**address_width-1 downto 0)(7 downto 0):=(others=>(others=>'0'));

attribute ram_init_file : string;
attribute ram_init_file of ram_data :signal is synthesis_file_directory;
signal output:std_logic_vector(data_width-1 downto 0);

begin 

check_extention(synthesis_file_directory,".mif" );

WRITING_PROCESS:process(clk,wd,address)
begin 
if(clk'event and clk='1') then if(wd='1') then
	for i in 0 to data_width/8 -1 loop 
	ram_data(to_integer(unsigned(address)+i))<=D(data_width-1-(data_width/8-1-i)*8 downto (data_width-1-(data_width/8-1-i)*8-7));
	end loop;
end if;end if;
end process;

READING_PROCESS:process(rd,address,ram_data)
variable O:std_logic_vector(data_width-1 downto 0);
begin
O:=(others=>'0');
if(RD='1') then 
	for i in 0 to data_width/8 -1 loop 
	--shift the input in byte by byte 
	O:=O(data_width-1-8 downto 0)&ram_data(to_integer(unsigned(address)-i+data_width/8 -1));
	end loop;
OUTPUT<=O;
	else output<=(others=>'0');
end if;
end process;
Q<=output;
end synthesis;