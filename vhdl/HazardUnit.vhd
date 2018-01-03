library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use work.ConstPackage.all;

entity HazardUnit is
	port
	(
		reset: in std_logic;
	--iz decode do hu
		stall_id_hu: in std_logic;
		hazard_rec_id_hu: in Record_hazard_ID_HU;
	--iz ostalih do hu
		hazard_rec_ex_hu: in Record_hazard_EX_MEM_WB_HU;
		hazard_rec_mem_hu: in Record_hazard_EX_MEM_WB_HU;
		hazard_rec_wb_hu: in Record_hazard_EX_MEM_WB_HU;
		
	--iz hu do decode
		hazard_rec_hu_id: out Record_hazard_HU_ID;
		stall: out std_logic
	);
end HazardUnit;

architecture ArchHazardUnit of HazardUnit is
	
begin

	process(reset, stall_id_hu, hazard_rec_id_hu, hazard_rec_ex_hu, hazard_rec_mem_hu, hazard_rec_wb_hu) is 
	variable stall_first:boolean;
	variable stall_second:boolean;
	begin
		hazard_rec_hu_id.valid_1 <= '0';
		hazard_rec_hu_id.valid_2 <= '0';
		hazard_rec_hu_id.data_1 <= std_logic_vector(to_unsigned(0, 32));
		hazard_rec_hu_id.data_2 <= std_logic_vector(to_unsigned(0, 32));
		stall_first := false;
		stall_second := false;
		if(reset='1') then
			stall <= '0';
		else
			stall <= stall_id_hu;
		end if;
		if(hazard_rec_id_hu.rd_reg_1 = '1') then
			if(hazard_rec_id_hu.reg_1 = hazard_rec_ex_hu.dst_reg and hazard_rec_ex_hu.wr_dst_reg='1') then
				if(hazard_rec_ex_hu.flush = '0') then
					if(hazard_rec_ex_hu.ready_data = '1') then
						hazard_rec_hu_id.data_1 <= hazard_rec_ex_hu.data;
						hazard_rec_hu_id.valid_1 <= '1';
						stall <= '0';
					else
						--if(hazard_rec_id_hu.reg_1 /= hazard_rec_id_hu.wr_reg) then
							stall <= '1';
							stall_first := true;
						--end if;
					end if;
				end if;
			elsif(hazard_rec_id_hu.reg_1 = hazard_rec_mem_hu.dst_reg and hazard_rec_mem_hu.wr_dst_reg='1') then
				if(hazard_rec_mem_hu.flush = '0') then
					if(hazard_rec_mem_hu.ready_data = '1') then
						hazard_rec_hu_id.data_1 <= hazard_rec_mem_hu.data;
						hazard_rec_hu_id.valid_1 <= '1';
						stall <= '0';
					else
						--if(hazard_rec_id_hu.reg_1 /= hazard_rec_id_hu.wr_reg) then
							stall <= '1';
							stall_first := true;
						--end if;
					end if;
				end if;
			elsif(hazard_rec_id_hu.reg_1 = hazard_rec_wb_hu.dst_reg and hazard_rec_wb_hu.wr_dst_reg='1') then
				if(hazard_rec_wb_hu.flush = '0') then
					if(hazard_rec_wb_hu.ready_data = '1') then
						hazard_rec_hu_id.data_1 <= hazard_rec_wb_hu.data;
						hazard_rec_hu_id.valid_1 <= '1';
						stall <= '0';
					else
						--if(hazard_rec_id_hu.reg_1 /= hazard_rec_id_hu.wr_reg) then
							stall <= '1';
							stall_first := true;
						--end if;
					end if;
				end if;
			else
				hazard_rec_hu_id.valid_1 <= '0';
			end if;
		end if;
		
		if(stall_first = false) then
			if(hazard_rec_id_hu.rd_reg_2 = '1') then
				if(hazard_rec_id_hu.reg_2 = hazard_rec_ex_hu.dst_reg and hazard_rec_ex_hu.wr_dst_reg='1' ) then
					if(hazard_rec_ex_hu.flush = '0') then
						if(hazard_rec_ex_hu.ready_data = '1') then
							hazard_rec_hu_id.data_2 <= hazard_rec_ex_hu.data;
							hazard_rec_hu_id.valid_2 <= '1';
							stall <= '0';
						else
							stall <= '1';
							stall_second := true;
						end if;
					end if;
				elsif(hazard_rec_id_hu.reg_2 = hazard_rec_mem_hu.dst_reg and hazard_rec_mem_hu.wr_dst_reg='1') then
					if(hazard_rec_mem_hu.flush = '0') then
						if(hazard_rec_mem_hu.ready_data = '1') then
							hazard_rec_hu_id.data_2 <= hazard_rec_mem_hu.data;
							hazard_rec_hu_id.valid_2 <= '1';
							stall <= '0';
						else
							stall <= '1';
							stall_second := true;
						end if;
					end if;
				elsif(hazard_rec_id_hu.reg_2 = hazard_rec_wb_hu.dst_reg and hazard_rec_wb_hu.wr_dst_reg='1') then
					if(hazard_rec_wb_hu.flush = '0') then
						if(hazard_rec_wb_hu.ready_data = '1') then
							hazard_rec_hu_id.data_2 <= hazard_rec_wb_hu.data;
							hazard_rec_hu_id.valid_2 <= '1';
							stall <= '0';
						else
							stall <= '1';
							stall_second := true;
						end if;
					end if;
				else
					hazard_rec_hu_id.valid_2 <= '0';
				end if;
			end if;
		end if;
		
		if( stall_first=false and stall_second=false) then
			stall<='0';
		end if;
	end process;
end ArchHazardUnit;
