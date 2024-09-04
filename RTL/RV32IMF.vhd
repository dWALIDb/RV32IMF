--the top level of the design 
--all components are instansiated to get the full design
--some data is transfered on the top level to respect the pin count on each component
--the control signals are transfered on top level on positive edge, each stage has its own control signals and 
--they are named as <signal name><how deep in the pipeline> 3 is the highest and 1 is the first pipeline,

library ieee;
use ieee.std_logic_1164.all;
use work.tools.all;

entity RV32IMF is 
generic(
data_width:integer:=32;
address_width:integer:=5;
memory_address_width:integer:=6;
data_simulation_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.txt";
data_synthesis_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.mif";
instruction_simulation_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/instruction.txt";
instruction_synthesis_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/instruction.mif";
mantissa_width:integer:=23;
exponent_width:integer:=8;
opcode_length:integer:=7;
simulation:boolean:=true
);
port(
--could use "go" signal that is used to rst control unit and to rst whole pipeline :)
	clk,rst,int:in std_logic;
	I_DATA:in std_logic_vector(data_width-1 downto 0);
	O_DATA:out std_logic_vector(data_width-1 downto 0)
);
end RV32IMF;

architecture arch of RV32IMF is 

component fetch_stage is 
generic(
	data_width:integer:=32;
	memory_address_width:integer:=6;
	address_width:integer:=5;
	--simulation file must be .txt file 
	simulation_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.txt";
	--synthesis file must be .mif file 
	synthesis_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.mif";
	simulation:boolean:=true
);
port(
	clk,rst,enable_pc:in std_logic;
	next_pc:in std_logic_vector(data_width-1 downto 0);
	immediate_value:out std_logic_vector(11 downto 0);
	upper_immediate_value:out std_logic_vector(19 downto 0);
	read_address1,read_address2,write_address:out std_logic_vector(address_width-1 downto 0);
	func3:out std_logic_vector(2 downto 0);
	func7:out std_logic_vector(6 downto 0);
	pc_outplus4:out std_logic_vector(data_width-1 downto 0);
	opcode:out std_logic_vector(6 downto 0)
);
end component;

component decode_stage is 
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
end component;

component execute_stage is 
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
); end component;

component memory_stage is
generic(
	data_width:integer:=32;
	address_width:integer:=5;
	memory_address_width:integer:=6;
	--simulation file must be .txt file 
	simulation_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.txt";
	--synthesis file must be .mif file 
	synthesis_file_directory:string:="C:/Users/brazz/OneDrive/Bureau/FPGA/RV32IMF/data.mif";
	simulation:boolean:=true
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
);end component;


component write_back_stage is 
generic(
	data_width:integer:=32;
	address_width:integer:=5
);
port(
	int:std_logic;
	selected_output,read_memory_data:in std_logic_vector(data_width-1 downto 0);
	writeback_op:in std_logic;
	write_address:in std_logic_vector(address_width-1 downto 0);
	write_address_out:out std_logic_vector(address_width-1 downto 0);
	write_back_value:out std_logic_vector(data_width-1 downto 0)
);end component;

component RV32IMF_control is 
port(
	clk,rst,int,fp_done:in std_logic;
	opcode,func7:in std_logic_vector(6 downto 0);
	func3:in std_logic_vector(2 downto 0);
	control_NEQ,control_EQ,control_LT,control_GE,fp_enable,ram_rd:out std_logic;
	ram_wd,unsigned_compare,jump_andlink:out std_logic;
	fp_op,alu_op:out std_logic_vector(3 downto 0);
	mul_div_op:out std_logic_vector(2 downto 0);
	offset_src,int_srcB,fp_srcA:out std_logic_vector(1 downto 0);
	ram_src:out std_logic_vector(2 downto 0);
	unconditional,int_wd,int_rd1,int_rd2,fp_wd,fp_rd1,fp_rd2,writeback_op:out std_logic;
	address_calculate,branchneq,brancheq,branchlt,branchge,pc_enable,pc_enable_src,interrupt_ack,ld_intaddress,ld_service_routine,IO_IN,IO_OUT:out std_logic
);end component;

--outputs of fetch stage are inputs for decode 
signal immediate_valueF:std_logic_vector(11 downto 0);
signal upper_immediate_valueF:std_logic_vector(19 downto 0);
signal read_address1F,read_address2F,write_addressF:std_logic_vector(address_width-1 downto 0);
signal func3F:std_logic_vector(2 downto 0);
signal func7F:std_logic_vector(6 downto 0);
signal pc_outplus4F:std_logic_vector(data_width-1 downto 0);
signal opcodeF:std_logic_vector(6 downto 0);
--NEXT PC COMES FROM MEMORY STAGE

--outputs of decode stage are inputs for execute
signal upper_immediate_valueD:std_logic_vector(19 downto 0);
signal read_address1D,read_address2D,write_addressD:std_logic_vector(address_width-1 downto 0);
signal extended_valueD,pc_OUTPLUS4D,int_operand1D,int_operand2D,fp_operand1D,fp_operand2D:std_logic_vector(data_width-1 downto 0);

--outputs of execute stage are inputs to memory stage 
signal int_readE,fp_readE,C_aluE,C_mul_divE,C_fpuE,PC_OUTPLUS4E,PC_unconditionalE:std_logic_vector(data_width-1 downto 0);
signal upper_immediate_valueE:std_logic_vector(19 downto 0);
signal write_addressE:std_logic_vector(address_width-1 downto 0);
signal ALU_NEQ,ALU_EQ,ALU_LT,ALU_GE:std_logic;

--outputs of memory stage are inputs to write back stage
signal forwarding_dataM,write_back_dataM,ram_outM,nexT_pcM:std_logic_vector(data_width-1 downto 0);
signal write_addressM:std_logic_vector(address_width-1 downto 0);

--outputs of write back stage are used as inputs to write back address and inputs to register file data
signal write_back_valueW: std_logic_vector(data_width-1 downto 0);
signal write_addressW:std_logic_vector(address_width-1 downto 0);

--CONTROL SIGNALS 
signal IO_IN,IO_OUT,ld_intaddress,ld_service_routine,interrupt_ack,jump_andlink,branchneq,brancheq,branchlt,branchge,address_calculate,control_NEQ,control_EQ,control_LT,control_GE,fp_done,fp_enable,ram_rd,ram_wd,unsigned_compare:std_logic;
signal fp_op,alu_op:std_logic_vector(3 downto 0);
signal mul_div_op,ram_src:std_logic_vector(2 downto 0);
signal offset_src,int_srcB,fp_srcA:std_logic_vector(1 downto 0);
signal unconditional,enable_pc,enable_pc1,enable_pc2,enable_pc_src,int_wd,int_rd1,int_rd2,fp_wd,fp_rd1,fp_rd2,writeback_op:std_logic;
--control signals for pipeline 1
signal IO_IN1,IO_OUT1,ld_service_routine1,interrupt_ack1,jump_andlink1,branchneq1,brancheq1,branchlt1,branchge1,address_calculate1,control_NEQ1,control_EQ1,control_LT1,control_GE1,fp_enable1,ram_rd1,ram_wd1,unsigned_compare1:std_logic;
signal fp_op1,alu_op1:std_logic_vector(3 downto 0);
signal mul_div_op1,ram_src1:std_logic_vector(2 downto 0);
signal offset_src1,int_srcB1,fp_srcA1:std_logic_vector(1 downto 0);
signal unconditional1,int_wd1,fp_wd1,writeback_op1:std_logic;
--control signals for pipeline 2
signal IO_IN2,IO_OUT2,ld_service_routine2,interrupt_ack2,jump_andlink2,branchneq2,brancheq2,branchlt2,branchge2,control_NEQ2,control_EQ2,control_LT2,control_GE2,ALU_NEQ1,ALU_EQ1,ALU_LT1,ALU_GE1,ram_rd2,ram_wd2:std_logic;
signal ram_src2:std_logic_vector(2 downto 0);
signal unconditional2,writeback_op2,int_wd2,fp_wd2:std_logic;
--CONTROL SIGNALS FOR PIPELINE 3
signal IO_OUT3,interrupt_ack3,writeback_op3,int_wd3,fp_wd3:std_logic;
--output of processor 
signal out_data:std_logic_vector(data_width-1 downto 0);

begin 

THE_FETCH_STAGE:fetch_stage generic map(data_width,memory_address_width,address_width,instruction_simulation_file_directory,instruction_synthesis_file_directory,simulation)
port map(clk,rst,enable_pc,next_pcM,immediate_valueF,upper_immediate_valueF,read_address1F,read_address2F,write_addressF,func3F,func7F,pc_OUTPLUS4F,opcodeF);

THE_DECODE_STAGE:decode_stage generic map(data_width,address_width)
port map(clk,rst,interrupt_ack,ld_intaddress,int_wd3,int_rd1,int_rd2,fp_wd3,fp_rd1,fp_rd2,write_back_valueW,PC_OUTPLUS4F,
immediate_valueF,upper_immediate_valueF,read_address1F,read_address2F,write_addressW,write_addressF,
write_addressD,extended_valueD,upper_immediate_valueD,int_operand1D,int_operand2D,fp_operand1D,
fp_operand2D,PC_OUTPLUS4D);

THE_EXECUTE_STAGE:execute_stage generic map(data_width,address_width,opcode_length,mantissa_width,exponent_width)
port map(clk,rst,fp_enable1,unsigned_compare1,address_calculate1,int_operand1D,fp_operand1D,
int_operand2D,fp_operand2D,extended_valueD,PC_OUTPLUS4D,upper_immediate_valueD,
write_addressD,alu_op1,fp_op1,mul_div_op1,offset_src1,int_srcB1,fp_srcA1,
fp_done,write_addressE,ALU_NEQ,ALU_EQ,ALU_LT,ALU_GE,
C_aluE,C_mul_divE,C_fpuE,
PC_OUTPLUS4E,PC_unconditionalE);

THE_MEMORY_STAGE:memory_stage generic map(data_width,address_width,memory_address_width,data_simulation_file_directory,data_synthesis_file_directory,simulation)
port map(clk,rst,interrupt_ack2,ld_service_routine2,IO_IN2,ram_RD2,ram_WD2,ALU_NEQ,ALU_EQ,ALU_LT,ALU_GE,control_NEQ2,control_EQ2,control_LT2,
control_GE2,unconditional2,branchneq2,brancheq2,branchlt2,branchge2,enable_pc_src,jump_andlink2,int_readE,fp_readE,I_DATA,C_aluE,C_fpuE,C_mul_divE,PC_OUTPLUS4E,PC_unconditionalE,
upper_immediate_valueE,write_addressE,ram_src2,write_back_dataM,ram_outM,write_addressM,next_pcM);

THE_WRITEBACK_STAGE:write_back_stage generic map(data_width,address_width)
port map(interrupt_ack3,write_back_dataM,ram_outM,writeback_op3,write_addressM,write_addressW,write_back_valueW);

CONTROL:RV32IMF_control port map(clk,rst,int,fp_done,opcodeF,func7F,func3F,control_NEQ,
control_EQ,control_LT,control_GE,fp_enable,ram_rd,ram_wd,unsigned_compare,jump_andlink,fp_op,
alu_op,mul_div_op,offset_src,int_srcB,fp_srcA,ram_src,
unconditional,int_wd,int_rd1,int_rd2,fp_wd,fp_rd1,fp_rd2,writeback_op,address_calculate,branchneq,
brancheq,branchlt,branchge,enable_pc,enable_pc_src,interrupt_ack,ld_intaddress,ld_service_routine,IO_IN,IO_OUT);

--WE REGISTER OUTPUT WHEN USING A SPECIFIC INSTRUCTION 
OUTPUT_DATA:process(clk,rst,IO_OUT3)
begin 
if(rst='1')then OUT_DATA<=(others=>'0');
elsif(clk'event and clk='1')then 
if(IO_OUT3='1')then OUT_DATA<=RAM_OUTM;
end if;
end if;
end process;

--output of the design 
O_DATA<=OUT_DATA;

--THESE SIGNALS ARE TAKEN INDEPENDENTLY TO RESPECT PIN COUNT :)
process(clk,rst)
begin 
if(rst='1') then int_readE<=(others=>'0');fp_readE<=(others=>'0');upper_immediate_valueE<=(others=>'0');
elsif(clk'event and clk='1') then upper_immediate_valueE<=upper_immediate_valueD;
int_readE<=int_operand1D;fp_readE<=fp_operand1D;
end if;
end process;

--PIPELINE 1 OUTPUTS ARE INTO EXECUTE STAGE OR TO PIPELINE 2
CONTROL_PIPELINE1:process(clk,rst,enable_pc2)
begin
--RST AND PC_ENABLE ARE USED TO RST CONTROL PIPELINE WHEN USING THE FPU :) (took 2 days to spaghetti code xD but it works perfectly)
if(enable_pc2='1' or rst='1')then
IO_OUT1<='0';
IO_IN1<='0';
ld_service_routine1<='0';
interrupt_ack1<='0'; 
jump_andlink1<='0';
enable_pc1<='0';
branchneq1<='0';
brancheq1<='0';
branchlt1<='0';
branchge1<='0';
address_calculate1<='0';
control_nEQ1<='0';
control_EQ1<='0';
control_LT1<='0';
control_GE1<='0';
fp_enable1<='0';
ram_rd1<='0';
ram_WD1<='0';
unsigned_compare1<='0';
fp_op1<=(others=>'0');
alu_op1<=(others=>'0');
mul_div_op1<=(others=>'0');
offset_src1<=(others=>'0');
int_srcB1<=(others=>'0');
fp_srcA1<=(others=>'0');
ram_src1<=(others=>'0');
unconditional1<='0';
int_wd1<='0';
fp_wd1<='0';
writeback_op1<='0';
elsif(clk'event and clk='1') then
--USED TO STALL THE CONTROL SIGNALS IF FPU IS USED UNTILL THE DONE SIGNAL IS HIGH
if(fp_enable1=fp_done) then
IO_OUT1<=IO_OUT;
IO_IN1<=IO_IN;
ld_service_routine1<=ld_service_routine;
interrupt_ack1<=interrupt_ack;
jump_andlink1<=jump_andlink;
enable_pc1<=enable_pc;
branchneq1<=branchneq;
brancheq1<=brancheq;
branchlt1<=branchlt;
branchge1<=branchge;
address_calculate1<=address_calculate;
control_nEQ1<=control_neq;
control_EQ1<=control_eq;
control_LT1<=control_LT;
control_GE1<=control_GE;
fp_enable1<=fp_enable;
ram_rd1<=ram_rd;
ram_WD1<=ram_wd;
unsigned_compare1<=unsigned_compare;
fp_op1<=fp_op;
alu_op1<=alu_op;
mul_div_op1<=mul_div_op;
offset_src1<=offset_src;
int_srcB1<=int_srcB;
fp_srcA1<=fp_srcA;
ram_src1<=ram_src;
unconditional1<=unconditional;
int_wd1<=int_wd;
fp_wd1<=fp_wd;
writeback_op1<=writeback_op;
end if;END IF;
end process;

--PIPELINE 2 OUTPUTS ARE INTO MEMORY STAGE OR TO PIPELINE 3
CONTROL_PIPELINE2:process(clk)
begin 

if(clk'event and clk='1') then
IO_OUT2<=IO_OUT1;
IO_IN2<=IO_IN1;
ld_service_routine2<=ld_service_routine1;
interrupt_ack2<=interrupt_ack1;
jump_andlink2<=jump_andlink1;
enable_pc2<=enable_pc1;
branchneq2<=branchneq1;
brancheq2<=brancheq1;
branchlt2<=branchlt1;
branchge2<=branchge1;
control_nEQ2<=control_neq1;
control_EQ2<=control_eq1;
control_LT2<=control_LT1;
control_GE2<=control_GE1;
ram_rd2<=ram_rd1;
ram_WD2<=ram_wd1;
ram_src2<=ram_src1;
unconditional2<=unconditional1;
int_wd2<=int_wd1;
fp_wd2<=fp_wd1;
writeback_op2<=writeback_op1;
end if;
end process; 
--PIPELINE 3 OUTPUTS ARE INTO DECODE TO WRITE ADDRESS OR TO OUTPUT DATA
CONTROL_PIPELINE3:process(clk)
begin

if(clk'event and clk='1') then
IO_OUT3<=IO_OUT2; 
interrupt_ack3<=interrupt_ack2;
int_wd3<=int_wd2;
fp_wd3<=fp_wd2;
writeback_op3<=writeback_op2;
end if;
end process;

end arch;