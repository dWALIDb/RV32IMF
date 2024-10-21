--THIS STAGE IS USED TO WRITE BACK TO FP/INTEGER REGISTER
--THE INPUTS ARE EITHER RAM DATA OR AN INPUT SELECTED FROM MEMORY STAGE 
--INPUT CHANGES DEPENDING OF NEEDED FOR WRITE BACK DATA 
--ALU/FPU/MDU FOR ARITHMETIC OPERATIONS 
--FP/INT REGISTER DATA FOR SWAPPING BETWEEN REGISTERS OR CONVERSION
--NEXT PC OR PC+20 BIT IMMEDIATE IS FOR AUPIC AND JUMP AND LINK INSTRUCTIONS 
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tools.all;

entity write_back_stage is 
generic(
	data_width:integer:=32;
	address_width:integer:=5
);
port(
	int:std_logic;
	selected_output,read_memory_data:in std_logic_vector(data_width-1 downto 0);
	writeback_op:in std_logic;
	write_address:in std_logic_vector(address_width-1 downto 0);
	write_address_out:out std_logic_vector(address_width-1 downto 0);
	write_back_value:out std_logic_vector(data_width-1 downto 0)
);end write_back_stage;
architecture arch of write_back_stage is

component generic_reg is 
generic(data_width:integer :=8);
port (
	clk,rst,ld:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component;

signal output:std_logic_vector(data_width-1 downto 0);
begin 
--selected output for -4 when holding the address
output<=selected_output when writeback_op='0' and int='0' else
		std_logic_vector(unsigned(selected_output)-4) when writeback_op='0' and int='1'else 
		read_memory_data;

write_back_value<=output;

--write and read addresses for write back
write_address_out<=write_address;
end arch;