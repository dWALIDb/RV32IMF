--CONTROL UNIT HANDELS ALL THE VALUES DEPENDING ON THE OPCODE(INSTRUCTION)
--IT EVEN ENABLES PC EACH 5 CLOCK CYCLES EXECPT FOR WHEN FPU IS USED, IT STALLS UNTILL INSTRUCTION CALCULATION IS DONE TO COMPLETE
--INTERRPTS ARE DEFINED AS FOLLOWS:
--  INTERRPUTS ARE NOT ENABLED UNTILL WE USE ENABLE INTERRUPT ENABLE INSTRUCTION. IT IS SIMILAR TO JALR INSTRUCTION
--  	IT TAKES RD TO STORE INSTRUCTION INTERRUPTED IN THE SPECIFIED REGISTER, AND A OFFSET OF RS1 AND 12 BIT IMMEDIATE FOR INTERRUPT SERVICE ROUTINE 
--  	INTERRUPT ACKNOLEDGE IS HIGH(ONLY AT START OF INSTRUCTION START SO CYCLE COUNT=0), PC WILL BE STORED IN RD, THEN PC IS SET TO ISR AND INTERRUPTS ARE DISABLED
-- I/O IS HANDELED BY WRITING AND READING FROM MEMORY BY SPECIFIC INSTUCTIONS.
--INPUT INSTRUCTION IS ENCODED AS IF IT IS A STORE INSTRUCTION BUT THE RS1 FIELD IS SET TO 0 BECAUSE THE SOURCE IS INPUT FROM USER 
--OUTPUT INSTRUCTION IS ENCODED AS IF IT IS A LOAD INSTRUCTION BUT RD IS SET TO 0 BECAUSE THE DESTINATION IS REGISTERED TO THE USER 
library ieee;
use ieee.std_logic_1164.all;
use work.tools.all;

entity RV32IMF_control is 
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
);end RV32IMF_control;

architecture arch of RV32IMF_control is 
signal Wcontrol_NEQ,Wcontrol_EQ,Wcontrol_LT,Wcontrol_GE,Wfp_enable,Wram_rd,Wram_wd,Wunsigned_compare,Waddress_calculate,Wbranchneq,Wbrancheq,Wbranchlt,Wbranchge,Wld_service_routine,WIO_IN:std_logic:='0';
signal Wfp_op,Walu_op:std_logic_vector(3 downto 0):="0000";
signal Wmul_div_op,Wram_src:std_logic_vector(2 downto 0):="000";
signal Woffset_src,Wint_srcB,Wfp_srcA:std_logic_vector(1 downto 0):="00";
signal Wunconditional,Wint_wd,Wint_rd1,Wint_rd2,Wfp_wd,Wfp_rd1,Wfp_rd2,Wwriteback_op,Wpc_enable,Wpc_enable_src,Wjump_andlink,int_enable,Wld_intaddress,Winterrupt_ack,WIO_OUT:std_logic:='0';
signal cycle_count:integer range 0 to 4;
signal selected_opcode:std_logic_vector(6 downto 0);
begin

process(clk,rst,opcode,func3,func7,int)
begin

--we test opcodes then we test function fields depending on instructions  
if(rst='1') then 
Wcontrol_NEQ<='0';Wcontrol_EQ<='0';Wcontrol_LT<='0';Wcontrol_GE<='0';Wfp_enable<='0';Wld_service_routine<='0';WIO_IN<='0';WIO_OUT<='0';
Wram_rd<='0';Wram_wd<='0';Wunsigned_compare<='0';Wfp_op<=(others=>'0');Wbranchneq<='0';Wbrancheq<='0';Wbranchlt<='0';Wbranchge<='0';
Walu_op<=(others=>'0');Wmul_div_op<=(others=>'0');Woffset_src<=(others=>'0');Wint_srcB<=(others=>'0');
Wfp_srcA<=(others=>'0');Wram_src<=(others=>'0');Wld_intaddress<='0';
Wunconditional<='0';Wint_wd<='0';Wint_rd1<='0';Wint_rd2<='0';Wpc_enable_src<='0';Wjump_andlink<='0';int_enable<='0';
Wfp_wd<='0';Wfp_rd1<='0';Wfp_rd2<='0';Wwriteback_op<='0';Waddress_calculate<='0';cycle_count<=0;Wpc_enable<='0';Winterrupt_ack<='0';

elsif(clk'event and clk='0') then

	Wcontrol_NEQ<='0';Waddress_calculate<='0';Wbranchneq<='0';Wbrancheq<='0';Wbranchlt<='0';Wbranchge<='0';
	Wcontrol_EQ<='0';Wcontrol_LT<='0';Wcontrol_GE<='0';Wfp_enable<='0';Wld_service_routine<='0';
	Wram_rd<='0';Wram_wd<='0';Wunsigned_compare<='0';Wfp_op<=(others=>'0');WIO_IN<='0';WIO_OUT<='0';
	Walu_op<=(others=>'0');Wmul_div_op<=(others=>'0');Woffset_src<=(others=>'0');Wint_srcB<=(others=>'0');
	Wfp_srcA<=(others=>'0');Wram_src<=(others=>'0');
	Wunconditional<='0';Wint_wd<='0';Wint_rd1<='0';Wint_rd2<='0';Winterrupt_ack<='0';
	Wfp_wd<='0';Wfp_rd1<='0';Wfp_rd2<='0';Wwriteback_op<='0';Wjump_andlink<='0';Wld_intaddress<='0';
	
	--the opcode is changed when rcieving an interrupt 
	if(int='1' and int_enable='1' and cycle_count=4)then selected_opcode<="1111111";
	elsif(selected_opcode="1111111" and cycle_count/=4) then selected_opcode<="1111111"; 
	else selected_opcode<=opcode; end if;
	--enable and disable interrupts 
	if(opcode="0111111") then int_enable<='1';
	elsif(opcode="0011111" or (int='1' and int_enable='1' and selected_opcode="1111111")) then int_enable<='0';
	else int_enable<=int_enable;
	end if;
	
	case selected_opcode is 
	
	--LUI THE BEST INSTRUCTION IN MY OPINION AHAHAHA....when it works every thing becomes easier
		when"0110111"=>Wint_wd<='1';Wram_src<="011";Wwriteback_op<='0';
	--REGISTER ARITHMETIC OPERATIONS
		when"0110011"=> Wint_wd<='1'; Wint_rd1<='1'; Wint_rd2<='1'; Wram_src<="000"; Wwriteback_op<='0';
						if(func7(5)='0' and func3="000") then Walu_op<="0000";--add
						elsif(func7(5)='1' and func3="000") then Walu_op<="0001";--sub
						elsif(func7(5)='0' and func3="111") then Walu_op<="0010";--and
						elsif(func7(5)='0' and func3="110") then Walu_op<="0011";--or
						elsif(func7(5)='0' and func3="100") then Walu_op<="0100";--xor
						elsif(func7(5)='0' and func3="010") then Walu_op<="0101";--slt
						elsif(func7(5)='0' and func3="011") then Walu_op<="0110";--sltu
						elsif(func7(5)='0' and func3="001") then Walu_op<="0111";--sll
						elsif(func7(5)='0' and func3="101") then Walu_op<="1000";--srl
						elsif(func7(5)='1' and func3="101") then Walu_op<="1001";--sra
						end if;
	--REGISTER MULTIPLICATION OPERATIONS: they have the same opcode
						if(func7(0)='1' and func3="000") then Wram_src<="001";Wmul_div_op<="000";--mul
						elsif(func7(0)='1' and func3="001") then Wram_src<="001";Wmul_div_op<="010";--mulh
						elsif(func7(0)='1' and func3="010") then Wram_src<="001";Wmul_div_op<="011";--mulhSU
						elsif(func7(0)='1' and func3="011") then Wram_src<="001";Wmul_div_op<="001";--mulhU
						elsif(func7(0)='1' and func3="100") then Wram_src<="001";Wmul_div_op<="101";--div
						elsif(func7(0)='1' and func3="101") then Wram_src<="001";Wmul_div_op<="100";--divU
						elsif(func7(0)='1' and func3="110") then Wram_src<="001";Wmul_div_op<="111";--REM
						elsif(func7(0)='1' and func3="111") then Wram_src<="001";Wmul_div_op<="110";--REMU
						end if;
	--REGISTER-IMMEDIATE OPERATIONS: the shifts are gonna be the last 5-bits of the sign extended value
	--ALU considers least 5-bits of sign extended value
		when"0010011"=> Wint_wd<='1'; Wint_rd1<='1'; Wram_src<="000"; Wwriteback_op<='0';Wint_srcB<="10";--take extended input
						if(func3="000") then Walu_op<="0000";--addi
						elsif(func3="111") then Walu_op<="0010";--andi
						elsif(func3="110") then Walu_op<="0011";--ori
						elsif(func3="100") then Walu_op<="0100";--xori
						elsif(func3="010") then Walu_op<="0101";--slti
						elsif(func3="011") then Walu_op<="0110";--sltui
						elsif(func3="001") then Walu_op<="0111";--slli
						elsif(func7(5)='0' and func3="101") then Walu_op<="1000";--srli
						elsif(func7(5)='1' and func3="101") then Walu_op<="1001";--srai
						end if;
		--LOAD INTEGER REGISTER:ALU output has the address offset
		when"0000011"=> if(func3="010") then Wram_rd<='1';Wint_wd<='1';Wint_rd1<='1';Wint_srcB<="10";Wwriteback_op<='1'; end if;
		--STORE INTEGER REGISTER:address is calculated then multiplexed with alu output 
		when"0100011"=> if(func3="010") then Wram_wd<='1';Wint_rd1<='1';Wint_rd2<='1';Wram_src<="100";Waddress_calculate<='1';end if;
		--BRANCH INSTRUCTIONS:address calculation starts from PC+4 so start calculating from next instruction
		when"1100011"=> Wint_rd1<='1';Wint_rd2<='1';Woffset_src<="00";Wunsigned_compare<='0';
						if(func3="000") then Wbrancheq<='1';Wcontrol_EQ<='1';
						elsif(func3="001") then Wbranchneq<='1'; Wcontrol_NEQ<='1';
						elsif(func3="100") then Wbranchlt<='1'; Wcontrol_LT<='1';
						elsif(func3="101") then Wbranchge<='1'; Wcontrol_GE<='1';
						elsif(func3="110") then Wunsigned_compare<='1';Wbranchlt<='1'; Wcontrol_LT<='1';
						elsif(func3="111") then Wunsigned_compare<='1';Wbranchge<='1'; Wcontrol_GE<='1';
						end if;
		--LOAD FLOATING POINT REGISTER:alu output has the address offset²
		when"0000111"=>Wram_rd<='1';Wfp_wd<='1';Wint_rd1<='1';Wint_srcB<="10";Wwriteback_op<='1';Wram_src<="010";
		--STORE FLOATING POINT REGISTER:address is calculated and the multiplexed with alu output
		when"0100111"=>Wram_wd<='1';Wfp_rd1<='1';Wint_rd2<='1';Wram_src<="101";Waddress_calculate<='1';
		--FLOATING POINT OPERATIONS 
		when"1010011"=>Wfp_wd<='1';Wfp_rd1<='1';Wfp_rd2<='1';Wram_src<="010";Wwriteback_op<='0';Wfp_enable<='1';
						if(func7="0001000") then Wfp_op<="0000";--mul
						elsif(func7="0001100") then Wfp_op<="0001";--div
						elsif(func7="0000000") then Wfp_op<="0010";--add
						elsif(func7="0010100" and func3="000") then Wfp_op<="0100";--min
						elsif(func7="0010100" and func3="001") then Wfp_op<="0011";--max
						elsif(func7="1100000" ) then Wfp_op<="0110";Wint_wd<='1';Wfp_wd<='0';Wfp_rd1<='1';Wfp_rd2<='0';--FCVT.W.S converts fp number to integer 
						elsif(func7="1101000" ) then Wfp_op<="0101";Wint_rd1<='1';Wfp_rd1<='0';Wfp_rd2<='0';Wfp_srcA<="01";--FCVT.S.W converts integer to fp number
						elsif(func7="1111000" and func3="000") then Wint_rd1<='1';Wfp_rd1<='0';Wfp_rd2<='0';Wfp_enable<='0';Wram_src<="000";--FMV.W.X to move integer reg to fp reg
						elsif(func7="1110000" and func3="000") then Wfp_enable<='0';Wfp_rd2<='0';Wfp_wd<='0';Wint_wd<='1';Wram_src<="101";--FMV.X.W to move fp reg to integer reg
						elsif(func7="0010000" and func3="000") then Wfp_enable<='0';Wfp_rd2<='0';Wram_src<="101";--FSGNJ.S to move data between registers RS2 is not used (FMV)
						elsif(func7="0010000" and func3="001") then Wfp_op<="1000";Wfp_rd2<='0';--FSGNJN.S to get negative of data sign(FNEG)
						elsif(func7="0010000" and func3="010") then Wfp_op<="0111";Wfp_rd2<='0';--FSGNJX.S to get absolute value of data(FABS)
						end if;
						--they follow the table in RISCV spec 2.2
		--INSTRUCTIONS THAT AFFECT: PC JAR JARL AUPIC
		--JALR:set pc to register+immediate offset and store the next instruction in a destination register
		when"1100111"=>if (func3="000") then Wram_src<="110";Wint_rd1<='1';Wint_srcB<="10";Wint_wd<='1';Wjump_andlink<='1';Walu_op<="0000";end if;
		--JAL:set pc to pc+4+20-bit relative immediate offset
		when"1101111"=>Wram_src<="110";Wint_wd<='1';Wunconditional<='1';Woffset_src<="01";
		--AUPIC:set a destination register to have the value of PC+20-bit upper immediate
		when"0010111"=>Wint_wd<='1';Woffset_src<="11";Wram_src<="111";
		--INTERRUPT STATE TO PUT PC IN REGISTER  AND PUT INTERRUPT SERVICE ROUTINE IN PC
		when"1111111"=>Wint_wd<='1';Wram_src<="110";Winterrupt_ack<='1';
		--INTERRUPT ENABLE ISR=RS1+12bit immediate offset
		when"0111111"=>int_enable<='1';Wint_rd1<='1';Wint_srcB<="10";Wld_intaddress<='1';Wld_service_routine<='1';
		--INTERRUPT DISABLE 
		WHEN"0011111"=>int_enable<='0';
		--IN_DATA:IO_IN USED TO INPUT TO RAM FROM USER just like the store word but for IO RS1 field is 0 and the others are the same
		when"1110111"=>Wram_wd<='1';Wram_src<="000";WIO_IN<='1';Wram_src<="100";Waddress_calculate<='1';
		--OUT_DATA:used to output data from ram to IO_regiser used like load instruction but for io alu has calculated address and RD is ZERO
		when"0001000"=> Wram_rd<='1';Wint_srcB<="10";Wwriteback_op<='1';WIO_OUT<='1';
		--NOTHING WILL BE DONE AND EVERY THING IS SET TO "0"
		when others=>null;
end case;

	if(Wfp_enable='1' and fp_done='0'and cycle_count<3 and cycle_count>0) then Wpc_enable<='0';Wpc_enable_src<='0';
	elsif(Wfp_enable='1' and fp_done='1' and cycle_count<3 and cycle_count>0) then Wpc_enable<='0';cycle_count<=4;Wpc_enable_src<='1';
	elsif(cycle_count=3) then Wpc_enable_src<='1';cycle_count<=cycle_count+1;
	elsif(cycle_count=4) then Wpc_enable<='1';cycle_count<=0;Wpc_enable_src<='0';
	else Wpc_enable<='0';cycle_count<=cycle_count+1;Wpc_enable_src<='0';
	end if;
end if;
end process;
control_NEQ<=Wcontrol_NEQ;address_calculate<=Waddress_calculate;pc_enable<=Wpc_enable;pc_enable_src<=Wpc_enable_src;
control_EQ<=Wcontrol_EQ;control_LT<=Wcontrol_LT;control_GE<=Wcontrol_GE;fp_enable<=Wfp_enable;IO_IN<=WIO_IN;IO_OUT<=WIO_OUT;
ram_rd<=Wram_rd;ram_wd<=Wram_wd;unsigned_compare<=Wunsigned_compare;fp_op<=Wfp_op;branchneq<=Wbranchneq;brancheq<=Wbrancheq;branchlt<=Wbranchlt;branchge<=Wbranchge;
alu_op<=Walu_op;mul_div_op<=Wmul_div_op;offset_src<=Woffset_src;int_srcB<=Wint_srcB;ld_service_routine<=Wld_service_routine;
fp_srcA<=Wfp_srcA;ram_src<=Wram_src;interrupt_ack<=Winterrupt_ack;
unconditional<=Wunconditional;int_wd<=Wint_wd;int_rd1<=Wint_rd1;int_rd2<=Wint_rd2;ld_intaddress<=Wld_intaddress;
fp_wd<=Wfp_wd;fp_rd1<=Wfp_rd1;fp_rd2<=Wfp_rd2;writeback_op<=Wwriteback_op;jump_andlink<=Wjump_andlink;
end arch;