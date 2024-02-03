----------------------------------------------------------------------------------
-- Krmilnik za VGA - glavni modul
-- Verzija: 2024-01-10
----------------------------------------------------------------------------------

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity vgaController is
    Port ( CLK100MHZ : in STD_LOGIC;
           CPU_RESETN : in STD_LOGIC;
           SW         : in STD_LOGIC_VECTOR(0 downto 0);
           VGA_HS : out STD_LOGIC;
           VGA_VS : out STD_LOGIC;
           VGA_R  : out STD_LOGIC_VECTOR(3 downto 0);
           VGA_G  : out STD_LOGIC_VECTOR(3 downto 0);
           VGA_B  : out STD_LOGIC_VECTOR(3 downto 0)
           );
end vgaController;

architecture Behavioral of vgaController is

signal CE : std_logic;
signal rst : std_logic;
signal display_area_h : std_logic;
signal display_area_v : std_logic;
signal display_area   : std_logic;
signal column : natural range 0 to 639;
signal row    : natural range 0 to 479;

signal WE : std_logic;
signal ADDR_WRITE : std_logic_vector (4 downto 0);
signal ADDR_READ : std_logic_vector (4 downto 0);
signal DATA_WRITE : std_logic_vector (0 to 479);
signal DATA_READ : std_logic_vector (0 to 479);

signal row_scaled : natural range 0 to 31;
signal column_scaled : natural range 0 to 39;

signal currently_drawing_row : natural range 0 to 31 := 0;
signal WE_cycle : natural range 0 to 3 := 0;

signal WL : std_logic := '0';
signal line_x : integer := 0;
signal line_y : integer := 0;

begin
    rst <= not CPU_RESETN;
    
    -- Povezovanje komponent: modula hsync in vsync
    hsync: entity work.hsync
    port map(
        clock => CLK100MHZ, 
        reset => rst,
        clock_enable => CE,
        display_area => display_area_h,
        column => column,
        hsync => VGA_HS
    );
    
    vsync: entity work.vsync
    port map(
        clock => CLK100MHZ, 
        reset => rst,
        clock_enable => CE,
        display_area => display_area_v,
        row => row, 
        vsync => VGA_VS
    );
    
    RAM_32x40: entity work.RAM_32x40
    port map(
        clk => CLK100MHZ,
        we => WE,
        addr_write => ADDR_WRITE,
        addr_read => ADDR_READ,
        data_write => DATA_WRITE,
        data_read => DATA_READ
    );
    
    -- Logika za prižig elektronskih topov (signali RGB)
    display_area <= display_area_h AND display_area_v;
    
    process (SW, display_area, row, column)
    begin
        row_scaled <= (row / 15);
        column_scaled <= (column / 16);
        
        ADDR_READ <= std_logic_vector(to_signed(row_scaled, ADDR_READ'length));
        
        if SW = "0" then
            if display_area = '1' then
                VGA_R <= DATA_READ((column_scaled * 12) to (column_scaled * 12) + 3);
                VGA_G <= DATA_READ(((column_scaled * 12) + 4) to ((column_scaled * 12) + 7));
                VGA_B <= DATA_READ(((column_scaled * 12) + 8) to ((column_scaled * 12) + 11)); 
            else
                VGA_R <= "0000";
                VGA_G <= "0000";
                VGA_B <= "0000";                
            end if;  
        else
            -- bel rob            
            if display_area='1' and (row=0 or row=479 or column=0 or column=639) then    
                VGA_R <= "1111";
                VGA_G <= "1111";
                VGA_B <= "1111";
            else
                VGA_R <= "0000";
                VGA_G <= "0000";
                VGA_B <= "0000";
            end if;
        end if;
    end process;
    
    -- This process is used for drawing stuff
    process(CLK100MHZ)
    begin
        -- 1st tick row gets filled, 2nd tick pause, 3rd tick WE to 0, repeat
        if rising_edge(CLK100MHZ) then
            -- Write to RAM every INTERVAL ticks and set WE to 1
            if WE_cycle = 0 then
                    --DATA_WRITE <= "111001001001111001001001000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000";
                    ADDR_WRITE <= std_logic_vector(to_unsigned(currently_drawing_row, ADDR_WRITE'length)); -- Update the address of the row that we are writing to
                    
                    DATA_WRITE <= (others => '0'); -- Fill the column vector with 0s
                    for j in 0 to 39 loop -- Go through column pixels (each is 12 bits wide)
                        DATA_WRITE((j * 12) to ((j * 12) + 11)) <= "111001001001"; -- RGB for the pixel
                    end loop;
                    
                    WE <= '1';
                    WE_cycle <= 1;
                    
                    -- Increment the row that we are writing to
                    if currently_drawing_row = 31 then
                        currently_drawing_row <= 0;
                    else
                        currently_drawing_row <= currently_drawing_row + 1;
                    end if;                    
                
            -- Wait for 1 tick
            elsif WE_cycle = 1 then
                WE_cycle <= 2;
                
            -- Now set WE to 0
            else
                WE <= '0';
                WE_cycle <= 0;
            end if;
            
        end if;
    end process;
    

end Behavioral;
