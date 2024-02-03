----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date: 02/02/2024 06:14:19 PM
-- Design Name: 
-- Module Name: FrameBuffer - Behavioral
-- Project Name: 
-- Target Devices: 
-- Tool Versions: 
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

entity FrameBuffer is
  Port (
  clock : in STD_LOGIC
  );
end FrameBuffer;

architecture Behavioral of FrameBuffer is
    type RAM_type is array (0 to 31) of std_logic_vector(0 to 39);
begin


end Behavioral;
