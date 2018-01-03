library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity InstrWB is
	port
	(
		clk    : in  std_logic;
	   reset  : in  std_logic;
		flush  : in  std_logic;
		data_mem_in : in std_logic_vector(D_BUS_WIDTH downto 0); --podatak koji se dobija iz MEMORIJE
		data_stack_wb : in std_logic_vector(D_BUS_WIDTH downto 0); --podatak koji se dobija sa STEKA
		result_mem_wb: in std_logic_vector(D_BUS_WIDTH downto 0); -- podatak iz FAZE MEM za upis u registar
		pc_record_mem_wb: in Record_PC;
		instr_rec_mem_wb : in Record_instr;
		
		hazard_rec_wb_hu: out Record_hazard_EX_MEM_WB_HU;
		rec_wb_id:    out Record_wb_id;
		pred_update_wb_if: out Record_update_predictor
	);
end InstrWB;

architecture ArchInstrWB of InstrWB is
	signal rec_wb_id_next   : Record_wb_id;
	signal rec_wb_id_reg    : Record_wb_id;
	signal pred_update_wb_if_next : Record_update_predictor;
	signal pred_update_wb_if_reg  : Record_update_predictor;
begin

--next
	process(flush, data_mem_in, data_stack_wb, result_mem_wb, instr_rec_mem_wb, rec_wb_id_next.data, pc_record_mem_wb) is 
	begin
		hazard_rec_wb_hu.ready_data <= '0';
		hazard_rec_wb_hu.flush <= '1';
		hazard_rec_wb_hu.wr_dst_reg <= '0';
		hazard_rec_wb_hu.dst_reg <= "ZZZZZ";
		hazard_rec_wb_hu.data <= std_logic_vector(to_unsigned(0, 32));
	
		rec_wb_id_next.reg_adr <= std_logic_vector(to_unsigned(0, 5));
		rec_wb_id_next.wr_reg <= '0';
		rec_wb_id_next.data <= std_logic_vector(to_unsigned(0, 32));
		
		pred_update_wb_if_next.i_jmp <= '0'; -- da li je instrukcija skoka
		pred_update_wb_if_next.jmp <= '0';
		pred_update_wb_if_next.pc <= std_logic_vector(to_unsigned(0, 32));
		pred_update_wb_if_next.real_jmp_adr <= std_logic_vector(to_unsigned(0, 32));
	
		if(flush /= '1') then
			if(instr_rec_mem_wb.flush = '1') then --ako je stall, mora na kraju da ima pravu vrednost
				hazard_rec_wb_hu.ready_data <= '1';
			
			elsif(instr_rec_mem_wb.flush_jmp='1') then --ako je pogresna predikcija skoka, onda nema pravu vrednost za HU
				hazard_rec_wb_hu.ready_data <= '0'; 
				hazard_rec_wb_hu.flush <= '1';
			elsif(instr_rec_mem_wb.rts='1') then
				pred_update_wb_if_next.i_jmp <= '1'; -- da li je instrukcija skoka
				pred_update_wb_if_next.jmp <= '1';
				pred_update_wb_if_next.pc <= pc_record_mem_wb.pc;
				pred_update_wb_if_next.real_jmp_adr <= data_stack_wb;
				
			else	
				if(instr_rec_mem_wb.load='1') then
					rec_wb_id_next.data <= data_mem_in;		
				elsif(instr_rec_mem_wb.pop='1' or instr_rec_mem_wb.rts='1') then
					rec_wb_id_next.data <= data_stack_wb;
				else
					rec_wb_id_next.data <= result_mem_wb;
				end if;
				
			-- hazard
				hazard_rec_wb_hu.flush <= instr_rec_mem_wb.flush;
				hazard_rec_wb_hu.data <= rec_wb_id_next.data;
				hazard_rec_wb_hu.dst_reg <= instr_rec_mem_wb.adr_rd;
				hazard_rec_wb_hu.wr_dst_reg <= instr_rec_mem_wb.wr_reg;
				
				if(instr_rec_mem_wb.ready_exec = '1' or instr_rec_mem_wb.load = '1' or instr_rec_mem_wb.pop = '1') then
						hazard_rec_wb_hu.ready_data <= '1';
					else
						hazard_rec_wb_hu.ready_data <= '0';
				end if;
			
			--next									
				rec_wb_id_next.reg_adr <= instr_rec_mem_wb.adr_rd;
				rec_wb_id_next.wr_reg <= instr_rec_mem_wb.wr_reg;
			end if;
		end if;
	end process;

--izlaz	
	rec_wb_id <= rec_wb_id_reg;
	pred_update_wb_if <= pred_update_wb_if_reg;

	process(clk) is
	begin
		if(rising_edge(clk)) then
			if(reset='1') then
				
			else
				rec_wb_id_reg <= rec_wb_id_next;
				pred_update_wb_if_reg <= pred_update_wb_if_next;
			end if;
		end if;
	end process;

end ArchInstrWB;