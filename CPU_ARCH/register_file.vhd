--the boolean is used to determin if the zero address is hardwired to zero or not
--simplest solution is the boolean in the generic
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tools.all;

entity register_file is 
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
end register_file;

architecture arch of register_file is 
signal reg_file_data: std_logic_vector_array(2**address_width-1 downto 0)(data_width-1 downto 0):=(others=>(others=>'0'));
signal output1,output2:std_logic_vector(data_width-1 downto 0);
constant ZERO_address:std_logic_vector(address_width-1 downto 0):=(others=>'0');
begin 

WRITING_PROCESS:process(clk,wd,write_address,reg_file_data)
begin 
if(clk'event and clk='1') then if(wd='1') then
	if(write_address=ZERO_address and hard_wired_zero=true)then reg_file_data(to_integer(unsigned(write_address)))<=(others=>'0');
	else reg_file_data(to_integer(unsigned(write_address)))<=D;
	end if;
end if;end if;
end process;

READING_PROCESS2:process(rd2,read_address2,reg_file_data)
begin
if(rd2='1') then 
OUTPUT2<=reg_file_data(to_integer(unsigned(read_address2)));
else output2<=(others=>'0');
end if;
end process;


READING_PROCESS1:process(rd1,read_address1,reg_file_data)
begin
if(rd1='1') then 
OUTPUT1<=reg_file_data(to_integer(unsigned(read_address1)));
else output1<=(others=>'0');
end if;
end process;
Q2<=output2;
Q1<=output1;
end arch;