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
		clk            	: in std_logic;
		reset					: in std_logic;
      blank          	: in std_logic;
      row            	: in std_logic_vector(10 downto 0);
      column         	: in std_logic_vector(10 downto 0);
      ascii_to_write 	: in std_logic_vector(7 downto 0);
      write_en       	: in std_logic;
		up,down,left,right: in std_logic;
      r,g,b          	: out std_logic_vector(7 downto 0)
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
	signal address_b_calc : std_logic_vector(11 downto 0);
	signal internal_count : std_logic_vector(11 downto 0);
	
	signal count: integer := 0;
	constant speed: integer := 4000000;
	
	signal internal_character: std_logic_vector(7 downto 0);
	
	signal internal_en: std_logic;
	signal change_char: boolean;
	
begin

	process (clk)	
	begin	
		if(rising_edge(clk)) then
			if count <= speed then
				count <= count + 1;
			else
				count <= 0;
			end if;
		end if;
	end process;
	
	address <= data_out_b(6 downto 0) & dff_row(0)(3 downto 0);
												                   --divide by 16								 divide by 8
	address_b_calc <= std_logic_vector(resize((unsigned(row(10 downto 4))*80 + unsigned(column(10 downto 3))),12));
	
	internal_en <= '1' when up = '1' or down = '1' else
						'0';
	
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
		we => internal_en,
		address_a => internal_count,--  : in std_logic_vector(11 downto 0); -- write address, primary port
		address_b => address_b_calc, --: in std_logic_vector(11 downto 0); -- dual read address
		data_in => internal_character,--   : in std_logic_vector(7 downto 0);  -- data input
		data_out_a => data_out_a,--: out std_logic_vector(7 downto 0); -- primary data output
		data_out_b => data_out_b--: out std_logic_vector(7 downto 0)  -- dual output port
	);
	
	process (clk, left, right) is
		--variable change_char : boolean;
	begin
		if rising_edge(clk) then
			if (reset = '1') then
				internal_count <= (others => '0');
				change_char <= false;
			elsif (right = '1' and count = speed and change_char = true) then--
				internal_count <= std_logic_vector(unsigned(internal_count) + 1);
				change_char <= false;
			elsif (left = '1' and count = speed and change_char = true) then--and change_char = true
				if (unsigned(internal_count) <= 2399) then
					internal_count <= std_logic_vector(unsigned(internal_count) - 1);
				elsif(unsigned(internal_count) = 0) then
					internal_count <= (others => '0');
				end if;
				change_char <= false;
			elsif (left = '0' and right = '0') then
				change_char <= true;
			end if;
		end if;
	end process;
	
	process (clk, up, down) is
	begin
		if rising_edge(clk) then
			if (reset = '1') then
				internal_character <= "01000001";--A
			elsif (down = '1' and count = speed) then
				internal_character <= std_logic_vector(unsigned(internal_character) + 1);
			elsif (up = '1' and count = speed) then
				internal_character <= std_logic_vector(unsigned(internal_character) - 1);
			end if;
		end if;
	end process;
	
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

