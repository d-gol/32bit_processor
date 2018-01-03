library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity InstructionMemory is
	port
	(
		clk: in std_logic;
		reset: in std_logic;
		
		reset_adr_in: in std_logic_vector(A_BUS_WIDTH downto 0);
		reset_data_in: in std_logic_vector(D_BUS_WIDTH downto 0);
		
		adr_in: in std_logic_vector(A_BUS_WIDTH downto 0);
		
		data_out: out std_logic_vector(D_BUS_WIDTH downto 0)
	);
end InstructionMemory;
	
architecture ArchInstructionMemory of InstructionMemory is
	type memory_array is array (0 to INSTRUCTION_MEM_SIZE) of std_logic_vector(D_BUS_WIDTH downto 0);
	signal memory : memory_array := (others => (others => 'Z'));	
begin
	--samo kada je reset
	write: process (clk)
	begin
		if (reset='1') then
			if (rising_edge(clk)) then
				memory(to_integer(unsigned(reset_adr_in))) <= reset_data_in;
			end if;
		end if;
	end process write;
	
	read:process (adr_in, reset)
	begin
		--if(rising_edge(clk)) then
			if (reset='1') then
				for i in data_out'range loop
					data_out(i) <= 'Z';
				end loop;
			else
				data_out <= memory(to_integer(unsigned(adr_in)));
			end if;
		--end if;
	end process read;
	
end ArchInstructionMemory;	
