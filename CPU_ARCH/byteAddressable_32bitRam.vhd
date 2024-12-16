library ieee;
use ieee.std_logic_1164.all;

entity byteAddressable_32bitRam is 
generic(
		address_width: integer:=6;
		mif0:string:="C:\Users\DELL\Desktop\fpga\RISC-V-CORE-WITH-VHDL-main\RISC-V-CORE-WITH-VHDL-main\assembler\d_mif0.mif";
		mif1:string:="C:\Users\DELL\Desktop\fpga\RISC-V-CORE-WITH-VHDL-main\RISC-V-CORE-WITH-VHDL-main\assembler\d_mif0.mif";
		mif2:string:="C:\Users\DELL\Desktop\fpga\RISC-V-CORE-WITH-VHDL-main\RISC-V-CORE-WITH-VHDL-main\assembler\d_mif0.mif";
		mif3:string:="C:\Users\DELL\Desktop\fpga\RISC-V-CORE-WITH-VHDL-main\RISC-V-CORE-WITH-VHDL-main\assembler\d_mif0.mif"
);
port(
	clk,rd,wd:in std_logic;
	address:in std_logic_vector(address_width -1 downto 0);
	D:in std_logic_vector(31 downto 0);
	Q:out std_logic_vector(31 downto 0)
);end byteAddressable_32bitRam;
architecture arch of byteAddressable_32bitRam is 

component byteAdressable_ram is 
generic(
		address_width:integer:=6;
		synthesis_file_directory: string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RAM TEST/ram_in.mif"
);
port(
--use this module to instantiate 4 rams and then write C++ code to generate the 4 initialization files :)
--i meaaan you can't complain you wanted this buddy stop whining;) 
		clk,RD,wd:in std_logic;
		address:in std_logic_vector(address_width-1 downto 0);
		D:in std_logic_vector(7 downto 0);
		Q:out std_logic_vector(7 downto 0)
);end component;

signal out0,out1,out2,out3:std_logic_vector(7 downto 0);

begin 

RAM0:byteAdressable_ram generic map(address_width,mif0) port map(clk,rd,wd,address,D(7 downto 0),out0);
RAM1:byteAdressable_ram generic map(address_width,mif1) port map(clk,rd,wd,address,D(15 downto 8),out1);
RAM2:byteAdressable_ram generic map(address_width,mif2) port map(clk,rd,wd,address,D(23 downto 16),out2);
RAM3:byteAdressable_ram generic map(address_width,mif3) port map(clk,rd,wd,address,D(31 downto 24),out3);

q<=out3&out2&out1&out0;
end arch;