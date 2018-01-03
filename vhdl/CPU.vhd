library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity CPU is
	port
	(
		clk : in  std_logic;
		reset: in std_logic;
		initialPC: in std_logic_vector(A_BUS_WIDTH downto 0);
		mem_data_in: in std_logic_vector(D_BUS_WIDTH downto 0); --podatak iz data memorije
		i_mem_instr_in: in std_logic_vector(D_BUS_WIDTH downto 0); -- podatak(instrukcija) iz instrukcijske memorije
		i_mem_adr_out: out std_logic_vector(A_BUS_WIDTH downto 0); -- adresa (pc) sa koje se cita instrukcija
		
		mem_rec_out: out Record_mem -- Podaci za upis u data memoriju
	);
end CPU;


architecture archCPU of CPU is

-- Azuriranje prediktora
	signal pred_update_mem_if: Record_update_predictor; -- Za if fazu, da se azurira prediktor
	signal pred_update_wb_if: Record_update_predictor; -- Za if fazu, da se azurira prediktor
	signal pred_succ: std_logic;

-- Flush mem - ostali
	signal flush: std_logic;
	
-- Flush
	signal halt: std_logic;
	
-- Rts
	signal rts_mem_mem: std_logic;
	signal rts_pc_pred_mem_mem: std_logic_vector(A_BUS_WIDTH downto 0);

-- PC record, PC pred
	signal pc_if_id_record: Record_PC;
	signal pc_id_ex_record: Record_PC;
	signal pc_ex_mem_record: Record_PC;
	signal pc_mem_wb_record: Record_PC;
	signal pc_pred_if_id: std_logic_vector(A_BUS_WIDTH downto 0);
	
-- Rezultat iz ALU (EX faze)	
	signal result_ex_mem : std_logic_vector(D_BUS_WIDTH downto 0);
	signal result_mem_wb : std_logic_vector(D_BUS_WIDTH downto 0);

-- Dekodovana instrukcija	
	signal record_instr_id_ex :  Record_instr;
	signal record_instr_ex_mem : Record_instr;
	signal record_instr_mem_wb : Record_instr;
	signal record_instr_wb_if:   Record_instr;

-- Registar za upis iz WB	
	signal record_reg_wb_id:     Record_wb_id; 

-- Stek	
	signal record_mem_stack:     Record_stack; -- podaci koji se salju steku pop push i data za eventualni push
	signal data_stack_wb:        std_logic_vector(D_BUS_WIDTH downto 0); -- podatak koji se dobija iz steka sa pop

-- Hazardi	
	signal hazard_rec_id_hu: Record_hazard_ID_HU;
	signal hazard_rec_ex_hu: Record_hazard_EX_MEM_WB_HU;
	signal hazard_rec_mem_hu: Record_hazard_EX_MEM_WB_HU;
	signal hazard_rec_wb_hu: Record_hazard_EX_MEM_WB_HU;
	signal hazard_rec_hu_id: Record_hazard_HU_ID;
	signal stall: std_logic; -- na nivou cpu
	signal stall_id_hu: std_logic;
	
begin
	
	IF_phase:  entity work.InstrFetch(archInstrFetch)  port map (clk, reset, initialPC, stall, flush, halt, pred_update_mem_if, pred_update_wb_if, pc_pred_if_id, i_mem_adr_out, pc_if_id_record);
	ID_phase:  entity work.InstrDecode(archInstrDecode)port map (clk, reset, stall, pc_if_id_record, pc_pred_if_id, record_reg_wb_id, i_mem_instr_in, hazard_rec_hu_id, flush, hazard_rec_id_hu, pc_id_ex_record, record_instr_id_ex, stall_id_hu);
	EX_phase:  entity work.InstrExec(archInstrExec) 	port map (clk, reset, pc_id_ex_record, record_instr_id_ex, flush, hazard_rec_ex_hu, result_ex_mem, pc_ex_mem_record, record_instr_ex_mem, pred_succ);
	MEM_phase: entity work.InstrMem(archInstrMem) 		port map (clk, reset, flush, rts_mem_mem, rts_pc_pred_mem_mem, halt, data_stack_wb, result_ex_mem, pc_ex_mem_record, record_instr_ex_mem, pred_succ, flush, pred_update_mem_if, mem_rec_out, record_mem_stack, hazard_rec_mem_hu, result_mem_wb, pc_mem_wb_record, record_instr_mem_wb, rts_mem_mem, rts_pc_pred_mem_mem, halt);
	WB_phase:  entity work.InstrWB(archInstrWB) 			port map (clk, reset, flush, mem_data_in, data_stack_wb, result_mem_wb, pc_mem_wb_record, record_instr_mem_wb, hazard_rec_wb_hu, record_reg_wb_id, pred_update_wb_if);
	
	ImplStack:      entity work.Stack(archStack)           port map(clk, record_mem_stack, data_stack_wb);	
	ImplHazardUnit: entity work.HazardUnit(archHazardUnit) port map(reset, stall_id_hu, hazard_rec_id_hu, hazard_rec_ex_hu, hazard_rec_mem_hu, hazard_rec_wb_hu, hazard_rec_hu_id, stall);
	
end archCPU;