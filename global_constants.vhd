----------------------------------------------------------------------------------
-- Company:        USAFA
-- Engineer:       Josh Nielsen
-- 
-- Create Date:    10:42:09 01/29/2014 
-- Design Name:    Nielsen
-- Module Name:    global_constants
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
use IEEE.STD_LOGIC_1164.all;

package global_constants is

-- Declare constants
constant h_active_video_pulse : natural := 640;
constant width : natural := 640;
constant h_front_porch_pulse : natural := 16;
constant h_sync_pulse_pulse : natural := 96;
constant h_back_porch_pulse : natural := 48;

constant v_active_video_pulse : natural := 480;
constant height : natural := 480;
constant v_front_porch_pulse : natural := 10;
constant v_sync_pulse_pulse : natural := 2;
constant v_back_porch_pulse : natural := 33;

constant paddle_height : natural := height/6;
constant paddle_width : natural := width/64;
constant ball_size : natural := width/64;

end global_constants;

package body global_constants is

end global_constants;
