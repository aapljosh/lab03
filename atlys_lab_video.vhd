----------------------------------------------------------------------------------
-- Company:        USAFA
-- Engineer:       Josh Nielsen
-- 
-- Create Date:    10:42:09 01/29/2014 
-- Design Name:    Nielsen
-- Module Name:    atlys_lab_font_controller
-- Project Name:   Lab 02
-- Target Devices: Spartan 6
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
Library UNISIM;
use UNISIM.vcomponents.all;
use IEEE.NUMERIC_STD.ALL;

entity atlys_lab_font_controller is
	port (
      clk   : in  std_logic; -- 100 MHz
      reset : in  std_logic;
		count : in  std_logic;
		SW0,SW1,SW2,SW3,SW4,SW5,SW6,SW7 : in std_logic;
      tmds  : out std_logic_vector(3 downto 0);
      tmdsb : out std_logic_vector(3 downto 0)
	);
end atlys_lab_font_controller;

architecture nielsen of atlys_lab_font_controller is
  
	type array2d is array (1 downto 0) of std_logic;
	
	signal	dff_h_sync_one, 
				dff_v_sync_one,
				dff_v_completed_one,
				dff_blank_one: array2d;

	signal shift_clk, pixel_clk, serialize_clk, serialize_clk_n, blank, h_sync, v_sync, 
	        red_s, green_s, blue_s, clock_s : std_logic;
	signal red, green, blue : std_logic_vector(7 downto 0);
	signal row, column : unsigned(10 downto 0);
	signal db_pulse : std_logic;
	
	signal h_sync_sig, v_sync_sig, v_completed_sig, blank_sig : std_logic;
	
	 
	component vga_sync
       port ( 
		    clk         : in  std_logic;
          reset       : in  std_logic;
          h_sync      : out std_logic;
          v_sync      : out std_logic;
          v_completed : out std_logic;
          blank       : out std_logic;
          row         : out unsigned(10 downto 0);
          column      : out unsigned(10 downto 0)
       );
   end component;
	 
	component character_gen	
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
   end component;
	
	component input_to_pulse
		port (
			clk		: in std_logic;
			reset		: in std_logic;
			input		: in std_logic;
			output	: out std_logic
		);
	end component;
			
begin
	
	-----------------------DELAY--------------------------------
	process (pixel_clk)	
	begin	
		if(rising_edge(pixel_clk)) then
			dff_h_sync_one(1) <= dff_h_sync_one(0);
			dff_h_sync_one(0) <= h_sync_sig;
		end if;
	end process;
	
	process (pixel_clk)	
	begin	
		if(rising_edge(pixel_clk)) then
			dff_v_sync_one(1) <= dff_v_sync_one(0);
			dff_v_sync_one(0) <= v_sync_sig;
		end if;
	end process;
	
	process (pixel_clk)	
	begin	
		if(rising_edge(pixel_clk)) then
			dff_v_completed_one(1) <= dff_v_completed_one(0);
			dff_v_completed_one(0) <= v_completed_sig;
		end if;
	end process;

	process (pixel_clk)	
	begin	
		if(rising_edge(pixel_clk)) then
			dff_blank_one(1) <= dff_blank_one(0);
			dff_blank_one(0) <= blank_sig;
		end if;
	end process;

	------------------------------------------------------------
	-- Clock divider - creates pixel clock from 100MHz clock
    inst_DCM_shift: DCM
    generic map(
		CLKFX_MULTIPLY => 1,
		CLKFX_DIVIDE   => 100000,
		CLK_FEEDBACK   => "1X"
		)
    port map(
		clkin => clk,
		rst   => reset,
		clkfx => shift_clk --1KHz
		);
	
    -- Clock divider - creates pixel clock from 100MHz clock
    inst_DCM_pixel: DCM
    generic map(
		CLKFX_MULTIPLY => 2,
		CLKFX_DIVIDE   => 8,
		CLK_FEEDBACK   => "1X"
		)
    port map(
		clkin => clk,
		rst   => reset,
		clkfx => pixel_clk --25MHz
		);

    -- Clock divider - creates HDMI serial output clock
    inst_DCM_serialize: DCM
    generic map(
	    CLKFX_MULTIPLY => 10, -- 5x speed of pixel clock
	    CLKFX_DIVIDE   => 8,
	    CLK_FEEDBACK   => "1X"
        )
    port map(
            clkin => clk,
            rst   => reset,
            clkfx => serialize_clk, --125MHz
            clkfx180 => serialize_clk_n
        );
				
	 --vga_sync port map		
    vga_sync_top: vga_sync 
	 port map(
	    clk => pixel_clk,
	    reset => reset,
	    h_sync => h_sync_sig,
	    v_sync => v_sync_sig,
	    v_completed => v_completed_sig,
	    blank => blank_sig,
	    row => row,
	    column => column 
	 );
	 
	character_gen_top: character_gen
	port map(
		clk => pixel_clk,
		reset => reset,
		blank => blank,
		ascii_to_write	=> SW7&SW6&SW5&SW4&SW3&SW2&SW1&SW0,--part B
		write_en => '1',--button push here
		row => std_logic_vector(row),
		column => std_logic_vector(column), 
	   r => red,
	   g => green,
	   b => blue
	);
	
	input_to_pulse_top: input_to_pulse
	port map(
		clk => pixel_clk,
		reset => reset,
		input => count,
		output => db_pulse
	);
	
	
    -- Convert VGA signals to HDMI (actually, DVID ... but close enough)
    inst_dvid: entity work.dvid
    port map(
		clk       => serialize_clk,
		clk_n     => serialize_clk_n, 
		clk_pixel => pixel_clk,
		red_p     => red,
		green_p   => green,
		blue_p    => blue,
		blank     => dff_blank_one(1),
		hsync     => dff_h_sync_one(1),
		vsync     => dff_v_sync_one(1),
		-- outputs to TMDS drivers
		red_s     => red_s,
		green_s   => green_s,
		blue_s    => blue_s,
		clock_s   => clock_s
        );

    -- Output the HDMI data on differential signalling pins
    OBUFDS_blue  : OBUFDS port map
        ( O  => TMDS(0), OB => TMDSB(0), I  => blue_s  );
    OBUFDS_red   : OBUFDS port map
        ( O  => TMDS(1), OB => TMDSB(1), I  => green_s );
    OBUFDS_green : OBUFDS port map
        ( O  => TMDS(2), OB => TMDSB(2), I  => red_s   );
    OBUFDS_clock : OBUFDS port map
        ( O  => TMDS(3), OB => TMDSB(3), I  => clock_s );

end nielsen;