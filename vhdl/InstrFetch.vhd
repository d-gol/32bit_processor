library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity InstrFetch is
 port
 (
	  clk : in  std_logic;
	  reset : in  std_logic;
	  initialPC: in std_logic_vector(A_BUS_WIDTH downto 0);
	  stall: in std_logic;
	  flush: in std_logic;
	  halt : in std_logic;
	  pred_update_mem_if: in Record_update_predictor; -- Za if fazu, da se azurira prediktor
	  pred_update_wb_if : in Record_update_predictor; -- Za if fazu, da se azurira prediktor
	  
	  pc_pred_if_id: out std_logic_vector(A_BUS_WIDTH downto 0);
	  adr_if_imem: out std_logic_vector(A_BUS_WIDTH downto 0);
	  pc_rec_if_id: out Record_PC
 );
end InstrFetch;

architecture ArchInstrFetch of InstrFetch is
	signal pc_rec_if_id_next: Record_PC;
	signal pc_rec_if_id_reg : Record_PC;
	signal reset_pc: std_logic;
	signal pc_pred : std_logic_vector(A_BUS_WIDTH downto 0);
	signal hit_pred: std_logic;
	signal real_pc_pred: Record_update_predictor; -- iz mem ili iz wb

begin
	Branch_predictor: entity work.Predictor(archPredictor) port map (clk, reset, flush, pc_rec_if_id_reg.pc, real_pc_pred, pc_pred, hit_pred);

	process(halt, pc_rec_if_id_reg, initialPC, flush, reset, reset_pc, pc_pred, stall, pred_update_mem_if, pred_update_wb_if, hit_pred, real_pc_pred) is
	variable pc_inc: std_logic_vector(D_BUS_WIDTH downto 0);
	variable pc: std_logic_vector(D_BUS_WIDTH downto 0);
	begin
		--inicijalizacija	
		pc_rec_if_id_next <= pc_rec_if_id_reg;
		
		pc := pc_rec_if_id_reg.pc;
		pc_inc := pc_rec_if_id_reg.pc;

		--informacije za prediktor od mem ili od wb zbog rts-a
		if(pred_update_wb_if.i_jmp='1') then
			real_pc_pred <= pred_update_wb_if;		
		elsif(pred_update_mem_if.i_jmp='1') then
			real_pc_pred <= pred_update_mem_if;
		else
			real_pc_pred.i_jmp <='0';
			real_pc_pred.jmp <='0';
			real_pc_pred.pc<=std_logic_vector(to_unsigned(0,32));
			real_pc_pred.real_jmp_adr<=std_logic_vector(to_unsigned(0,32));
		end if;
		
		if(halt='1') then
			pc_rec_if_id_next.pc <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
			pc_rec_if_id_next.pc_inc <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
			pc_rec_if_id_next.pc_pred <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
		else
			if(stall /= '1') then
				if(reset_pc = '1') then
					pc_rec_if_id_next.pc <= initialPC;
					pc_rec_if_id_next.pc_inc <= std_logic_vector( unsigned(initialPC ) + 1);
					pc_rec_if_id_next.pc_pred <= pc_pred;
				else
					if((flush = '1' and real_pc_pred.jmp='0')) then
						pc := std_logic_vector( unsigned(real_pc_pred.pc ) + 1);
					elsif(flush = '1' and real_pc_pred.jmp='1') then
						pc := real_pc_pred.real_jmp_adr;
					else
						if(hit_pred='1') then
							pc := pc_pred;
						else
							pc := std_logic_vector( unsigned(pc_rec_if_id_reg.pc ) + 1);
						end if;
					end if;
					pc_inc := std_logic_vector( unsigned(pc ) + 1);
					pc_rec_if_id_next.pc <= pc;
					pc_rec_if_id_next.pc_inc <= pc_inc;					
					pc_rec_if_id_next.pc_pred <= pc_pred;	
				end if;
			end if;
		end if;
	end process;
	
--izlaz	
	adr_if_imem <= pc_rec_if_id_reg.pc;
	pc_rec_if_id <= pc_rec_if_id_reg;
	pc_pred_if_id <= pc_pred;
	
	process(clk) is
	begin
		if(rising_edge(clk)) then
			if(reset='1') then
				reset_pc <= '1';
				pc_rec_if_id_reg.pc_inc <= std_logic_vector(to_unsigned(0,32));
				pc_rec_if_id_reg.pc_pred <= std_logic_vector(to_unsigned(0,32));
			else
				reset_pc <= '0';
				pc_rec_if_id_reg <= pc_rec_if_id_next;
			end if;
		end if;
	end process;
	
end ArchInstrFetch;