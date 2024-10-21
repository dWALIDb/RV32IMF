--FP AND INT REGISTER FILES HAVE THE SAME INPUT AND THE SAME WRITE ADDRESSES 
--BECAUSE ONE OF THEM ONLY MUST BE ENABLED AND THEY USE THE SAME FOR INSTRUCTIONS FIELDS 
--SAME FOR READ ADDRESSES YOU ENABLE WHAT YOU NEED :)
library ieee;
use ieee.std_logic_1164.all;
use work.tools.all;

entity decode_stage is 
generic(
	data_width:integer:=32;
	address_width:integer:=5
);
port (
	clk,rst,int,ld_intaddress,int_wd,int_rd1,int_rd2,fp_wd,fp_rd1,fp_rd2:in std_logic;
	input_data,PC_PLUS4:in std_logic_vector(data_width-1 downto 0);--used for both int and float chosing is for the stage write back
	immediate_value:in std_logic_vector(11 downto 0);
	upper_immediate_value:in std_logic_vector(19 downto 0);
	read_address1,read_address2,writeback_address,write_address:in std_logic_vector(address_width-1 downto 0);
	write_address_out:out std_logic_vector(address_width-1 downto 0);
	extended_value:out std_logic_vector(data_width-1 downto 0);
	upper_immediate_value_out:out std_logic_vector(19 downto 0);
	int_operand1,int_operand2,fp_operand1,fp_operand2,PC_PLUS4_out:out std_logic_vector(data_width-1 downto 0)
	);
end decode_stage;

architecture arch of decode_stage is 

component register_file is 
generic(data_width:integer :=32 ;
		address_width:integer:=5;
		hard_wired_zero:boolean:=true
);
port(
		clk,wd,rd1,rd2:in std_logic;
		read_address1,read_address2,write_address:in std_logic_vector(address_width-1 downto 0);
		D:in std_logic_vector(data_width-1 downto 0);
		Q1,Q2:out std_logic_vector(data_width-1 downto 0)
);
end component;

component generic_reg is 
generic(data_width:integer :=8);
port (
	clk,rst,ld:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component;

signal int_output1,int_output2,fp_output1,fp_output2,sign_extended:std_logic_vector(data_width-1 downto 0);
signal chosen_address,interrupt_address:std_logic_vector(address_width-1 downto 0);
constant all_zeroes:std_logic_vector(19 downto 0):=(others=>'0');
constant all_ones:std_logic_vector(19 downto 0):=(others=>'1');
begin

FP_REGISTER:register_file generic map(data_width,address_width,FALSE) port map(clk,fp_wd,fp_rd1,fp_rd2,read_address1,read_address2,writeback_address,input_data,fp_output1,fp_output2);
INTEGER_REGISTER:register_file generic map(data_width,address_width,TRUE) port map(clk,int_wd,int_rd1,int_rd2,read_address1,read_address2,writeback_address,input_data,int_output1,int_output2);

--register the outputs
process(clk,rst)
begin
if(rst='1')then 
fp_operand1<=(others=>'0');
fp_operand2<=(others=>'0');
int_operand1<=(others=>'0');
int_operand2<=(others=>'0');
extended_value<=(others=>'0');
upper_immediate_value_out<=(others=>'0');
PC_PLUS4_out<=(others=>'0');
write_address_out<=(others=>'0');

elsif(clk'event and clk='1')then 
fp_operand1<=fp_output1;
fp_operand2<=fp_output2;
int_operand1<=int_output1;
int_operand2<=int_output2;
extended_value<=sign_extended;
upper_immediate_value_out<=upper_immediate_value;
PC_PLUS4_out<=PC_PLUS4;
write_address_out<=chosen_address;
end if;
end process;


--first_FP_OUTPUT:generic_reg generic map(data_width) port map(clk,rst,'1',fp_output1,fp_operand1);
--second_FP_OUTPUT:generic_reg generic map(data_width) port map(clk,rst,'1',fp_output2,fp_operand2);
--
--first_INT_OUTPUT:generic_reg generic map(data_width) port map(clk,rst,'1',int_output1,int_operand1);
--second_INT_OUTPUT:generic_reg generic map(data_width) port map(clk,rst,'1',int_output2,int_operand2);
--
--registered_sign_extended:generic_reg generic map(data_width) port map(clk,rst,'1',sign_extended,extended_value);
--registered_upper_immediate_extended:generic_reg generic map(20) port map(clk,rst,'1',upper_immediate_value,upper_immediate_value_out);
--
--PROGRAM_COUNTER:generic_reg generic map(data_width) port map(clk,rst,'1',PC_PLUS4,PC_PLUS4_out);
--
ADDRESS_LOCATION_ON_INTERRUPT:generic_reg generic map(address_width) port map(clk,rst,ld_intaddress,write_address,interrupt_address);
--
chosen_address<=write_address when int='0' else interrupt_address; 

--WD_ADDRESS:generic_reg generic map(address_width) port map(clk,rst,'1',chosen_address,write_address_out);
--sign extended immediate
 
sign_extended<= all_ones&immediate_value when immediate_value(data_width-opcode_length-2*address_width-4)='1'
					else all_zeroes&immediate_value;
end arch;