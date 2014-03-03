----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    10:28:22 02/25/2014 
-- Design Name: 
-- Module Name:    character_gen - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
library UNISIM;
use UNISIM.VComponents.all;

entity character_gen is
   port (
		clk            : in std_logic;
		reset				: in std_logic;
      blank          : in std_logic;
      row            : in std_logic_vector(10 downto 0);
      column         : in std_logic_vector(10 downto 0);
      ascii_to_write : in std_logic_vector(7 downto 0);
      write_en       : in std_logic;
      r,g,b          : out std_logic_vector(7 downto 0)
	);
end character_gen;

architecture nielsen of character_gen is

	type array2d is array (1 downto 0) of std_logic_vector(10 downto 0);
--	
	signal dff_row, dff_column_one: array2d;

	component font_rom
	port(
		clk: in std_logic;
		addr: in std_logic_vector(10 downto 0);
		data: out std_logic_vector(7 downto 0)
	);
	end component;
	
	component char_screen_buffer
	port (
		clk        : in std_logic;
		we         : in std_logic;                     -- write enable
		address_a  : in std_logic_vector(11 downto 0); -- write address, primary port
		address_b  : in std_logic_vector(11 downto 0); -- dual read address
		data_in    : in std_logic_vector(7 downto 0);  -- data input
		data_out_a : out std_logic_vector(7 downto 0); -- primary data output
		data_out_b : out std_logic_vector(7 downto 0)  -- dual output port
	);
	end component;
	
	signal data_out_a, data_out_b : std_logic_vector(7 downto 0);
	signal address : std_logic_vector(10 downto 0);
	signal data : std_logic_vector(7 downto 0);
	signal address_b_calc_long : std_logic_vector(13 downto 0);
	signal address_b_calc : std_logic_vector(11 downto 0);
	signal internal_count : std_logic_vector(11 downto 0);
	
begin
	
	address <= data_out_b(6 downto 0) & dff_row(0)(3 downto 0);
												--divide by 16									divide by 8
	address_b_calc <= std_logic_vector(resize((unsigned(row(10 downto 4))*80 + unsigned(column(10 downto 3))),12));
	--address_b_calc <= address_b_calc_long(11 downto 0);
	
	internal_count <= (others => '0') when reset = '1' or unsigned(internal_count) = 2400 else
							std_logic_vector(unsigned(internal_count) + 1) when write_en = '1' else
							internal_count;
	
	process (clk)	
	begin	
		if(rising_edge(clk)) then
			dff_row(1) <= dff_row(0);--delay 2 cycles (unnecessary)
			dff_row(0) <= row;--delay 1 cycle
		end if;
	end process;
	
	process (clk)	
	begin	
		if(rising_edge(clk)) then
			dff_column_one(1) <= dff_column_one(0);--delay 2 cycles
			dff_column_one(0) <= column;--delay 1 cycle
		end if;
	end process;
	
	font_rom_top: font_rom
	port map(
		clk => clk,
		addr => address,
		data => data
	);
	
	char_screen_buffer_top: char_screen_buffer
	port map(
		clk => clk,
		we => write_en,
		address_a => "000000000001",--  : in std_logic_vector(11 downto 0); -- write address, primary port
		address_b => address_b_calc, --: in std_logic_vector(11 downto 0); -- dual read address
		data_in => ascii_to_write,--   : in std_logic_vector(7 downto 0);  -- data input
		data_out_a => data_out_a,--: out std_logic_vector(7 downto 0); -- primary data output
		data_out_b => data_out_b--: out std_logic_vector(7 downto 0)  -- dual output port
	);
	
--	process (clk, write_en) is
--	begin
--		if rising_edge(clk) then
--			if (reset = '1') then
--				internal_count <= (others => '0');
--			elsif (write_en = '1') then
--				internal_count <= std_logic_vector(unsigned(internal_count) + 1);
--			elsif (unsigned(internal_count) = 2400) then
--				internal_count <= (others => '0');
--			end if;
--			else
--		end if;
--	end process;
	
	r	<=	data(7) & "0000000" when dff_column_one(1)(2 downto 0) = "000" else-- fix zeros
			data(6) & "0000000" when dff_column_one(1)(2 downto 0) = "001" else	
			data(5) & "0000000" when dff_column_one(1)(2 downto 0) = "010" else
			data(4) & "0000000" when dff_column_one(1)(2 downto 0) = "011" else
			data(3) & "0000000" when dff_column_one(1)(2 downto 0) = "100" else
			data(2) & "0000000" when dff_column_one(1)(2 downto 0) = "101" else
			data(1) & "0000000" when dff_column_one(1)(2 downto 0) = "110" else
			data(0) & "0000000" when dff_column_one(1)(2 downto 0) = "111" else
			(others => '0');
	
	g	<=	(others => '0');
	b	<=	(others => '0');

end nielsen;

