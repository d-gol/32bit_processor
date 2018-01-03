library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;
use std.textio.all;    
use ieee.std_logic_textio.all;

entity InstrDecode is
 port
 (
	  clk : in  std_logic;
	  reset : in  std_logic;
	  stall : in std_logic;
	  pc_record_if_id: in Record_PC;
	  pc_pred_if_id: in std_logic_vector(A_BUS_WIDTH downto 0);
	  rec_wb_id: in Record_wb_id;
	  instruction_mem_in: in std_logic_vector(D_BUS_WIDTH downto 0); -- instrukcija koja se dobija sa te adrese
	  hazard_rec_hu_id: in Record_hazard_HU_ID;
	  flush: in std_logic;
	  
	  hazard_rec_id_hu: out Record_hazard_ID_HU; -- za hazard jedinicu
	  pc_record_id_ex: out Record_PC;
	  instr_rec_id_ex : out Record_instr;
	  stall_id_hu : out std_logic
 );
end InstrDecode;

architecture ArchInstrDecode of InstrDecode is
	signal adr_rd   : std_logic_vector(4 downto 0); --adr register destination 1
	signal data_rd_in : std_logic_vector(D_BUS_WIDTH downto 0); -- Iz wb faze
	signal data_rs_1_out : std_logic_vector(D_BUS_WIDTH downto 0); --iz reg fajla
	signal data_rs_2_out : std_logic_vector(D_BUS_WIDTH downto 0);
	signal instr_rec_id_ex_next: Record_instr;
	signal instr_rec_id_ex_reg: Record_instr;
	signal pc_record_id_ex_next: Record_PC;
	signal pc_record_id_ex_reg: Record_PC;
begin
	RegFile: entity work.RegisterFile(archRegisterFile) port map (instr_rec_id_ex_next.adr_rs_1, instr_rec_id_ex_next.adr_rs_2, adr_rd, rec_wb_id.data, rec_wb_id.reg_adr, rec_wb_id.wr_reg, data_rs_1_out, data_rs_2_out);
	
	process(adr_rd, stall, flush, pc_pred_if_id, pc_record_if_id, pc_record_id_ex_reg, data_rs_1_out, data_rs_2_out, instruction_mem_in, hazard_rec_hu_id, instr_rec_id_ex_reg) is
	variable adr_rs_1 : std_logic_vector(4 downto 0); --adr register source 1
	variable adr_rs_2 : std_logic_vector(4 downto 0);
	begin
		--inicijalizacija
		
		adr_rs_1 := "ZZZZZ";
		adr_rs_2 := "ZZZZZ";
		adr_rd <= "ZZZZZ";
		
		instr_rec_id_ex_next.opcode <= "ZZZZZZ";
		instr_rec_id_ex_next.adr_rs_1 <= "ZZZZZ";
		instr_rec_id_ex_next.adr_rs_2 <= "ZZZZZ";
		instr_rec_id_ex_next.data_rs_1 <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
		instr_rec_id_ex_next.data_rs_2 <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
		instr_rec_id_ex_next.adr_rd <= "ZZZZZ";
		instr_rec_id_ex_next.imm16 <= "ZZZZZZZZZZZZZZZZ";
		instr_rec_id_ex_next.imm5 <= "ZZZZZ";
		instr_rec_id_ex_next.ready_exec <= '0';
		instr_rec_id_ex_next.adr_mem <=   "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
		instr_rec_id_ex_next.jmp_happened <= '0';
		instr_rec_id_ex_next.overflow <= '0';
		
		instr_rec_id_ex_next.add<='0'; instr_rec_id_ex_next.sub<='0'; instr_rec_id_ex_next.addi<='0'; instr_rec_id_ex_next.subi<='0'; instr_rec_id_ex_next.and_o<='0';
		instr_rec_id_ex_next.or_o<='0'; instr_rec_id_ex_next.xor_o<='0'; instr_rec_id_ex_next.not_o<='0'; instr_rec_id_ex_next.shl<='0'; instr_rec_id_ex_next.shr<='0';
		instr_rec_id_ex_next.sar<='0'; instr_rec_id_ex_next.ror_o<='0'; instr_rec_id_ex_next.rol_o<='0'; instr_rec_id_ex_next.load<='0'; instr_rec_id_ex_next.store<='0';
		instr_rec_id_ex_next.mov<='0'; instr_rec_id_ex_next.movi<='0'; instr_rec_id_ex_next.jmp<='0'; instr_rec_id_ex_next.jsr<='0'; instr_rec_id_ex_next.rts<='0';
		instr_rec_id_ex_next.halt<='0'; instr_rec_id_ex_next.beq<='0'; instr_rec_id_ex_next.bnq<='0'; instr_rec_id_ex_next.bgt<='0'; instr_rec_id_ex_next.blt<='0';
		instr_rec_id_ex_next.ble<='0'; instr_rec_id_ex_next.bge<='0'; instr_rec_id_ex_next.push<='0'; instr_rec_id_ex_next.pop<='0';
		
		instr_rec_id_ex_next.wr_reg <= '0';
		instr_rec_id_ex_next.wr_mem <= '0';
		instr_rec_id_ex_next.rd_mem <= '0';
		
		instr_rec_id_ex_next.flush <= '0';
		instr_rec_id_ex_next.flush_jmp <= '0';
		instr_rec_id_ex_next.instr_jmp <= '0';
		
		hazard_rec_id_hu.reg_1 <= "ZZZZZ";
		hazard_rec_id_hu.reg_2 <= "ZZZZZ";
		hazard_rec_id_hu.rd_reg_1 <= '0';
		hazard_rec_id_hu.rd_reg_2 <= '0';
		stall_id_hu <= '0';
				
		instr_rec_id_ex_next.opcode <= instruction_mem_in(A_BUS_WIDTH downto A_BUS_WIDTH-5);
		
		--odredjivanje tipa instrukcije
		case instruction_mem_in(A_BUS_WIDTH downto A_BUS_WIDTH - 5) is
		
		--type 1
		
			--load
			when "000000" =>  instr_rec_id_ex_next.load<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									instr_rec_id_ex_next.wr_mem<='0';
									instr_rec_id_ex_next.rd_mem<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.imm16 <= instruction_mem_in(15 downto 0);
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
			--addi						
			when "001100" =>  instr_rec_id_ex_next.addi<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.imm16 <= instruction_mem_in(15 downto 0);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
			--subi						
			when "001101" =>  instr_rec_id_ex_next.subi<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.imm16 <= instruction_mem_in(15 downto 0);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									
		--type 2
		
			--store
			when "000001" =>  instr_rec_id_ex_next.store<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									instr_rec_id_ex_next.wr_mem<='1';
									instr_rec_id_ex_next.rd_mem<='0';
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.imm16  <= instruction_mem_in(25 downto 21) & instruction_mem_in(10 downto 0);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';

			--beq
			when "101000" =>  instr_rec_id_ex_next.beq<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.imm16  <= instruction_mem_in(25 downto 21) & instruction_mem_in(10 downto 0);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.instr_jmp <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
			--bnq
			when "101001" =>  instr_rec_id_ex_next.bnq<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.imm16  <= instruction_mem_in(25 downto 21) & instruction_mem_in(10 downto 0);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.instr_jmp <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
			--bgt
			when "101010" =>  instr_rec_id_ex_next.bgt<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.imm16  <= instruction_mem_in(25 downto 21) & instruction_mem_in(10 downto 0);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.instr_jmp <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
			--blt
			when "101011" =>  instr_rec_id_ex_next.blt<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.imm16  <= instruction_mem_in(25 downto 21) & instruction_mem_in(10 downto 0);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.instr_jmp <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
			--bge
			when "101100" =>  instr_rec_id_ex_next.bge<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.imm16  <= instruction_mem_in(25 downto 21) & instruction_mem_in(10 downto 0);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.instr_jmp <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
			--ble
			when "101101" =>  instr_rec_id_ex_next.ble<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.imm16  <= instruction_mem_in(25 downto 21) & instruction_mem_in(10 downto 0);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.instr_jmp <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
								  
		--type 3
		
			--add
			when "001000" => 	instr_rec_id_ex_next.add<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
			--sub						
			when "001001" =>  instr_rec_id_ex_next.sub<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
			--and
			when "010000" =>  instr_rec_id_ex_next.and_o<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
			--or
			when "010001" =>  instr_rec_id_ex_next.or_o<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
			--xor
			when "010010" =>  instr_rec_id_ex_next.xor_o<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(20 downto 16);
									adr_rs_2 := instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_2 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									hazard_rec_id_hu.rd_reg_2 <= '1';
			--not
			when "010011" =>  instr_rec_id_ex_next.not_o<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
													
		--type 4
		
			--shr
			when "011001" => 	instr_rec_id_ex_next.shr<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.imm5 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
			--shl
			when "011000" =>  instr_rec_id_ex_next.shl<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.imm5 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
			--sar
			when "011010" =>  instr_rec_id_ex_next.sar<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.imm5 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
			--rol
			when "011011" =>  instr_rec_id_ex_next.rol_o<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.imm5 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
			--ror
			when "011100" =>  instr_rec_id_ex_next.ror_o<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.imm5 <= instruction_mem_in(15 downto 11);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
		
		--type 5
		
			--mov
			when "000100" =>  instr_rec_id_ex_next.mov<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									adr_rs_1 := instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									
		--type 6
		
			--movi 
			when "000101" =>  instr_rec_id_ex_next.movi<='1';
									instr_rec_id_ex_next.wr_reg<='1';
									adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.imm16 <= instruction_mem_in(15 downto 0);
									instr_rec_id_ex_next.ready_exec <= '1';
								  
		--type 7
			
			--jmp
			when "100000" => 	instr_rec_id_ex_next.jmp<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									adr_rs_1 := instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.imm16 <= instruction_mem_in(15 downto 0);
									instr_rec_id_ex_next.instr_jmp <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
			--jsr
			when "100001" =>  instr_rec_id_ex_next.jsr<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									adr_rs_1 := instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(25 downto 21);
									instr_rec_id_ex_next.imm16 <= instruction_mem_in(15 downto 0);
									instr_rec_id_ex_next.instr_jmp <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
									
		--type 8
		
			--rts
			when "100010" =>  instr_rec_id_ex_next.rts<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									instr_rec_id_ex_next.instr_jmp <= '1';
			--halt
			when "111111" =>  instr_rec_id_ex_next.halt<='1';
									instr_rec_id_ex_next.wr_reg<='0';
			
		--type 9
		
			--push
			when "100100" =>  instr_rec_id_ex_next.push<='1';
									instr_rec_id_ex_next.wr_reg<='0';
									adr_rs_1 := instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.adr_rs_1 <= instruction_mem_in(20 downto 16);
									instr_rec_id_ex_next.ready_exec <= '1';
									
									hazard_rec_id_hu.rd_reg_1 <= '1';
								  
		--type 10
		
			--pop
			when "100101" => instr_rec_id_ex_next.pop<='1';
								  instr_rec_id_ex_next.wr_reg<='1';
								  adr_rd <= instruction_mem_in(25 downto 21);
								  instr_rec_id_ex_next.adr_rd <= instruction_mem_in(25 downto 21);
								  
		--ostalo
			when others => --instr_rec_id_ex_next.halt<='1'; --privremeno
								instr_rec_id_ex_next.wr_reg<='0';
			
		end case;
		
		
		if(hazard_rec_hu_id.valid_1 = '0') then
			instr_rec_id_ex_next.data_rs_1 <= data_rs_1_out;
		else
			instr_rec_id_ex_next.data_rs_1 <= hazard_rec_hu_id.data_1;
		end if;
		
		if(hazard_rec_hu_id.valid_2 = '0') then
			instr_rec_id_ex_next.data_rs_2 <= data_rs_2_out;
		else
			instr_rec_id_ex_next.data_rs_2 <= hazard_rec_hu_id.data_2;
		end if;
		
		--hazard	
		hazard_rec_id_hu.reg_1 <= adr_rs_1;
		hazard_rec_id_hu.reg_2 <= adr_rs_2;
		hazard_rec_id_hu.wr_reg <= adr_rd;
	
		--pc record
		pc_record_id_ex_next <= pc_record_if_id;
		pc_record_id_ex_next.pc_pred <= pc_pred_if_id;	
		
		if(flush='1') then
			instr_rec_id_ex_next.flush_jmp <= '1';
		else
			if(stall = '1') then
				instr_rec_id_ex_next <= instr_rec_id_ex_reg;
				pc_record_id_ex_next <= pc_record_id_ex_reg;
				instr_rec_id_ex_next.flush <= '1';
				stall_id_hu <= '1';
			end if;
		end if;
		
	end process;

--izlaz
	instr_rec_id_ex <= instr_rec_id_ex_reg;
	pc_record_id_ex <= pc_record_id_ex_reg;
	
	process(clk)
	begin
		if(rising_edge(clk)) then
			if(reset='1')then
				
			else
				instr_rec_id_ex_reg <= instr_rec_id_ex_next;
				pc_record_id_ex_reg <= pc_record_id_ex_next;
			end if;
		end if;
	end process;
	
end ArchInstrDecode;