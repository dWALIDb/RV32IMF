--ADD 0000
--sub 0001
--AND 0010
--OR  0011
--xor 0100
--SLT 0101
--SLTU 0110
--SLL 0111
--SRL 1000
--SRA 1001
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity arithmetic_logic_unit is 
generic(
	operand_width:integer:=32;
	address_width:integer:=5
);
port(
	A,B:in std_logic_vector(operand_width-1 downto 0);
	op:in std_logic_vector(3 downto 0);
	C:out std_logic_vector(operand_width-1 downto 0)
);end arithmetic_logic_unit;

architecture arch of arithmetic_logic_unit is 
signal output: std_logic_vector(operand_width-1 downto 0);
constant ZERO: std_logic_vector(operand_width-1 downto 0):=(others=>'0');
constant ONE: std_logic_vector(operand_width-1 downto 0):=(0=>'1',others=>'0');
begin

process(A,B,op)
begin
output<=ZERO;
case op is
when "0000"=> output<=std_logic_vector(unsigned(A)+unsigned(B));--add
when "0001"=> output<=std_logic_vector(unsigned(A)-unsigned(B));--sub
when "0010"=> output<=A and B;--and 
when "0011"=> output<=A or B;--or
when "0100"=> output<=A xor B;--xor idk why im commenting but its funny xD
when "0101"=> if signed(A)>signed(B) then output<=ONE; else output<=ZERO; end if;--signed comparison
when "0110"=> if unsigned(A)>unsigned(B) then output<=ONE; else output<=ZERO; end if;--unsigned comparison
when "0111"=> output<=std_logic_vector(shift_left(unsigned(A),to_integer(unsigned(B(address_width-1 downto 0)))));--shift left
when "1000"=> output<=std_logic_vector(shift_right(unsigned(A),to_integer(unsigned(B(address_width-1 downto 0)))));--shift right with 0
when "1001"=> output<=std_logic_vector(shift_right(signed(A),to_integer(unsigned(B(address_width-1 downto 0)))));--shift right with 1 if negative
when others =>null;
end case;
end process;

C<=output;

end arch;