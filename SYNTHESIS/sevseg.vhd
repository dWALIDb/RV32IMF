library ieee;
use ieee.std_logic_1164.all;

entity sevseg is 
port(
	input: in std_logic_vector(3 downto 0);
	output: out std_logic_vector(6 downto 0)
);
end sevseg;
architecture arch of sevseg is
signal v:std_logic_vector(6 downto 0); 
begin
 
	process(input)
	begin
	case(input) is
	--hex(0),hex(1)...hex(6) THE values are swapped so the msb is the LSB in pin assignement :)
	when x"0"=>v<="0000001";
	when x"1"=>v<="1001111";
	when x"2"=>v<="0010010";
	when x"3"=>v<="0000110";
	when x"4"=>v<="1001100";
	when x"5"=>v<="0100100";
	when x"6"=>v<="0100000";
	when x"7"=>v<="0001111";
	when x"8"=>v<="0000000";
	when x"9"=>v<="0000100";
	when x"A"=>v<="0000010";
	when x"B"=>v<="1100000";
	when x"C"=>v<="0110001";
	when x"D"=>v<="1000010";
	when x"E"=>v<="0110000";
	when x"F"=>v<="0111000";
	when others=>v<="0111111";
	end case;
	end process;
	output<=v;
end arch;