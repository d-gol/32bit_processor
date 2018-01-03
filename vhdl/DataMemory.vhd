library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity DataMemory is
	port
	(
		clk: in std_logic;
		reset: in std_logic;
		mem_rec_in: in Record_mem;
		reset_mem_rec_in: in Record_mem;
		
		data_out: out std_logic_vector(D_BUS_WIDTH downto 0)
	);
end DataMemory;
	
architecture ArchDataMemory of DataMemory is
	type memory_array is array (0 to DATA_MEM_SIZE) of std_logic_vector(D_BUS_WIDTH downto 0);
	signal memory : memory_array := (others => (others => '0'));	
begin
	
	write: process (clk)
	begin
		if (mem_rec_in.wr='1' or reset_mem_rec_in.wr='1') then
			if (rising_edge(clk)) then
				if(reset='1') then
					memory(to_integer(unsigned(reset_mem_rec_in.adr))) <= reset_mem_rec_in.data;
				else
					memory(to_integer(unsigned(mem_rec_in.adr))) <= mem_rec_in.data;
				end if;
			end if;
		end if;
	end process write;
	
	--read:process (clk, mem_rec_in.rd, mem_rec_in.adr, memory)
	read:process (clk)
	begin
	if(rising_edge(clk)) then
		if (mem_rec_in.rd='1') then
			data_out <= memory(to_integer(unsigned(mem_rec_in.adr)));
		else
			for i in data_out'range loop
				data_out(i) <= 'Z';
			end loop;
		end if;
	end if;
	end process read;
	
end ArchDataMemory;	
