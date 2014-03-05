#Introduction

The goal of this code repository is to expand upon the VGA lab assignment by implementing a font controller. For base functionality, the code must be able to display a 80x30 grid of ASCII characters within the 640x480 screen resolution. For B functionality, the implementation must be expanded to include using a denounced button to select characters based upon the configuration of the switches on the FPGA. Finally, to achieve A functionality, it must be possible to use a NES controller to select the current position of an invisible cursor and change the character at the cursor’s position.
#Implementation
Much of this lab’s functionality is based upon the functionality of [lab 1] (https://github.com/aapljosh/lab01). This previous lab provided the basis for outputting to a display. Without it there would be no sense in even trying to implement a font controller on the Spartan 6. 

The modules associated with the font controller are slightly different that those of the previous labs. Instead of having a pixel_gen module for displaying pixels and a logic module for determining the game logic as with [Pong] (https://github.com/aapljosh/lab02), there is a single module (character_gen) that takes in the current row, column, and desired ASCII character to write and outputs proper values for r, g, and b.

Almost all of the new material necessary to complete this lab is contained within the character_gen module:
![character_gen]( http://ece383.com/labs/lab3/figure3.jpg)
Documentation: Lab 3 - Font Controller

Both the screen-buffer and font_ROM modules were provided.  This meant that all that was really necessary to get this to work was to hook up the signals properly. I decided to simply hook up signals first without the DFF in place to see if I could get characters to display. That was I could be sure that I was making progress on my code. The trickiest part here was figuring out the combinational logic to send to address_b of the screen buffer and how to combine the desired row with the output of the screen_buffer:  

```vhdl
address <= data_out_b(6 downto 0) & dff_row(0)(3 downto 0);		                
address_b_calc <= std_logic_vector(resize((unsigned(row(10 downto 4))*80 + unsigned(column(10 downto 3))),12));
```

Notice how the internal address’s upper bit are the output of data and the lower bit are the last four bits of the row signal. This ensures that the font_ROM matches the proper memory location with the proper character and displays it in the proper location on the screen.  Address_b_calc needs to return the memory location that corresponds to the current row/column input.  They are laid out as follows:

![grid]( http://ece383.com/labs/lab3/figure2.jpg)
Documentation: Lab 3 - Font Controller

For row we can ignore the lower 4 bits and for column we can ignore the lower 3 bits because they have no impact on the location we care about because the characters are 8 pixels wide and 16 pixels tall. Multiplying row by 80 and then adding upper 8 bits of column accomplishes the desired function. This took some time to see, but once you think about it for more than a few seconds it intuitively makes sense. For values of 0 to 15 row multiplied by 80 returns zero. We then shift to the right however much column/ 8 is and we end up in the proper location. 

The next interesting thing to note is how the 8-to-1 mux operates. The issue we have here is that the screen is little endian and the characters are stored big endian, therefore the we need a mux to output the memory locations to the proper pixels:

```vhdl
r	<=	data(7) & "0000000" when dff_column_one(1)(2 downto 0) = "000" else
			data(6) & "0000000" when dff_column_one(1)(2 downto 0) = "001" else	
			data(5) & "0000000" when dff_column_one(1)(2 downto 0) = "010" else
			data(4) & "0000000" when dff_column_one(1)(2 downto 0) = "011" else
			data(3) & "0000000" when dff_column_one(1)(2 downto 0) = "100" else
			data(2) & "0000000" when dff_column_one(1)(2 downto 0) = "101" else
			data(1) & "0000000" when dff_column_one(1)(2 downto 0) = "110" else
			data(0) & "0000000" when dff_column_one(1)(2 downto 0) = "111" else
			(others => '0');
```

At this point simply hooking up character gen to the existing vga code produced the desire results. However, this is only because I made the mistake of sending the fast clock (100MHz) to the character_gen module instead of pixel_clk which is 4 times slower.  When I realized this and fied it everything actually stopped working and I needed to add delays to fix the off by 2 error. To fix this I needed to allow time for memory access by adding delays. I coded this as follows:

 ```vhdl
type array2d is array (1 downto 0) of std_logic;
…
process (clk)	
	begin	
		if(rising_edge(clk)) then
			dff_column_one(1) <= dff_column_one(0);--delay 2 cycles
			dff_column_one(0) <= column;--delay 1 cycle
		end if;
	end process;
```
Once I did the same thing for the v_sync, h_sync and blank signals in the top level, everything displayed beautifully. 

Finally I could move on to the other parts of the lab. B functionality was farily strait forward. All I had to do was add the FPGA’s switches to the constraints file and make the desired ascii character to write be based off of that. 

```vhdl
ascii_to_write	=> SW7&SW6&SW5&SW4&SW3&SW2&SW1&SW0,
```	

I then attached the write enable bit of the character_gen module to a denounced button input. Whenever the button was pressed the 8-bit character specified by the switches was written to memory and subsequently written to the screen.  Here is how I debounced the button:

```vhdl
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

end Behavioral;```	

Basically, a shift register incremented every 20000 clock cycles was used. Whenever the shift register’s msb became a ‘1’, the output went to ‘1’ for one clock cycle.

To achieve ‘A’ functionality I used the provided nes_controller code. The proper signals were added to the constraints file and were sent into the character_gen module.  Up and Down control what character is displayed while left and right switch the cursor’s location. I had to limit the speed at which characters and cursor locations switched by latching left/right to only move one space at a time and by only updating the current character every 4000000 clock cycles. Here is the specific code:

```vhdl
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
```	
 The overall machine looks like this:

![ capture1]( /Capture1.png)
![ capture1]( /Capture2.png)

#Test/Debug
- Aside from hooking up signals incorrectly, the first real problem I ran into was the fact that characters displayed perfectly without any delay circuitry. I knew something wasn’t right. Upon further examination, I realized I was sending clk (100MHz) to character_gen instead of pixel_clk (25MHz). This was making it so my latched button press acted weird so I had to add the delay circuitry and switch to using pixel_clk.
- The off by two manifested itself as the characters being shifted two pixels from where they should have been. I fixed this simply by adding 1 cycle delays. 
- The next major proplem that I spent far too much time on was that my input_to_pulse module was testbenchable but not synthesizable.  I used a ‘wait 1ms statement’ which is fine for testbenches, but will not synthesize. 
- Other than the input_to_pulse module, everything was tested through the LCD. There were just too many signals to test any other way. As long as something is being displayed it is farily easy to see what is wrong (mostly the whole off by 2 thing). 
#Conclusion
Of the Labs we have doe=ne so far, I spent 6he elast amount of time on this one. I believe this is for several reasons. First, I think I am getting better at VHDL (Yay!). Second, I worked with a SNES controller last year and that helped me know intuitively how to work with an NES controller in this lab. Lastly, most of this lab was simply looking at the diagram and hooking up signals. The only real original work that I felt was unique was my input_to_pulse module and my implementation of the controller within character_gen. 

The most difficult part for me was actually when everything worked when I did not expect it to. Finding error when things are working is far more difficult than finding them when things aren’t working.  

This lab introduced several concepts that I think are important.  I had not ever really thought before about having a grid within a grid when it comes to displaying things. Also, the concept of delaying signals to make sure everything lines up is important, especially for designs that are larger than this one. 
 

