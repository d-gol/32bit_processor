library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity RegisterFile is
	port
	(
		adr_rs_1 : in std_logic_vector(4 downto 0); --adr register source 1
		adr_rs_2 : in std_logic_vector(4 downto 0); --adr register source 2
		adr_rd   : in std_logic_vector(4 downto 0); --adr register destination 1 --mora da ide jer to se prenosi dalje
		
		data_wr_in : in std_logic_vector(D_BUS_WIDTH downto 0); -- Iz wb faze
		adr_wr_in  : in std_logic_vector(4 downto 0); -- Iz wb faze
		wr_reg_in	 : in std_logic; -- iz wb, da li je potrebno upisati u registar
		
		data_rs_1_out: out std_logic_vector(D_BUS_WIDTH downto 0); --salje se u ID fazu
		data_rs_2_out: out std_logic_vector(D_BUS_WIDTH downto 0)
	);
	
end RegisterFile;

architecture archRegisterFile of RegisterFile is
	type registerFile is array(0 to 31) of std_logic_vector(D_BUS_WIDTH downto 0);
	signal registers : registerFile  := (others => (others => '0'));
begin
	data_rs_1_out <= registers(to_integer(unsigned(adr_rs_1)));
	data_rs_2_out <= registers(to_integer(unsigned(adr_rs_2)));
	
	process(adr_wr_in, wr_reg_in, data_wr_in) is
	begin
		if(wr_reg_in='1') then
			registers(to_integer(unsigned(adr_wr_in))) <= data_wr_in;
		end if;
	end process;

end archRegisterFile;

