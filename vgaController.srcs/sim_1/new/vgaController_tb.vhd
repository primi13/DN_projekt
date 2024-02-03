----------------------------------------------------------------------------------
-- Simulacija krmilnika za VGA - test bench
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity vgaController_tb is
    --  Port ( );
end entity;

architecture Behavioral of vgaController_tb is
    ----------------------------------------------------------------------------------
    -- KONSTANTE
    ----------------------------------------------------------------------------------
    constant clock_period : time := 10ns;
    
    ----------------------------------------------------------------------------------
    -- NOTRANJI SIGNALI
    ----------------------------------------------------------------------------------
    -- Signali, ki povezujejo vhode UUT z generatorjem stimulusov
    signal clk_sim, reset_sim : std_logic := '0';
    signal sw_sim : std_logic_vector(0 downto 0) := "0";
    -- Signali, ki povezujejo izhode UUT z osciloskopom (waveform)
    signal hsync_sim, vsync_sim : std_logic := '0';
    signal red_sim, green_sim, blue_sim: std_logic_vector(3 downto 0) := "0000";

begin
    -- instanciacija modula, ki ga testiramo
    UUT: entity work.vgaController
        port map(
            CLK100MHZ  => clk_sim,
            CPU_RESETN => reset_sim,
            SW         => sw_sim,
            VGA_HS     => hsync_sim,
            VGA_VS     => vsync_sim,
            VGA_R      => red_sim,
            VGA_G      => green_sim,
            VGA_B      => blue_sim
        );

    -- Generator stimulusov (dražljajev) = scenarij poteka signalov 
    -- 1. Ura 
    clk_stimuli: process
    begin
        clk_sim <= '0';
        wait for clock_period/2;
        clk_sim <= '1';
        wait for clock_period/2;
        -- alternativa:
        --clk_sim <= not clk_sim;
        --wait for clock_period/2;
    end process;

    -- 2. Ostali signali
    other_stimuli: process
    begin
        -- dolgi reset (za 3 u.p.)
        -- Reset je aktiven, ko je 0 (CPU_RESETN)
        reset_sim <= '0';
        
        wait for clock_period*3;

        -- reset umaknemo
        reset_sim <= '1';
        -- Testiramo stikalo
        sw_sim <= "0";
        wait for 17 ms; -- izris enega zaslona (60 Hz)
        sw_sim <= "1";
        -- čakaj v neskončnost
        wait;
    end process;
end Behavioral;