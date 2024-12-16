--module has 3 BIG Components 
--Floating Point Unit for operantions on floating point representation
--arithmetic logic unit for operations on integers like "add" and "OR" operations  
--integer multiply and devide module that operates on integers 
--alu output is multiplexed with an address calculation that occurs when we need to calculate an offset for store
--branch and jump ofsets are handelled separately
--comparison is signed unless unsigned_compare is set
--4700 logic
library IEEE;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tools.all;

entity execute_stage is 
generic(
	operand_width:integer:=32;
	address_width:integer:=5;
	opcode_width:integer:=7;
	mantissa_width:integer:=23;
	exponent_width:integer:=8
);
port(
	clk,rst,fp_enable,unsigned_compare,address_calculate:in std_logic;
	A_int,A_fp,B_int,B_fp,extendedB,PC_PLUS4:in std_logic_vector(operand_width-1 downto 0);
	upper_immediate_value:std_logic_vector(19 downto 0);
	write_address:in std_logic_vector(address_width-1 downto 0);
	alu_op,fp_op:in std_logic_vector(3 downto 0);
	mul_div_op:in std_logic_vector(2 downto 0);
	offset_src,int_srcB,fp_srcA:in std_logic_vector(1 downto 0);
	fp_done:out std_logic;
	write_address_out:out std_logic_vector(address_width-1 downto 0);
	ALU_NEQ,ALU_EQ,ALU_LT,ALU_GE:out std_logic;
	C_alu,C_mul_div,C_fpu,PC_PLUS4_out,PC_unconditional:out std_logic_vector(operand_width-1 downto 0)
); end execute_stage;

architecture arch of execute_stage is 

component generic_reg is 
generic(data_width:integer :=8);
port (
	clk,rst,ld:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component;

component fp_unit is 
generic(
operand_width:integer:=32;
mantissa_width:integer:=23;
exponent_width:integer:=8
);
port(
	clk,rst:in std_logic;
	op:in std_logic_vector(3 downto 0);
	A,B:in std_logic_vector(operand_width-1 downto 0);
	done:out std_logic;
	C:out std_logic_vector(operand_width-1 downto 0)
);
end component;

component arithmetic_logic_unit is 
generic(
	operand_width:integer:=32;
	address_width:integer:=5
);
port(
	A,B:in std_logic_vector(operand_width-1 downto 0);
	op:in std_logic_vector(3 downto 0);
	C:out std_logic_vector(operand_width-1 downto 0)
);end component;

component int_mul_div is 
generic(operand_width:integer :=32 );
port(
	A,B:in std_logic_vector(operand_width-1 downto 0);
	OP:std_logic_vector(2 downto 0);
	C:out std_logic_vector(operand_width-1 downto 0)
);end component;

constant all_zeroes:std_logic_vector(operand_width-1 downto 0):=(others=>'0');
constant all_ones:std_logic_vector(operand_width-1 downto 0):=(others=>'1');
signal calculated_address,calculated_offset,selected_offset,fpu_out,mult_div_out,alu_out,integer_operandA,integer_operandB,FP_operandA,FP_operandB:std_logic_vector(operand_width-1 downto 0);
signal equal,greater,not_equal,unsigned_greater,lower,unsigned_lower:std_logic;
signal store_offset_forming:std_logic_vector(data_width-1 downto 0);
--lsb is forced to be ZERO
signal B_format:std_logic_vector(10 downto 0);
signal J_format:std_logic_vector(18 downto 0);
--not forced to be ZERO for lsb because upper 20 bits 
signal U_format:std_logic_vector(19 downto 0);
begin 

--input for alu and mul_div
integer_operandA<= A_int;

integer_operandB<= B_int when int_srcB="00" else --regular input or forwarded input or immediate extended
				   extendedB when int_srcB="10" else 
				   PC_PLUS4;--this takes care of jarl

--input for FP
fp_operandA<= A_fp when fp_srcA="00" else --regular input or integer input to convert to float
				   A_int;
fp_operandB<= B_fp;

--address calculation it has B format used for store instructions but different bit arrangement (used for OUTPUT instruction too :) ) 
store_offset_forming<=all_zeroes(data_width-12-1 downto 0)&upper_immediate_value(19 downto 13)&write_address when upper_immediate_value(19)='0' else all_ones(data_width-12-1 downto 0)&upper_immediate_value(19 downto 13)&write_address;

calculated_address<=std_logic_vector(unsigned(B_int)+unsigned(store_offset_forming)) when address_calculate='1' else alu_out;

--register outputs of modules always enabled so they would take values each cycle
FPU_OUTPUT:generic_reg generic map(operand_width) port map(clk,rst,'1',fpu_out,C_fpu);

ALU_OUTPUT:generic_reg generic map(operand_width) port map(clk,rst,'1',calculated_address,C_alu);

MDU_OUTPUT:generic_reg generic map(operand_width) port map(clk,rst,'1',mult_div_out,C_mul_div);

PROGRAM_COUNTER:generic_reg generic map(operand_width) port map(clk,rst,'1',PC_PLUS4,PC_PLUS4_out);

OFFSET_PROGRAM_COUNTER:generic_reg generic map(operand_width) port map(clk,rst,'1',calculated_offset,PC_unconditional);

WD:generic_reg generic map(address_width) port map(clk,rst,'1',write_address,write_address_out);

--the essential components
FPU:fp_unit generic map(operand_width,mantissa_width,exponent_width) port map(clk,not fp_enable OR rst,fp_op,fp_operandA,fp_operandB,fp_done,fpu_out);

ALU:arithmetic_logic_unit generic map(operand_width,address_width) port map(integer_operandA,integer_operandB,alu_op,alu_out);

MDU:int_mul_div generic map(operand_width) port map(integer_operandA,integer_operandB,mul_div_op,mult_div_out);

--auipc use U format jal uses J format and branches use B format 
B_format<=upper_immediate_value(19)&write_address(0)&upper_immediate_value(18 downto 14)&write_address(address_width-1 downto  1);

J_format<=upper_immediate_value(19)&upper_immediate_value(7 downto 1)&upper_immediate_value(8)&upper_immediate_value(18 downto 9);

U_format<=upper_immediate_value;

selected_offset<=all_zeroes(operand_width-B_format'length-2 downto 0)&B_format&'0' when offset_src="00" AND upper_immediate_value(19)='0' else --branch
				 all_ones(operand_width-B_format'length-2 downto 0)&B_format&'0' when offset_src="00" AND upper_immediate_value(19)='1' else 
				 all_zeroes(operand_width-J_format'length-2 downto 0)&J_format&'0' when offset_src="01" AND upper_immediate_value(19)='0' else--jal
				 all_ones(operand_width-J_format'length-2 downto 0)&J_format&'0' when offset_src="01" AND upper_immediate_value(19)='1' else
				 U_format&all_zeroes(operand_width-U_format'length-1 downto 0) when offset_src="11" else --aupic
				 (others=>'0');

calculated_offset<=std_logic_vector(unsigned(PC_PLUS4)+unsigned(selected_offset));

equal<='1' when A_int=B_int else '0';
not_equal<=not equal;

greater<='1' when signed(A_int)>signed(B_int) else '0';
lower<='1' when signed(A_int)>signed(B_int) else '0';

unsigned_greater<='1' when unsigned(A_int)>unsigned(B_int) else '0';
unsigned_lower<='1' when unsigned(A_int)>unsigned(B_int) else '0';

ALU_EQ<=equal;

ALU_NEQ<=not_equal;

ALU_GE<=greater or equal  when unsigned_compare='0' else unsigned_greater or equal;

ALU_LT<=lower when unsigned_compare='0' else unsigned_lower;

end arch;