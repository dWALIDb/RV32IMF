library ieee;
use ieee.std_logic_1164.all;
use STD.TEXTIO.all;
use ieee.std_logic_textio.all;

package tools is 

constant instruction_address: integer:=5;
--address width for registers
constant data_address: integer:=5;
--instruction address for rams used for data and instruction memories
constant memory_address_width: integer :=6;
constant data_width: integer :=32;
constant simulation_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF_sim/Text1.txt";
constant synthesis_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.mif";
constant opcode_length:integer:=7;

type std_logic_vector_array is array (integer range<>) of std_logic_vector;

impure function init_ram_withFile(file_directory: string;num_rows: integer) return std_logic_vector_array;

procedure check_extention(file_directory:in string;extention:in string);
end package tools;

package body tools is 

procedure check_extention(file_directory:in string;extention:in string) is 
begin 
--string is defined to have the range <1 TO  last element> counter intuitive for me (im used to DOWNTO
-- so "C:\data" C is index 1 and "a"in data is index 7     :)
assert(file_directory(file_directory'length-extention'length+1 to file_directory'length)=extention)
report "file extention "& file_directory(file_directory'length-extention'length-1 to file_directory'length) &" not supported please use a "&extention&" file to proceed" 
severity failure;

end procedure;

impure function init_ram_withFile(file_directory: string;num_rows: integer) return std_logic_vector_array is 

file data_file : text open read_mode is file_directory;
variable row : line;
variable S:string(1 to 8);
--memory is byte addressable 
variable data_read: std_logic_vector_array(2**num_rows -1 downto 0)(7 downto 0);
variable i: integer range 0 to 2**num_rows+4;

begin 
check_extention(file_directory,".txt" );
while not endfile(data_file) loop

for y in 0 to data_width/8 -1 loop
readline(data_file,row);--we read byte 1 then byte 2 and so on
S:='0'&row.all(2 to S'length);
if(row.all(1)='#')then i:=integer'value(S)-4; 
exit;end if;

read(row,data_read(i+y));
	end loop;
--readline(data_file,row);
--read(row,data_read(i+1));
--readline(data_file,row);
--read(row,data_read(i+2));
--readline(data_file,row);
--read(row,data_read(i+3));

if(i<2**num_rows-4)  then i:=i+4; 
else exit; 
end if;

end loop;
file_close(data_file);
return data_read;
end function;

end package body;