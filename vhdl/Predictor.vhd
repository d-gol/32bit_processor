library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity Predictor is
	
	port
	(
		clk	: in std_logic;
		reset : in std_logic;
		flush : in std_logic;
		pc_in : in std_logic_vector(A_BUS_WIDTH downto 0);
		pred_update_in : in Record_update_predictor;

		pc_pred : out std_logic_vector(A_BUS_WIDTH downto 0);
		hit : out std_logic
	);
	
end Predictor;


architecture ArchPredictor of Predictor is
	type memory_array is array (0 to 2**PRED_EXP-1) of std_logic_vector(A_BUS_WIDTH downto 0);
	type state_array is array (0 to 2**PRED_EXP-1) of std_logic_vector(1 downto 0);
	type lru_array is array (0 to 2**PRED_EXP-1) of std_logic_vector(PRED_EXP-1 downto 0);
	
	signal tag_mem : memory_array := (others => (others => 'Z'));
	signal data_mem : memory_array := (others => (others => 'Z'));
	signal state_mem : state_array := (others => (others => '0'));
	signal lru_mem : lru_array := (others => (others => '0'));
	
begin

-- azuriranje prediktora i reset
	process(clk, pred_update_in, flush, reset, tag_mem, data_mem, lru_mem, state_mem) is
	variable i:integer :=0;
	variable found: boolean;
	variable max: integer;
	variable index: integer;
	
	variable tag_mem_var : memory_array := (others => (others => 'Z'));
	variable data_mem_var : memory_array := (others => (others => 'Z'));
	variable state_mem_var : state_array := (others => (others => '0'));
	variable lru_mem_var : lru_array := (others => (others => '0'));
	
	
	begin
		index := 0;
		found := false;
		max := 0;
		
		if(rising_edge(clk)) then
--		tag_mem_var := tag_mem;
--		data_mem_var := data_mem;
--		state_mem_var := state_mem;
--		lru_mem_var := lru_mem;
		
--		tag_mem <= tag_mem_var;
--		data_mem <= data_mem_var;
--		state_mem <= state_mem_var;
--		lru_mem <= lru_mem_var;
		
		--inicijalizacija za reset
			if(reset = '1') then
				for i in 0 to 2**PRED_EXP-1
				loop
					lru_mem_var(i) := std_logic_vector(to_unsigned((2**PRED_EXP - 1) - i, PRED_EXP)); --lru (i) = 3 - i; lru = {3,2,1,0}
					state_mem_var(i) := "10"; -- weekly taken state = {2,2,2,2}
					
					lru_mem <= lru_mem_var;
					state_mem <= state_mem_var;
				end loop;
			else
			
				--ako nam dolazi update sa instrukcije skoka
				if(pred_update_in.i_jmp = '1') then
					if(flush = '1') then -- ako je promasaj radimo update
					
					--Trazimo jednakost na pc koji dolazi
						for i in 0 to 2**PRED_EXP-1 -- trazimo jednakost
						loop
							if(pred_update_in.pc = tag_mem(i)) then
								index := i;
								found := true;
							else
							end if;
						end loop;
						
					--Ako ne nadjemo pc u kesu, moramo neki da izbacimo
						if(found /= true) then
						
							for i in 0 to 2**PRED_EXP-1 
							loop
								if( to_integer(unsigned(lru_mem(i))) > max ) then
									max := to_integer(unsigned(lru_mem(i)));
									index := i;
								end if;
							end loop;
						
						end if;
						
			--ovde imammo indeks u nizovima kojem pristupamo	

					--azuriramo brojace
						for i in 0 to 2**PRED_EXP-1 
						loop
							--ako su manje od maksimuma, pocecavamo, ako su veci ne diramo ih
							if( to_integer(unsigned(lru_mem(i))) < to_integer(unsigned(lru_mem(index))) ) then
								lru_mem_var(i) := std_logic_vector( unsigned ( lru_mem(i) ) + 1 );
								
								lru_mem(i) <= lru_mem_var(i);
							end if;
						end loop;
					
						--trenutni koji se koristi postaje 0
						lru_mem_var(index) := "00";
						lru_mem(index) <= lru_mem_var(index);
						
			-- azuriramo tag memoriju
						tag_mem_var(index) := pred_update_in.pc;
						tag_mem(index) <= tag_mem_var(index);
			
			-- azuriramo data memoriju ako treba
						--if(state_mem(index) = "01" or state_mem(index) = "10") then
							data_mem_var(index) := pred_update_in.real_jmp_adr;
							data_mem(index) <= data_mem_var(index);
						--end if;
						
					--	azuriramo state	
					if(pred_update_in.jmp = '1') then
						if(unsigned ( state_mem(index) ) < 3) then
							state_mem_var(index) := std_logic_vector( unsigned ( state_mem(index) ) + 1 );
							state_mem(index) <= state_mem_var(index);
						end if;
					else
						if(unsigned ( state_mem(index) ) > 0) then
							state_mem_var(index) := std_logic_vector( unsigned ( state_mem(index) ) - 1 );
							state_mem(index) <= state_mem_var(index);
						end if;
					end if;

					end if;
					
				end if;
			end if;
			
			tag_mem <= tag_mem_var;
			data_mem <= data_mem_var;
			state_mem <= state_mem_var;
			lru_mem <= lru_mem_var;
		end if;
	end process;
	
-- citanje prediktovane vrednosti
	process(pc_in, tag_mem, data_mem) is 
	variable i:integer;
	variable found: boolean;
	variable ind_pred: integer;
	begin
		ind_pred := 0;
		found := false;
		ind_pred := 0;
		for i in 0 to 2**PRED_EXP-1 -- trazimo jednakost
		loop
			if(pc_in = tag_mem(i)) then
				ind_pred := i;
				found := true;
			end if;
		end loop;
		
		if(found) then
			pc_pred <= data_mem(ind_pred);
			hit <= '1';
		else
			pc_pred <= "ZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZZ";
			hit <= '0';
		end if;
		
	end process;

end ArchPredictor;