----------------------------------------------------------------------------------------
-- RAM: 32 rows of 40 bits
-- Simple dual-port: 
--     - simultaneous reading and writing
--     - asynchronous reads: we get data on dataOut immediately after valid addrOut
--     - synchronous writes: data on dataIn are being written at address addrIn 
--                           on a rising edge of the clock and active write-enable (we) 
-- Example: VGA frame buffer
--     - simplification: 30x40 is a 1/16 of the original VGA resolution 480x640
--     - we will declare 32x40 bits RAM but will use only rows 0 to 29
--     - caution: a row is oriented in LSB -> MSB fashion to better model a screen, 
--       where the top-leftmost pixel has an index of 0.
-----------------------------------------------------------------------------------------


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity RAM_32x40 is
    port (
        clk         : in  std_logic;
        we          : in  std_logic;
        addr_write  : in  std_logic_vector (4 downto 0);
        addr_read   : in  std_logic_vector (4 downto 0);
        data_write  : in  std_logic_vector (0 to 479);
        data_read   : out std_logic_vector (0 to 479)
    );
end entity;

architecture Behavioral of RAM_32x40 is
    -- Let's declare an array of words (array of pixel rows)
    -- The leftmost bit in a row has the index 0  
    type RAM_type is array (0 to 31) of std_logic_vector(0 to 479);
    
    -- signal RAM : RAM_type;
    -- If you want to initialize RAM content, use this line instead:
    signal RAM : RAM_type := (others => (others => '0'));
    
begin
    -- asynchronous reading
    data_read <= RAM(to_integer(unsigned(addr_read)));

    -- synchronous writing
    SYNC_PROC: process (clk)
    begin
        if rising_edge(clk) then
            if we='1' then
                RAM(to_integer(unsigned(addr_write))) <= data_write;
            end if;
        end if;
    end process;
end Behavioral;
