
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity hsync_tb is
end hsync_tb;

architecture Behavioral of hsync_tb is

constant clock_period : time := 10 ns;

-- vhodi v testiran modul
signal CLK100MHZ : std_logic;
signal CPU_RESET : std_logic;

-- izhodi modula, ki gredo na "osciloskop"
signal hsync_out : std_logic;

begin

    -- Ustvarimo instanco modula (entitetni način)
    UUT: entity work.hsync(Behavioral)
    port map(
        clock => CLK100MHZ, 
        reset => CPU_RESET, 
        hsync => hsync_out
    );
    
    -- opišemo spreminjanje dražljajev (stimuli)
    -- ustvarimo uro
    clock_stimulus: process  
    begin
        CLK100MHZ <= '0';
        wait for clock_period/2;
        CLK100MHZ <= '1';
        wait for clock_period/2;
    end process;
    
    -- ostali dražljaji
    other_stimuli: process  
    begin
        -- dolg reset na začetku
        CPU_RESET <= '1';
        wait for 4*clock_period;
        
        CPU_RESET <= '0';
        wait;
    end process;
    

end Behavioral;
