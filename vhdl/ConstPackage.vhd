library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

package ConstPackage is
  constant A_BUS_WIDTH : integer := 31;
  constant D_BUS_WIDTH : integer := 31;
  constant STACK_SIZE : integer := 256;
  constant PRED_EXP : integer := 2; -- 2 na PRED_EXP je velicina kesa u prediktoru
  constant DATA_MEM_SIZE : integer := 1024;
  constant INSTRUCTION_MEM_SIZE : integer := 8096;
  
  --Za updatovanje prediktora
  type Record_update_predictor is record
		pc: std_logic_vector(A_BUS_WIDTH downto 0);
		real_jmp_adr: std_logic_vector(A_BUS_WIDTH downto 0);
		jmp: std_logic; -- da li se desio skok
		i_jmp: std_logic; -- da li je stvarno instrukcija skoka
  end record Record_update_predictor;
  
  --Rezultat operacija iz Hazard unita, slanje ID fazi da li ima prosledjivanja, i prosledjeni podatak
  type Record_hazard_HU_ID is record
		valid_1: std_logic; -- da li ima prosledjivanja
		valid_2: std_logic;
		data_1: std_logic_vector(D_BUS_WIDTH downto 0);
		data_2: std_logic_vector(D_BUS_WIDTH downto 0);
  end record Record_hazard_HU_id;
  
  --Podaci koji se salju Hazard unitu od faza EX, MEM i WB (koje vrednosti upisujemo i da li su spremne)
  type Record_hazard_EX_MEM_WB_HU is record
		dst_reg: std_logic_vector(4 downto 0);
		wr_dst_reg: std_logic;
		data: std_logic_vector(D_BUS_WIDTH downto 0); -- podatak za prosledjivanje
		ready_data: std_logic;
		flush : std_logic;
  end record Record_hazard_EX_MEM_WB_HU;
  
  --Podaci koji se salju Hazard Unitu od ID faze (koje registre citamo i da li stvarno citamo)
  type Record_hazard_ID_HU is record
		reg_1: std_logic_vector(4 downto 0);
		reg_2: std_logic_vector(4 downto 0);
		rd_reg_1: std_logic;  --da li se stvarno cita
		rd_reg_2: std_logic;
		wr_reg: std_logic_vector(4 downto 0); -- za situaciju kada imamo citanje i upis u isti registar kod load npr
  end record Record_hazard_ID_HU;
  
  --Signali koji se salju steku da bi on upisao ili vratio vrednost
  type Record_stack is record
		push: std_logic;
		pop: std_logic;
		data: std_logic_vector(D_BUS_WIDTH downto 0);
  end record Record_stack;
  
  --Signali koji se salju memoriji da bi ona upisala ili vratila vrednost
  type Record_mem is record
		wr: std_logic;
		rd: std_logic;
		adr: std_logic_vector(A_BUS_WIDTH downto 0);
		data: std_logic_vector(D_BUS_WIDTH downto 0);
  end record Record_mem;
  
  --Podaci iz WB do ID, za upis u registar 
  type Record_wb_id is record
		data    : std_logic_vector(D_BUS_WIDTH downto 0); -- podatak koji se salje u ID
		reg_adr : std_logic_vector(4 downto 0); -- adresa (broj) registra koji se salje u ID
		wr_reg  : std_logic; --da li se upisuje u registar
  end Record Record_WB_ID;
  
  --Podaci za PC
  type Record_PC is record
		pc: std_logic_vector(A_BUS_WIDTH downto 0);
		pc_inc: std_logic_vector(A_BUS_WIDTH downto 0);
		pc_pred: std_logic_vector(A_BUS_WIDTH downto 0);
  end record Record_PC;
  
  --Dekodovana istrukcija
  type Record_instr is record
		opcode   : std_logic_vector(5 downto 0); -- 6 bitova za opcode
		adr_rs_1 : std_logic_vector(4 downto 0); -- register source 1
		adr_rs_2 : std_logic_vector(4 downto 0); -- register source 2
		data_rs_1 : std_logic_vector(D_BUS_WIDTH downto 0);
		data_rs_2 : std_logic_vector(D_BUS_WIDTH downto 0);
		adr_rd   : std_logic_vector(4 downto 0); -- register destination
		imm16    : std_logic_vector(15 downto 0);
		imm5    : std_logic_vector(4 downto 0);
		ready_exec: std_logic; -- da li je vrednost spremna u exec fazi
		instr_jmp: std_logic; -- da li je u pitanju instrukcija skoka
		jmp_happened: std_logic; -- da li se zaista desio skok, odredjuje se u ex fazi
		flush_jmp: std_logic; -- flush koji potice od pogresne predikcija skoka
		wr_reg: std_logic; -- da li se upisuje u registar, jer ima instrukcija koje upisuju u memoriju
		wr_mem: std_logic;
		rd_mem: std_logic;
		adr_mem : std_logic_vector(A_BUS_WIDTH downto 0);
		flush: std_logic; -- od stalla
		overflow: std_logic; -- prekoracenje kod load, store, jmp, jsr, beq...ble
		add: std_logic;
		sub: std_logic;
		addi: std_logic;
		subi: std_logic;
		load: std_logic;
		store: std_logic;
		mov: std_logic;
		movi: std_logic;
		and_o: std_logic;
		or_o: std_logic;
		xor_o: std_logic;
		not_o: std_logic;
		shl: std_logic;
		shr: std_logic;
		sar: std_logic;
		rol_o: std_logic;
		ror_o: std_logic;
		jmp: std_logic;
		jsr: std_logic;
		rts: std_logic;
		push: std_logic;
		pop: std_logic;
		beq: std_logic;
		bnq: std_logic;
		bgt: std_logic;
		blt: std_logic;
		bge: std_logic;
		ble: std_logic;
		halt: std_logic;
  end record Record_instr;
  
end ConstPackage;