--MODULE has DATA RAM FOR LOAD AND STORE 
--LOAD HAS THE ADDRESS CALCULATED IN EXECUTE STAGE AND PUT IN ALU OUTPUT
--STORE HAS THE ADDRESS CALCULATED IN EXECUTE STAGE SEPARATELY BUT ITS MULTIPLEXED WITH ALU OUTPUT 
--BOTH ADDRESSES ARE PUT IN ALU OUT REGISTER IN THE END
--DATA FOR RAM INPUT COULD BE ALU/FPU/MDU OUTPUTS,FP/INT REGISTER DATA,UPPER IMMEDIATE VALUE,PC+4 OR PC+20-BIT IMMEDIATE
--MOST OF THESE SIGNALS ARE USED AS INPUT FOR WRITE BACK STAGE SO THE OUTPUT OF MULTIPLEXER IS USED FOR WRITE BACK,THIS WAY WE REDUCE LOGIC ELEMENTS 
--NEXT INSTRUCTION IS DECIDED AT THIS STAGE,BRANCHES ARE CONDITIONAL AND EACH CONDITION HAS ITS OWN SIGNAL AND ITS OWN EVALUATION
--UNCONDITIONAL BRANCHES HAVE THE SIGNAL UNCONDITIONAL THAT ENABLES THEM EXCEPT FOR JARL THAT USES ALU OUT AND JUMP AND LINK SIGNAL TO BE TAKEN 
--2998 logic 2180 reg
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.tools.all;

entity memory_stage is
generic(
	data_width:integer:=32;
	address_width:integer:=5;
	memory_address_width:integer:=6;
	--simulation file must be .txt file 
	simulation_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.txt";
	--synthesis file must be .mif file 
	data_synthesis_file_directory0:string:=
	"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_0.mif";
	data_synthesis_file_directory1:string:=
	"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_1.mif";
	data_synthesis_file_directory2:string:=
	"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_2.mif";
	data_synthesis_file_directory3:string:=
	"C:\Users\brazz\OneDrive\Bureau\learn\risc-v assembly\dmif_3.mif";
	simulation:boolean:=false
);
port(
	clk,rst,int,ld_service_routine,IO_IN,RD,WD,alu_NEQ,alu_EQ,alu_LT,alu_GE,CONTROL_NEQ,CONTROL_EQ,CONTROL_LT,CONTROL_GE:in std_logic;
	unconditional,branchneq,brancheq,branchlt,branchge,pc_enable,jump_andlink:in std_logic;
	int_read_data,fp_read_data,IO_DATA,C_ALU,C_FPU,C_mult_div,PC_PLUS4,PC_unconditional:in std_logic_vector(data_width-1 downto 0);
	Upper_Immediate:in std_logic_vector(19 downto 0);
	write_address:in std_logic_vector(address_width-1 downto 0);
	ram_src:in std_logic_vector(2 downto 0);
	write_back_data,ram_out:out std_logic_vector(data_width-1 downto 0);
	write_address_out:out std_logic_vector(address_width-1 downto 0);
	next_pc_out:out std_logic_vector(data_width-1 downto 0)
);end memory_stage;

architecture arch of memory_stage is 

component generic_reg is 
generic(data_width:integer :=8);
port (
	clk,rst,ld:in std_logic;
	D:in std_logic_vector(data_width-1 downto 0);
	Q:out std_logic_vector(data_width-1 downto 0)
);
end component; 

component RAM_synthesis is 
generic(data_width:integer :=32 ;
		address_width:integer:=5;
		synthesis_file_directory: string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.mif"
);
port(
		clk,RD,wd:in std_logic;
		address:in std_logic_vector(address_width-1 downto 0);
		D:in std_logic_vector(data_width-1 downto 0);
		Q:out std_logic_vector(data_width-1 downto 0)
);
end component;

component RAM_simulation is 
generic(data_width:integer :=32 ;
		address_width:integer:=5;
		simulation_file_directory: string
);
port(
		clk,RD,wd:in std_logic;
		address:in std_logic_vector(address_width-1 downto 0);
		D:in std_logic_vector(data_width-1 downto 0);
		Q:out std_logic_vector(data_width-1 downto 0)
);
end component;

component byteAddressable_32bitRam is 
generic(
		address_width: integer:=6;
		mif0:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RAM TEST/MIF0.mif";
		mif1:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RAM TEST/MIF1.mif";
		mif2:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RAM TEST/MIF2.mif";
		mif3:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RAM TEST/MIF3.mif"
);
port(
	clk,rd,wd:in std_logic;
	address:in std_logic_vector(address_width -1 downto 0);
	D:in std_logic_vector(31 downto 0);
	Q:out std_logic_vector(31 downto 0)
);end component;


signal selected_data,read_data,selected_pc,interrupt_service_routine:std_logic_vector(data_width-1 downto 0);
signal beq,bneq,blt,bge:std_logic;
begin 
GENERATE_SIMULATION_DATA_MEMORY:if(simulation=true) generate
SIMULATION_DATA_MEMORY:RAM_simulation generic map(data_width,memory_address_width,simulation_file_directory ) 
port map(clk,RD,WD,C_ALU(memory_address_width-1 downto 0),selected_data,read_data);
end generate;

GENERATE_SYNTHESIS_DATA_MEMORY:if(simulation=false) generate
SYNTHESIS_DATA_MEMORY:byteAddressable_32bitRam generic map(memory_address_width,data_synthesis_file_directory0,data_synthesis_file_directory1,data_synthesis_file_directory2,data_synthesis_file_directory3)
port map(clk,RD,WD,C_ALU(memory_address_width-1 downto 0),selected_data,read_data);

--RAM_synthesis generic map(data_width,memory_address_width,synthesis_file_directory) 
--port map(clk,RD,WD,C_ALU(memory_address_width-1 downto 0),selected_data,read_data);
end generate;
--ADD RAM INPUT CONTROL TO SELECT INPUT OF RAM TO STORE or to pass into write back stage 
selected_data<=C_ALU when ram_src="000"and IO_IN='0' else --to take integer operation results or calculated addresses
			   C_mult_div when  ram_src="001"and IO_IN='0' else --for integer multiplication and devision extension
			   C_FPU when ram_src="010"and IO_IN='0' else --for FPU output 
			   upper_Immediate&"000000000000" when ram_src="011"and IO_IN='0' else --for LUI
			   int_read_data when ram_src="100" and IO_IN='0' else --passing data between registers
			   fp_read_data when ram_src="101" and IO_IN='0' else --passing data between registers
			   PC_PLUS4 when ram_src="110" and IO_IN='0' else --used to store the next instruction from jarl and jal
			   std_logic_vector(unsigned(PC_unconditional)-4) when ram_src="111" and IO_IN='0' else --subtract 4 because we need to offset according to current instruction and not next instruction address
			   IO_data when ram_src="100" and IO_IN='1' else (others=>'0');--IO_DATA is similar to store instruction but for IO so RS1 doesn't matter  

--register pipeline 
DATA_FOR_WRITEBACK:generic_reg generic map(data_width) port map(clk,rst,'1',selected_data,write_back_data);
RAM_OUTPUT:generic_reg generic map(data_width) port map(clk,rst,'1',read_data,RAM_out);
WD_ADDRESS:generic_reg generic map(address_width) port map(clk,rst,'1',write_address,write_address_out);

--pc unconditional has the branch offset value exept for jarl, the offset is the output of the alu
bneq<=branchneq and alu_NEQ and conTROL_NEQ;
beq<=brancheq and alu_EQ and conTROL_EQ;
blt<=branchlt and alu_LT and conTROL_LT;
bge<=branchge and alu_GE and conTROL_GE;

--take the interrupt service routine  from enable interrupt instruction;
--it takes RD to specify register address that is used to store PC when INTERRUPTING
--and RS1 with immediate 12 bits to specify interrupt service routine and an internal signal is set to enable interrupts
NEXT_INSTRUCTION:process(clk,rst,int)
begin
if(rst='1') then interrupt_service_routine<=(others=>'0');selected_pc<=(others=>'0');
elsif(clk'event and clk='0')then 

if(ld_service_routine='1') then interrupt_service_routine<=C_alu(data_width-1 downto 1)&'0';end if;--just like jarl but for INTERRUPT this happens on interrupt enable 

--branch when  else take pc for next instuction jal is a mix between branches and jump and link 
--jal has a 12 bit immediate offset but it stores the next pc so kinda a mix between them 
if(bneq='1' or beq='1' or blt='1' or bge='1' or unconditional='1') then selected_pc<=pc_unconditional;--take branch or jal address
elsif(int='1') then selected_pc<=interrupt_service_routine;--take service routine for next instruction address
elsif(jump_andlink='1')then selected_pc<=C_alu(data_width-1 downto 1)&'0';--jarl has address calculated in alu and the lsb is forced to be 0
elsif(pc_enable='1') then selected_pc<=PC_PLUS4;

end if;end if;
end process;


next_pc_out<=selected_pc;

end arch;