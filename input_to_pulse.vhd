----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    22:02:36 02/24/2014 
-- Design Name: 
-- Module Name:    input_to_pulse - Behavioral 
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
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity input_to_pulse is

	generic (
		SHIFT_SIZE : natural := 8
	);

	port (
		clk		: in std_logic;
		reset		: in std_logic;
		input		: in std_logic;
		output	: out std_logic
	);
end input_to_pulse;

architecture Behavioral of input_to_pulse is

--Documentation: http://www.edaboard.com/thread135501.html	
-- Build an array type for the shift register
type shift_register_size is array ((SHIFT_SIZE-1) downto 0) of std_logic;

-- Declare the shift register signal
signal shift: shift_register_size;
signal first_output, first_push: boolean;

signal count: integer := 0;

begin

	process (clk)	
	begin	
		if(rising_edge(clk)) then
			if count <= 20000 then
				count <= count + 1;
			else
				count <= 0;
			end if;
		end if;
	end process;

	shift_proc: process				
	begin	
		if(rising_edge(clk)) and count = 20000 then
			if (reset = '1') then
				first_push <= true;
			elsif(input = '1') then	
				-- Shift data by one stage; data from last stage is lost
				shift((SHIFT_SIZE-1) downto 1) <= shift((SHIFT_SIZE-2) downto 0);
				-- Load new data into the first stage
				shift(0) <= '1';
				if(shift(SHIFT_SIZE-1) = '1') then
					first_push <= false;
				end if;
			else
				shift <= (others => '0');
				first_push <= true;
			end if;	
		end if;
	end process;


	process(clk, shift)
		variable rising : boolean;
	begin
		if(rising_edge(clk)) then
			output <= '0';
			if reset = '1' then
				first_output <= true;
			elsif shift(SHIFT_SIZE-1) = '1' then
				if first_output then
					output <= '1';
					first_output <= false;
				end if;
			elsif shift(SHIFT_SIZE-1) = '0' then
				first_output <= true;
			end if;
		end if;
	end process;

end Behavioral;