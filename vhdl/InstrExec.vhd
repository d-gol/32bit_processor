library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity InstrExec is
	port
	(
		clk : in std_logic;
	   reset : in  std_logic;
		pc_record_id_ex : in Record_PC;
		instr_rec_id_ex : in Record_instr;
		flush: in std_logic;
		
		hazard_rec_ex_hu: out Record_hazard_EX_MEM_WB_HU;
		result_ex_mem   : out std_logic_vector(D_BUS_WIDTH downto 0);
		pc_record_ex_mem : out Record_PC;
		instr_rec_ex_mem : out Record_instr;
		pred_succ : out std_logic
	);
end InstrExec;

architecture ArchInstrExec of InstrExec is
	signal result_ex_mem_reg: std_logic_vector(D_BUS_WIDTH downto 0);
	signal result_ex_mem_next: std_logic_vector(D_BUS_WIDTH downto 0);
	signal instr_rec_ex_mem_reg: Record_instr;
	signal instr_rec_ex_mem_next: Record_instr;
	signal pc_record_ex_mem_reg: Record_PC;
	signal pc_record_ex_mem_next: Record_PC;
	signal real_jmp_adr: std_logic_vector(A_BUS_WIDTH downto 0);
	signal pred_succ_next: std_logic;
	signal pred_succ_reg: std_logic;

begin
		
	process(flush, instr_rec_id_ex, pc_record_id_ex, real_jmp_adr) is
	variable adr_load_store: std_logic_vector(A_BUS_WIDTH downto 0);
	begin
		pc_record_ex_mem_next <= pc_record_id_ex;
		pred_succ_next <= '0';
		real_jmp_adr <= std_logic_vector(to_unsigned(0, 32));
		
		hazard_rec_ex_hu.ready_data <= '0';
		hazard_rec_ex_hu.wr_dst_reg <= '0';
		hazard_rec_ex_hu.dst_reg <= "ZZZZZ";
		hazard_rec_ex_hu.data <= std_logic_vector(to_unsigned(0, 32));
		hazard_rec_ex_hu.flush <= '0';
		
		instr_rec_ex_mem_next <= instr_rec_id_ex;
		result_ex_mem_next <= std_logic_vector(to_unsigned(0,32));
		
		if(instr_rec_id_ex.flush_jmp='1' or flush='1') then
			instr_rec_ex_mem_next.flush_jmp <= '1';
			hazard_rec_ex_hu.flush <= '1';
		else
			if(instr_rec_id_ex.flush = '1') then
				hazard_rec_ex_hu.flush <= '1';
			else
				instr_rec_ex_mem_next <= instr_rec_id_ex;
				hazard_rec_ex_hu.flush <= '0';
				result_ex_mem_next <= std_logic_vector(to_unsigned(0,32)); --dummy
				
				--add
				if(instr_rec_id_ex.add='1') then
					result_ex_mem_next <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) + signed(instr_rec_id_ex.data_rs_2) );
					hazard_rec_ex_hu.data <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) + signed(instr_rec_id_ex.data_rs_2) );
				end if;
				
				--sub
				if(instr_rec_id_ex.sub='1') then
					result_ex_mem_next <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) - signed(instr_rec_id_ex.data_rs_2) );
					hazard_rec_ex_hu.data <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) - signed(instr_rec_id_ex.data_rs_2) );
				end if;
				
				--addi
				if(instr_rec_id_ex.addi='1') then
					result_ex_mem_next <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) + signed(instr_rec_id_ex.imm16) );
					hazard_rec_ex_hu.data <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) + signed(instr_rec_id_ex.imm16) );
				end if;
				
				--subi
				if(instr_rec_id_ex.subi='1') then
					result_ex_mem_next <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) - signed(instr_rec_id_ex.imm16) );
					hazard_rec_ex_hu.data <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) - signed(instr_rec_id_ex.imm16) );
				end if;
				
				--shr
				if(instr_rec_id_ex.shr='1') then
					result_ex_mem_next <= std_logic_vector(shift_right(unsigned(instr_rec_id_ex.data_rs_1), to_integer(unsigned(instr_rec_id_ex.imm5))));
					hazard_rec_ex_hu.data <= std_logic_vector(shift_right(unsigned(instr_rec_id_ex.data_rs_1), to_integer(unsigned(instr_rec_id_ex.imm5))));
				end if;
				
				--shl
				if(instr_rec_id_ex.shl='1') then
					result_ex_mem_next <= std_logic_vector(shift_left(unsigned(instr_rec_id_ex.data_rs_1), to_integer(unsigned(instr_rec_id_ex.imm5))));
					hazard_rec_ex_hu.data <= std_logic_vector(shift_left(unsigned(instr_rec_id_ex.data_rs_1), to_integer(unsigned(instr_rec_id_ex.imm5))));
				end if;
				
				--sar
				if(instr_rec_id_ex.sar='1') then
					result_ex_mem_next <= std_logic_vector(shift_right(signed(instr_rec_id_ex.data_rs_1), to_integer(unsigned(instr_rec_id_ex.imm5))));
					hazard_rec_ex_hu.data <= std_logic_vector(shift_right(signed(instr_rec_id_ex.data_rs_1), to_integer(unsigned(instr_rec_id_ex.imm5))));
				end if;
				
				--ror
				if(instr_rec_id_ex.ror_o='1') then
					result_ex_mem_next <= std_logic_vector(rotate_right(signed(instr_rec_id_ex.data_rs_1), to_integer(unsigned(instr_rec_id_ex.imm5))));
					hazard_rec_ex_hu.data <= std_logic_vector(rotate_right(signed(instr_rec_id_ex.data_rs_1), to_integer(unsigned(instr_rec_id_ex.imm5))));
				end if;
				
				--rol
				if(instr_rec_id_ex.rol_o='1') then
					result_ex_mem_next <= std_logic_vector(rotate_left(signed(instr_rec_id_ex.data_rs_1), to_integer(unsigned(instr_rec_id_ex.imm5))));
					hazard_rec_ex_hu.data <= std_logic_vector(rotate_left(signed(instr_rec_id_ex.data_rs_1), to_integer(unsigned(instr_rec_id_ex.imm5))));
				end if;
				
				--and
				if(instr_rec_id_ex.and_o='1') then
					result_ex_mem_next <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) and signed(instr_rec_id_ex.data_rs_2) );
					hazard_rec_ex_hu.data <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) and signed(instr_rec_id_ex.data_rs_2) );
				end if;
				
				--or
				if(instr_rec_id_ex.or_o='1') then
					result_ex_mem_next <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) or signed(instr_rec_id_ex.data_rs_2) );
					hazard_rec_ex_hu.data <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) or signed(instr_rec_id_ex.data_rs_2) );
				end if;
				
				--xor
				if(instr_rec_id_ex.xor_o='1') then
					result_ex_mem_next <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) xor signed(instr_rec_id_ex.data_rs_2) );
					hazard_rec_ex_hu.data <= std_logic_vector( signed(instr_rec_id_ex.data_rs_1) xor signed(instr_rec_id_ex.data_rs_2) );
				end if;
				
				--not
				if(instr_rec_id_ex.not_o='1') then
					result_ex_mem_next <= std_logic_vector(not(signed(instr_rec_id_ex.data_rs_1)));
					hazard_rec_ex_hu.data <= std_logic_vector(not(signed(instr_rec_id_ex.data_rs_1)));
				end if;
				
				--movi
				if(instr_rec_id_ex.movi='1') then
					result_ex_mem_next <= "0000000000000000" & std_logic_vector(signed(instr_rec_id_ex.imm16));
					hazard_rec_ex_hu.data <= "0000000000000000" & std_logic_vector(signed(instr_rec_id_ex.imm16));
				end if;
				
				--mov
				if(instr_rec_id_ex.mov='1') then
					result_ex_mem_next <= std_logic_vector(signed(instr_rec_id_ex.data_rs_1));
					hazard_rec_ex_hu.data <= std_logic_vector(signed(instr_rec_id_ex.data_rs_1));
				end if;
				
				--store
				if(instr_rec_id_ex.store='1') then
					result_ex_mem_next <= std_logic_vector(signed(instr_rec_id_ex.data_rs_2));
					hazard_rec_ex_hu.data <= std_logic_vector(signed(instr_rec_id_ex.data_rs_2));
					
					adr_load_store := std_logic_vector(to_unsigned(to_integer(unsigned(instr_rec_id_ex.data_rs_1)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
					instr_rec_ex_mem_next.adr_mem <= adr_load_store;
					if(unsigned(adr_load_store) > to_unsigned(DATA_MEM_SIZE, A_BUS_WIDTH+1)) then
						instr_rec_ex_mem_next.overflow <= '1';
					end if;
				end if;
				
				--load
				if(instr_rec_id_ex.load='1') then
					result_ex_mem_next <= std_logic_vector(signed(instr_rec_id_ex.data_rs_2));
					hazard_rec_ex_hu.data <= std_logic_vector(signed(instr_rec_id_ex.data_rs_2));
					
					adr_load_store := std_logic_vector(to_unsigned(to_integer(unsigned(instr_rec_id_ex.data_rs_1)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
					instr_rec_ex_mem_next.adr_mem <= adr_load_store;
					if(unsigned(adr_load_store) > to_unsigned(DATA_MEM_SIZE, A_BUS_WIDTH+1)) then
						instr_rec_ex_mem_next.overflow <= '1';
					end if;
				end if;
				
				--push
				if(instr_rec_id_ex.push='1') then
					result_ex_mem_next <= std_logic_vector(signed(instr_rec_id_ex.data_rs_1));
					hazard_rec_ex_hu.data <= std_logic_vector(signed(instr_rec_id_ex.data_rs_1));
				end if;
				
				--jmp
				if(instr_rec_id_ex.jmp='1') then
					--real_jmp_adr <= std_logic_vector(unsigned(instr_rec_id_ex.data_rs_1) + unsigned(instr_rec_id_ex.imm16));
					real_jmp_adr <= std_logic_vector(to_unsigned(to_integer(unsigned(instr_rec_id_ex.data_rs_1)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
					--result_ex_mem_next <= std_logic_vector(unsigned(instr_rec_id_ex.data_rs_1) + unsigned(instr_rec_id_ex.imm16)); --salje se adresa kao rezutat mem fazi
					result_ex_mem_next <= std_logic_vector(to_unsigned(to_integer(unsigned(instr_rec_id_ex.data_rs_1)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
				end if;
				
				--jsr
				if(instr_rec_id_ex.jsr='1') then
					--real_jmp_adr <= std_logic_vector(unsigned(instr_rec_id_ex.data_rs_1) + unsigned(instr_rec_id_ex.imm16));
					real_jmp_adr <= std_logic_vector(to_unsigned(to_integer(unsigned(instr_rec_id_ex.data_rs_1)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
					--result_ex_mem_next <= std_logic_vector(unsigned(instr_rec_id_ex.data_rs_1) + unsigned(instr_rec_id_ex.imm16)); --salje se adresa kao rezutat mem fazi
					result_ex_mem_next <= std_logic_vector(to_unsigned(to_integer(unsigned(instr_rec_id_ex.data_rs_1)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
				end if;
				
				--beq
				if(instr_rec_id_ex.beq='1') then
					result_ex_mem_next <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(signed(instr_rec_id_ex.imm16)),32));
					
					if(instr_rec_id_ex.data_rs_1 = instr_rec_id_ex.data_rs_2) then
						real_jmp_adr <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
					else
						real_jmp_adr <= std_logic_vector(unsigned(pc_record_id_ex.pc) + 1);
					end if;
				end if;
				
				--bnq
				if(instr_rec_id_ex.bnq='1') then
					result_ex_mem_next <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(signed(instr_rec_id_ex.imm16)),32));
					
					if(instr_rec_id_ex.data_rs_1 /= instr_rec_id_ex.data_rs_2) then
						real_jmp_adr <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
					else
						real_jmp_adr <= std_logic_vector(unsigned(pc_record_id_ex.pc) + 1);
					end if;
				end if;
				
				--bgt
				if(instr_rec_id_ex.bgt='1') then
					result_ex_mem_next <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(signed(instr_rec_id_ex.imm16)),32));
					
					if(instr_rec_id_ex.data_rs_1 > instr_rec_id_ex.data_rs_2) then
						real_jmp_adr <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
					else
						real_jmp_adr <= std_logic_vector(unsigned(pc_record_id_ex.pc) + 1);
					end if;
				end if;
				
				--bge
				if(instr_rec_id_ex.bge='1') then
					result_ex_mem_next <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(signed(instr_rec_id_ex.imm16)),32));
					
					if(instr_rec_id_ex.data_rs_1 >= instr_rec_id_ex.data_rs_2) then
						real_jmp_adr <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
					else
						real_jmp_adr <= std_logic_vector(unsigned(pc_record_id_ex.pc) + 1);
					end if;
				end if;
				
				--blt
				if(instr_rec_id_ex.blt='1') then
					result_ex_mem_next <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(signed(instr_rec_id_ex.imm16)),32));
					
					if(instr_rec_id_ex.data_rs_1 < instr_rec_id_ex.data_rs_2) then
						real_jmp_adr <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
					else
						real_jmp_adr <= std_logic_vector(unsigned(pc_record_id_ex.pc) + 1);
					end if;
				end if;
				
				--ble
				if(instr_rec_id_ex.ble='1') then
					result_ex_mem_next <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(signed(instr_rec_id_ex.imm16)),32));
					
					if(instr_rec_id_ex.data_rs_1 <= instr_rec_id_ex.data_rs_2) then
						real_jmp_adr <= std_logic_vector(to_unsigned(1 + to_integer(unsigned(pc_record_id_ex.pc)) + to_integer(resize(signed(instr_rec_id_ex.imm16),32)),32));
					else
						real_jmp_adr <= std_logic_vector(unsigned(pc_record_id_ex.pc) + 1);
					end if;
				end if;
		
		-- Obrada skoka
				if(instr_rec_id_ex.instr_jmp = '1') then
					
					if(pc_record_id_ex.pc_pred = real_jmp_adr) then
						pred_succ_next <= '1';
					else
						pred_succ_next <= '0';
					end if;
					
					if(unsigned(pc_record_id_ex.pc) + 1 = unsigned(real_jmp_adr)) then
						instr_rec_ex_mem_next.jmp_happened <= '0';
					else
						instr_rec_ex_mem_next.jmp_happened <= '1';
					end if;	
					
					if(unsigned(real_jmp_adr) > to_unsigned(INSTRUCTION_MEM_SIZE, A_BUS_WIDTH + 1)) then
						instr_rec_ex_mem_next.overflow <= '1';
					end if;
					
				end if;
				
				--hazard
			
				hazard_rec_ex_hu.flush <= instr_rec_id_ex.flush; 
				--hazard_rec_ex_hu.data <= result_ex_mem_next;
				hazard_rec_ex_hu.dst_reg <= instr_rec_id_ex.adr_rd;
				hazard_rec_ex_hu.wr_dst_reg <= instr_rec_id_ex.wr_reg;
														
				if(instr_rec_id_ex.ready_exec = '1') then
					hazard_rec_ex_hu.ready_data <= '1';
				else
					hazard_rec_ex_hu.ready_data <= '0';
				end if;
				
			end if;
		end if;	
	end process;
	
--izlaz	
	result_ex_mem <= result_ex_mem_reg;
	instr_rec_ex_mem <= instr_rec_ex_mem_reg;
	pc_record_ex_mem <= pc_record_ex_mem_reg;
	pred_succ <= pred_succ_reg;
	
	process(clk) is 
	begin
		if(rising_edge(clk)) then
			if(reset='1')then
				
			else
				instr_rec_ex_mem_reg <= instr_rec_ex_mem_next;
				result_ex_mem_reg <= result_ex_mem_next;
				pc_record_ex_mem_reg <= pc_record_ex_mem_next;
				pred_succ_reg <= pred_succ_next;
			end if;
		end if;	
	end process;
	
	

end ArchInstrExec;
