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
      blank          : in std_logic;
      row            : in std_logic_vector(10 downto 0);
      column         : in std_logic_vector(10 downto 0);
      ascii_to_write : in std_logic_vector(7 downto 0);
      write_en       : in std_logic;
      r,g,b          : out std_logic_vector(7 downto 0)
	);
end character_gen;

architecture nielsen of character_gen is
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
	
	signal data_out_a, data_out_b : std_logic_vector(6 downto 0);
	signal address : std_logic_vector(10 downto 0);
	signal data : std_logic_vector(7 downto 0);
	
begin
	
	font_rom_top: font_rom
	port map(
		clk => clk,
		addr => "00000000000",
		data => "00000000"
	);
	
	char_screen_buffer_top: char_screen_buffer
	port map(
		clk => clk,
		we => write_en,
		address_a => "00000000000",--  : in std_logic_vector(11 downto 0); -- write address, primary port
		address_b => "00000000000", --: in std_logic_vector(11 downto 0); -- dual read address
		data_in => "00000000",--   : in std_logic_vector(7 downto 0);  -- data input
		data_out_a => "00000000",--: out std_logic_vector(7 downto 0); -- primary data output
		data_out_b => "00000000"--: out std_logic_vector(7 downto 0)  -- dual output port
	);
	

end nielsen;

