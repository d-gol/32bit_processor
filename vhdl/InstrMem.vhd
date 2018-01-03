library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity InstrMem is
	port
	(
		clk : in std_logic;
	   reset : in  std_logic;
		flush_in : in std_logic;
		rts_in: in std_logic;
		rts_pred_pc: in std_logic_vector(A_BUS_WIDTH downto 0);
		halt_in: in std_logic;
		stack_data_in: in std_logic_vector(D_BUS_WIDTH downto 0); -- za RTS
		result_ex_mem : in std_logic_vector(D_BUS_WIDTH downto 0);
		pc_record_ex_mem : in Record_PC;
		instr_rec_ex_mem : in Record_instr;
		pred_succ : in std_logic;
		
		flush : out std_logic;
		pred_update_mem_if: out Record_update_predictor; -- Za if fazu, da se azurira prediktor
		mem_rec_out: out Record_mem; -- Ovo se salje memoriji
		stack_rec_out: out Record_stack; -- Podaci koje se salje steku za push ili pop
		hazard_rec_mem_hu: out Record_hazard_EX_MEM_WB_HU; -- Za Hazard jedinicu
		result_mem_wb: out std_logic_vector(D_BUS_WIDTH downto 0); --Ovo se salje u WB, rezultat za upis u registar. Ako je load rezultat ce biti iz memorije, to se proverava u sledecoj fazi
		pc_record_mem_wb: out Record_PC;
		instr_rec_mem_wb : out Record_instr;
		rts_out: out std_logic;
		rts_pred_pc_out: out std_logic_vector(A_BUS_WIDTH downto 0);
		halt_out: out std_logic
	);
end InstrMem;

architecture ArchInstrMem of InstrMem is
	signal result_mem_wb_next: std_logic_vector(D_BUS_WIDTH downto 0);
	signal result_mem_wb_reg: std_logic_vector(D_BUS_WIDTH downto 0);
	signal instr_rec_mem_wb_next: Record_instr;
	signal instr_rec_mem_wb_reg: Record_instr;
	signal pc_record_mem_wb_next: Record_PC;
	signal pc_record_mem_wb_reg: Record_PC;
	signal flush_next: std_logic;
	signal flush_reg:  std_logic;
	signal pred_update_mem_if_next : Record_update_predictor;
	signal pred_update_mem_if_reg  : Record_update_predictor;
	signal rts_out_next: std_logic;
	signal rts_out_reg: std_logic;
	signal halt_out_next: std_logic;
	signal halt_out_reg: std_logic;
	signal rts_pred_pc_out_next: std_logic_vector(A_BUS_WIDTH downto 0);
	signal rts_pred_pc_out_reg: std_logic_vector(A_BUS_WIDTH downto 0);
begin

	process(stack_data_in, rts_pred_pc, halt_in, rts_in, flush_in, pred_succ, result_ex_mem, instr_rec_ex_mem, pc_record_ex_mem) is
	begin
		--Flush
		flush_next <= '0';
		rts_out_next <= '0';
		halt_out_next <= halt_in;
		rts_pred_pc_out_next <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
	
		--Hazard
		hazard_rec_mem_hu.flush <= '0';
		hazard_rec_mem_hu.ready_data <= '0';
		hazard_rec_mem_hu.wr_dst_reg <= '0';
		hazard_rec_mem_hu.dst_reg <= "00000";
		hazard_rec_mem_hu.data <= std_logic_vector(to_unsigned(0, 32));
		
		--stek out
		stack_rec_out.push <= '0';
		stack_rec_out.pop <= '0';
		stack_rec_out.data <= std_logic_vector(to_unsigned(0, 32)); --pazi za jsr
		
		-- memory out	
		mem_rec_out.wr <= '0';
		mem_rec_out.rd <= '0';
		mem_rec_out.adr  <= std_logic_vector(to_unsigned(0, 32));
		mem_rec_out.data <= std_logic_vector(to_unsigned(0, 32));
		
		-- predictor out
		pred_update_mem_if_next.i_jmp <= instr_rec_ex_mem.instr_jmp; -- da li je instrukcija skoka
		pred_update_mem_if_next.jmp <= instr_rec_ex_mem.jmp_happened;
		pred_update_mem_if_next.pc <= pc_record_ex_mem.pc;
		pred_update_mem_if_next.real_jmp_adr <= result_ex_mem;
		
		--next
		instr_rec_mem_wb_next <= instr_rec_ex_mem;
		result_mem_wb_next <= result_ex_mem;
		pc_record_mem_wb_next <= pc_record_ex_mem;
		

		if(instr_rec_ex_mem.flush_jmp = '1') then
			instr_rec_mem_wb_next.flush_jmp <= '1';
			hazard_rec_mem_hu.flush <= '1';
		elsif(flush_in='1') then
			instr_rec_mem_wb_next.flush_jmp <= '1';
			hazard_rec_mem_hu.flush <= '1';
		else
			if(instr_rec_ex_mem.flush = '1') then --ako je stall
				hazard_rec_mem_hu.flush <= '1';
			elsif(instr_rec_ex_mem.instr_jmp='1' and pred_succ='0') then	-- ako je pogresna predikcija skoka
				flush_next <= '1';
				
				if(instr_rec_ex_mem.overflow='1') then
					halt_out_next <= '1';
				else
				
					if(instr_rec_ex_mem.jsr = '1') then
						stack_rec_out.push<='1';
						stack_rec_out.pop<='0';
						stack_rec_out.data <= std_logic_vector(unsigned(pc_record_ex_mem.pc) + 1);
					end if;
					
					if(instr_rec_ex_mem.rts='1') then
						rts_out_next <= '1';
						stack_rec_out.pop <= '1';
						flush_next <= '0';
						pred_update_mem_if_next.i_jmp<='0';
						pred_update_mem_if_next.jmp<='0';
						rts_pred_pc_out_next <= pc_record_ex_mem.pc_pred;
					end if;
					
					if(rts_in='1') then
						flush_next<='0';
						if(unsigned(rts_pred_pc) /= unsigned(stack_data_in)) then
							rts_out_next <= '0';
							flush_next <= '1';
							stack_rec_out.push<='0';
							mem_rec_out.wr<='0';
							mem_rec_out.rd<='0';
							halt_out_next <= '0';
						end if;
					end if;
				end if;
			else			--ako je dobra predikcija skoka ili nije instrukcija skoka							
				-- next
				instr_rec_mem_wb_next <= instr_rec_ex_mem;
				result_mem_wb_next <= result_ex_mem;
				pc_record_mem_wb_next <= pc_record_ex_mem;
				halt_out_next <= '0';
				
				--stek out
				if(instr_rec_ex_mem.push = '1' or instr_rec_ex_mem.jsr = '1') then
					stack_rec_out.push<='1';
				end if;
				stack_rec_out.pop <= instr_rec_ex_mem.pop or instr_rec_ex_mem.rts;
				stack_rec_out.data <= result_ex_mem;
				if(instr_rec_ex_mem.jsr='1') then
					stack_rec_out.data <= std_logic_vector(unsigned(pc_record_ex_mem.pc) + 1);
				end if;
				
				-- memory out	
				mem_rec_out.wr <= instr_rec_ex_mem.wr_mem;
				mem_rec_out.rd <= instr_rec_ex_mem.rd_mem;
				mem_rec_out.adr  <= instr_rec_ex_mem.adr_mem;
				mem_rec_out.data <= result_ex_mem;
				
				-- hazard
				hazard_rec_mem_hu.flush <= instr_rec_ex_mem.flush;
				hazard_rec_mem_hu.data <= result_ex_mem;
				hazard_rec_mem_hu.dst_reg <= instr_rec_ex_mem.adr_rd;
				hazard_rec_mem_hu.wr_dst_reg <= instr_rec_ex_mem.wr_reg;
				
				if(instr_rec_ex_mem.ready_exec = '1') then
					hazard_rec_mem_hu.ready_data <= '1';
				else
					hazard_rec_mem_hu.ready_data <= '0';
				end if;
				
				if(instr_rec_ex_mem.halt = '1' or instr_rec_ex_mem.overflow='1') then
					halt_out_next <= '1';
					flush_next <= '1';
					mem_rec_out.rd<='0';
					mem_rec_out.wr<='0';
				end if;
				
				if(rts_in='1') then
					flush_next<='0';
					if(unsigned(rts_pred_pc) /= unsigned(stack_data_in)) then
						rts_out_next <= '0';
						flush_next <= '1';
						stack_rec_out.push<='0';
						mem_rec_out.wr<='0';
						mem_rec_out.rd<='0';
						halt_out_next <= '0';
					end if;
				end if;
				
				if(halt_in='1') then
					halt_out_next <= '1';
					flush_next <= '0';
				end if;
			
			end if;
		end if;
	end process;
	
-- izlazi
	instr_rec_mem_wb <= instr_rec_mem_wb_reg;
	result_mem_wb <= result_mem_wb_reg;
	pc_record_mem_wb <= pc_record_mem_wb_reg;
	flush <= flush_reg;
	pred_update_mem_if <= pred_update_mem_if_reg;
	rts_out <= rts_out_reg;
	halt_out <= halt_out_reg;
	rts_pred_pc_out <= rts_pred_pc_out_reg;
	
	process(clk) is
	begin
		if(rising_edge(clk)) then
			if(reset='1') then
				halt_out_reg <= '0';
			else
				result_mem_wb_reg <= result_mem_wb_next;
				instr_rec_mem_wb_reg <= instr_rec_mem_wb_next;
				pc_record_mem_wb_reg <= pc_record_mem_wb_next;
				flush_reg <= flush_next;
				pred_update_mem_if_reg <= pred_update_mem_if_next;
				rts_out_reg <= rts_out_next;
				halt_out_reg <= halt_out_next;
				rts_pred_pc_out_reg <= rts_pred_pc_out_next;
			end if;
		end if;
	end process;

end ArchInstrMem;
