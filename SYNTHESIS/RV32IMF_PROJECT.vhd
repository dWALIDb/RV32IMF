-- this file is used for synthesis,and is providing PC,SEVEN SEGMENT DISPLAY
-- so when we test the values 
library ieee;
use ieee.std_logic_1164.all;

entity RV32IMF_PROJECT is
generic(
data_width:integer:=32;
address_width:integer:=5;
instruction_memory_address_width:integer:=6;
data_memory_address_width:integer:=6;

data_synthesis_file_directory0:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_0.mif";
data_synthesis_file_directory1:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_1.mif";
data_synthesis_file_directory2:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_2.mif";
data_synthesis_file_directory3:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_3.mif";

instruction_synthesis_file_directory0:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\mif_0.mif";
instruction_synthesis_file_directory1:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\mif_1.mif";
instruction_synthesis_file_directory2:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\mif_2.mif";
instruction_synthesis_file_directory3:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\mif_3.mif"


);
port (
--"rd" must be '1' and "wd" must be '0'
	clk,rst,int,rd,wd:in std_logic;
	IN_DATA:in std_logic_vector(31 downto 0);
	pc:out std_logic_vector(31 downto 0);
	sev_seg1,sev_seg2,sev_seg3,sev_seg4,sev_seg5,sev_seg6,sev_seg7,sev_seg8:out std_logic_vector(6 downto 0)
);end RV32IMF_PROJECT;
architecture arch of RV32IMF_PROJECT is 


component sevseg is 
port(
	input: in std_logic_vector(3 downto 0);
	output: out std_logic_vector(6 downto 0)
);
end component;

component RV32IMF is 
generic(
data_width:integer:=32;
address_width:integer:=5;
instruction_memory_address_width:integer:=6;
data_memory_address_width:integer:=6;

data_simulation_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.txt";

data_synthesis_file_directory0:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_0.mif";
data_synthesis_file_directory1:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_1.mif";
data_synthesis_file_directory2:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_2.mif";
data_synthesis_file_directory3:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_3.mif";

instruction_simulation_file_directory:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\output_file.txt";

instruction_synthesis_file_directory0:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\mif_0.mif";
instruction_synthesis_file_directory1:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\mif_1.mif";
instruction_synthesis_file_directory2:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\mif_2.mif";
instruction_synthesis_file_directory3:string:=
"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\mif_3.mif";

mantissa_width:integer:=23;
exponent_width:integer:=8;
opcode_length:integer:=7;
simulation:boolean:=false
);
port(
--could use "go" signal that is used to rst control unit and to rst whole pipeline :)
	clk,rst,int,rd,wd:in std_logic;
	I_DATA:in std_logic_vector(data_width-1 downto 0);
	--address0,address1,address2,address3,address4:out std_logic_vector(address_width-1 downto 0);
	O_DATA,pc:out std_logic_vector(data_width-1 downto 0)
	--,D_data,OPCODE_data,InT_data1,inT_data2,fp_data1,fp_data2,wb_data,ram_data,pc:out std_logic_vector(data_width-1 downto 0)
);
end component;

signal CPU_output:std_logic_vector(31 downto 0);
begin

THE_CORE:RV32IMF 
generic map(32,5,instruction_memory_address_width,data_memory_address_width,"",data_synthesis_file_directory0,
data_synthesis_file_directory1,data_synthesis_file_directory2,data_synthesis_file_directory3,"",instruction_synthesis_file_directory0,instruction_synthesis_file_directory1,
instruction_synthesis_file_directory2,instruction_synthesis_file_directory3,23,8,7,false)

port map(clk,rst,int,rd,wd,IN_DATA,CPU_output,pc);

--seven segment display set up, but outputs must be assigned
SEVSEG1:sevseg port map(CPU_output(3 downto 0),sev_seg1);
SEVSEG2:sevseg port map(CPU_output(7 downto 4),sev_seg2);
SEVSEG3:sevseg port map(CPU_output(11 downto 8),sev_seg3);
SEVSEG4:sevseg port map(CPU_output(15 downto 12),sev_seg4);
SEVSEG5:sevseg port map(CPU_output(19 downto 16),sev_seg5);
SEVSEG6:sevseg port map(CPU_output(23 downto 20),sev_seg6);
SEVSEG7:sevseg port map(CPU_output(27 downto 24),sev_seg7);
SEVSEG8:sevseg port map(CPU_output(31 downto 28),sev_seg8);

end arch;