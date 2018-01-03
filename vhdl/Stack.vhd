library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity Stack is
	port
	(
		clk: in std_logic;
		
		stack_rec_in : in Record_stack; -- push pop data
		
		data_out: out std_logic_vector(D_BUS_WIDTH downto 0) --podatak sa pop-a
	);
end Stack;
	
architecture ArchStack of Stack is
	type memory_array is array (0 to (STACK_SIZE - 1) ) of std_logic_vector(D_BUS_WIDTH downto 0);
	signal memory : memory_array := (others => (others => '0'));
	
	signal SP: integer:= STACK_SIZE - 1; --sp na pocetku 255, onda se smanjuje
begin
	
	process(clk) is
	begin
		if(rising_edge(clk)) then
			if(stack_rec_in.push='1') then
				if(SP > 0) then
					memory(SP) <= stack_rec_in.data;
					SP <= SP - 1;
				end if;
			else 
				if (stack_rec_in.pop='1') then
					if(SP < (STACK_SIZE - 1) ) then
						SP <= SP + 1;
						data_out <= memory(SP+1); -- zato sto on tek na klok promeni SP!
					end if;
				else
					for i in data_out'range loop
						data_out(i) <= 'Z';
					end loop;
				end if;
			end if;
		end if;
	end process;
	
end ArchStack;	
