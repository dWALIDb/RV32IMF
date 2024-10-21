--mul div for signed and unsigned integers
--mul 000 lower bits of multiplication
--mulhU 001 upper bits of multiplication both operands are unsigned 
--mulh 010 both operands are signed result is fine
--mulhSU 011 for signed*unsigned operands A is considered the signed operand 
--divU 100 for unsigned operands
--div 101 for signed operands
--remU 110 for unsigned remainder
--rem 111 for signed remainder
--the outputs and philosophy of operation is taken from the RISC-V SPEC version 2.2
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity int_mul_div is 
generic(operand_width:integer :=32 );
port(
	A,B:in std_logic_vector(operand_width-1 downto 0);
	OP:std_logic_vector(2 downto 0);
	C:out std_logic_vector(operand_width-1 downto 0)
);end int_mul_div;

architecture arch of int_mul_div is 

signal multiplication:std_logic_vector(2*operand_width-1 downto 0);
signal division,remainder,output:std_logic_vector(operand_width-1 downto 0);
constant all_ones:std_logic_vector(operand_width-1 downto 0):=(others=>'1');--1111...1111
constant ZERO:std_logic_vector(operand_width-1 downto 0):=(others=>'0');--000....000
constant most_negative:std_logic_vector(operand_width-1 downto 0):=(operand_width-1=>'1',others=>'0');--1000....0000
begin

multiplication<=std_logic_vector(unsigned(A) * unsigned(B));

division<=all_ones when B=ZERO else std_logic_vector(unsigned(A) / unsigned(B));--return dividend when division by ZERO

remainder<=A when B=ZERO else std_logic_vector(unsigned(A) rem unsigned(B));--return dividend when division by ZERO

process(A,B,OP,multiplication,division,remainder)
begin
case op is 
when "000"=> output<=multiplication(operand_width-1 downto 0);--we take lower bits of multiplication
when "001"=> output<=multiplication(2*operand_width-1 downto operand_width);--we take upper bits of multiplication when unsigned
when "010"=> if A(operand_width-1) /= B(operand_width-1) then output<=std_logic_vector(unsigned(not multiplication(2*operand_width-1 downto operand_width))+1) ;else output<=multiplication(2*operand_width-1 downto operand_width);end if;--upper bits taken for signed multiplication
when "011"=> if A(operand_width-1) ='1' then output<=std_logic_vector(unsigned(not multiplication(2*operand_width-1 downto operand_width))+1) ;else output<=multiplication(2*operand_width-1 downto operand_width);end if;--A is signed and B is unsigned 
when "100"=> output<=division;--unsigned division
when "101"=> if(A=most_negative and B=all_ones) then output<=most_negative;
			 elsif A(operand_width-1) /= B(operand_width-1) then output<=std_logic_vector(unsigned(not division )+1); else output<=division;end if;--signed division special over flow case when A is most negative and B is -1 then we take most_negative as quotient
when "110"=> output<=remainder;--take unsigned remainder
when "111"=> if A=most_negative and B=all_ones then output<=zero;
			 elsif A(operand_width-1) /= B(operand_width-1) then output<=std_logic_vector(unsigned(not remainder )+1); 
			 else output<=remainder;end if;--special over flow case when A is most negative and B is -1 then we take as remainder
when others=>null;
end case;
end process;
C<=output;
end arch;