LIBRARY ieee;                                               
USE ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.std_logic_textio.all;
use std.textio.all; 
use work.ConstPackage.all;                               

ENTITY CPU_vhd_tst IS
END CPU_vhd_tst;
ARCHITECTURE CPU_arch OF CPU_vhd_tst IS
-- constants                                                 
-- signals                                                   
SIGNAL clk : STD_LOGIC;
SIGNAL initialPC : STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL reset : STD_LOGIC;
SIGNAL mem_wr: std_logic;
SIGNAL mem_rd: std_logic;
SIGNAL rec_cpu_mem: Record_mem;
SIGNAL data_mem_cpu: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL reset_mem_rec: Record_mem;
SIGNAL reset_adr_i_mem: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL reset_data_i_mem: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL adr_cpu_i_mem: STD_LOGIC_VECTOR(31 DOWNTO 0);
SIGNAL instr_i_mem_cpu: STD_LOGIC_VECTOR(31 DOWNTO 0);

COMPONENT CPU
	PORT (
		clk : in  std_logic;
		reset: in std_logic;
		initialPC: in std_logic_vector(A_BUS_WIDTH downto 0);
		mem_data_in: in std_logic_vector(D_BUS_WIDTH downto 0); --podatak iz data memorije
		i_mem_instr_in: in std_logic_vector(D_BUS_WIDTH downto 0); -- podatak(instrukcija) iz instrukcijske memorije
		i_mem_adr_out: out std_logic_vector(A_BUS_WIDTH downto 0); -- adresa (pc) sa koje se cita instrukcija
		
		mem_rec_out: out Record_mem -- Podaci za upis u data memoriju
	);
END COMPONENT;
COMPONENT DataMemory
	PORT(
		clk: in std_logic;
		reset: in std_logic;
		mem_rec_in: in Record_mem;
		reset_mem_rec_in: in Record_mem;
		
		data_out: out std_logic_vector(D_BUS_WIDTH downto 0)
	);
END COMPONENT;
COMPONENT InstructionMemory
	PORT(
		clk: in std_logic;
		reset: in std_logic;
		
		reset_adr_in: in std_logic_vector(A_BUS_WIDTH downto 0);
		reset_data_in: in std_logic_vector(D_BUS_WIDTH downto 0);
		
		adr_in: in std_logic_vector(A_BUS_WIDTH downto 0);
		
		data_out: out std_logic_vector(D_BUS_WIDTH downto 0)
	);
END COMPONENT;

BEGIN
	i1 : CPU
	PORT MAP (
	-- list connections between master ports and signals
		clk => clk,
		reset => reset,
		initialPC => initialPC,
		mem_data_in => data_mem_cpu,
		i_mem_instr_in => instr_i_mem_cpu,
		i_mem_adr_out => adr_cpu_i_mem,
		mem_rec_out => rec_cpu_mem
	);

	dataMem : DataMemory
	PORT MAP(
		clk => clk,
		reset => reset,
		mem_rec_in => rec_cpu_mem,
		reset_mem_rec_in => reset_mem_rec,
		data_out => data_mem_cpu
	);
	
	instMem : InstructionMemory
	PORT MAP(
		clk => clk,
		reset => reset,
		reset_adr_in => reset_adr_i_mem,
		reset_data_in => reset_data_i_mem,
		adr_in => adr_cpu_i_mem,
		data_out => instr_i_mem_cpu
	);
	
PROCESS
	variable clk_next:std_logic:='1';
BEGIN
	loop
		clk<=clk_next;
		clk_next := not clk_next;
		wait for 5 ns;
	end loop;
END PROCESS;   
                                       
PROCESS
	file instructions	: text open read_mode is "javni_test_inst_in.txt";
	file data_mem_file	: text open read_mode is "javni_test_data_in.txt";
	variable line_instr	:	line;
	variable line_data	:	line;
	variable instruction_address	:	std_logic_vector(31 downto 0);
	variable instruction	:	std_logic_vector(31 downto 0);
	variable data_mem_adr: std_logic_vector(31 downto 0);
	variable data_mem_data: std_logic_vector(31 downto 0);
BEGIN
--inicijalni PC
	readline(instructions, line_instr);
	hread(line_instr, instruction_address);
	initialPC <= instruction_address;
	
	reset <= '1';
	
-- Inicijalizacija Data memorije	
	while ( not endfile(data_mem_file) ) loop
		readline(data_mem_file, line_data);
		hread(line_data, data_mem_adr);
		read(line_data, data_mem_data);
		reset_mem_rec.wr <= '1';
		reset_mem_rec.adr <= data_mem_adr;
		reset_mem_rec.data <= data_mem_data;
		wait until rising_edge(clk);
	end loop;
	
-- Inicijalizacija instrukcijske memorije		
	while ( not endfile(instructions) ) loop
		readline(instructions, line_instr);
		hread(line_instr, instruction_address);
		read(line_instr, instruction);
		reset_adr_i_mem <= instruction_address;
		reset_data_i_mem <= instruction;
		wait until rising_edge(clk);
	end loop;
	
	reset_mem_rec.wr <= '0'; --BITNO!
	reset_mem_rec.rd <= '0'; --BITNO!
	wait until rising_edge(clk);
	reset <= '0';
	wait;
END PROCESS;                                          
END CPU_arch;
