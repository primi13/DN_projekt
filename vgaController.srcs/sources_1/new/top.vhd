library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

entity top is
    Port (
        CLK100MHZ  : in std_logic;
        LED        : out std_logic_vector(15 downto 0);
        CPU_RESETN : in STD_LOGIC;
        SW         : in STD_LOGIC_VECTOR(0 downto 0);
        VGA_HS     : out STD_LOGIC;
        VGA_VS     : out STD_LOGIC;
        VGA_R      : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_G      : out STD_LOGIC_VECTOR(3 downto 0);
        VGA_B      : out STD_LOGIC_VECTOR(3 downto 0)
    );
end top;

architecture Behavioral of top is
    signal rst : std_logic;
    constant clk_interval : integer := 10e6;
    signal clk_counter : integer := 0;
    
    -- Signals for lines
    signal start_x : integer := 20;
    signal start_y : integer := 0;
    
    signal line1_x : integer := 20;
    signal line1_y : integer := 20;
    signal line1_rgb : std_logic_vector (0 to 11) := "111001001001";
    
    signal line2_x : integer;
    signal line2_y : integer;
    signal line2_rgb : std_logic_vector (0 to 11);
    
    constant backgroundRGB : std_logic_vector (0 to 11) := "000000000000";
begin

rst <= not CPU_RESETN;

gfx: entity work.gfx
port map (
    CLK100MHZ => CLK100MHZ,
    CPU_RESETN => CPU_RESETN,
    SW => SW,
    VGA_HS => VGA_HS,
    VGA_VS => VGA_VS,
    VGA_R => VGA_R,
    VGA_G => VGA_G,
    VGA_B => VGA_B,
    start_x => start_x,
    start_y => start_y,
    line1_x => line1_x,
    line1_y => line1_y,
    line1_rgb => line1_rgb,
    line2_x => line2_x,
    line2_y => line2_y,
    line2_rgb => line2_rgb,
    backgroundRGB => backgroundRGB
);

process(CLK100MHZ)
    begin
    
    if rising_edge(CLK100MHZ) then
        if clk_counter = clk_interval then
        
            if line1_x = 39 then
                line1_x <= 0;
            else
                line1_x <= line1_x + 1;
            end if;
            
            clk_counter <= 0;
        else
            clk_counter <= clk_counter + 1;
        end if;
    end if;
    
end process;

end Behavioral;
