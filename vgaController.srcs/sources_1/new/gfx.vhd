library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity gfx is
    port ( CLK100MHZ : in STD_LOGIC;
           CPU_RESETN : in STD_LOGIC;
           SW         : in STD_LOGIC_VECTOR(0 downto 0);
           VGA_HS : out STD_LOGIC;
           VGA_VS : out STD_LOGIC;
           VGA_R  : out STD_LOGIC_VECTOR(3 downto 0);
           VGA_G  : out STD_LOGIC_VECTOR(3 downto 0);
           VGA_B  : out STD_LOGIC_VECTOR(3 downto 0);
           
           start_x : integer;
           start_y : integer;
           
           line1_x : integer;
           line1_y : integer;
           line1_rgb : std_logic_vector (0 to 11);

           line2_x : integer;
           line2_y : integer;
           line2_rgb : std_logic_vector (0 to 11);
           
           backgroundRGB : std_logic_vector (0 to 11)
    );
end gfx;

architecture Behavioral of gfx is
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
    
-- Function that makes a color darker
function darken(inputColor: std_logic_vector(11 downto 0)) return std_logic_vector is
    variable r, g, b: std_logic_vector(0 to 3);
    begin
        -- Extract RGB components from the input color
        r := inputColor(11 downto 8);
        g := inputColor(7 downto 4);
        b := inputColor(3 downto 0);
    
        -- Make each color component 50% darker
        r := std_logic_vector(shift_right(unsigned(r), 2));
        g := std_logic_vector(shift_right(unsigned(g), 2));
        b := std_logic_vector(shift_right(unsigned(b), 2));
    
        -- Recombine the components into a single 12-bit color
        return (r & g & b); -- Concatenate the darker components
end darken;
    
    
-- Functions used for telling for a pixel if line goes through it or not
    -- Better one
--function should_place_dot(x, y, in_x0, in_y0, in_x1, in_y1: integer) return boolean is
--    variable dx, dy, sx, sy, err, e2: integer;
--    variable x0, y0, x1, y1: integer;
    
--	begin
--        x0 := in_x0;
--        y0 := in_y0;
--        x1 := in_x1;
--        y1 := in_y1;
--		dx := abs(x1 - x0); -- VHDL's abs function computes the absolute value
--		dy := -(abs(y1 - y0));
--		if x0 < x1 then
--			sx := 1;
--		else
--			sx := -1;
--		end if;
--		if y0 < y1 then
--			sy := 1;
--		else
--			sy := -1;
--		end if;
--		err := dx + dy;
		
--		for i in 0 to 52 loop
--			if x0 = x and y0 = y then
--				return true; -- The function returns true if the current point matches
--			end if;
--			if x0 = x1 and y0 = y1 then
--				exit; -- Exit the loop if the end point is reached
--			end if;
--			e2 := 2 * err;
--			if e2 >= dy then
--				err := err + dy;
--				x0 := x0 + sx;
--			end if;
--			if e2 <= dx then
--				err := err + dx;
--				y0 := y0 + sy;
--			end if;
--		end loop;
		
--		return false; -- Return false if the point does not match
--end function;

    -- Fast one
function min(a, b: integer) return integer is
begin
    if a < b then
        return a;
    else
        return b;
    end if;
end function;

function max(a, b: integer) return integer is
begin
    if a > b then
        return a;
    else
        return b;
    end if;
end function;

function should_place_dot(x, y, in_x0, in_y0, in_x1, in_y1: integer) return boolean is
    variable m, b, y_line: integer;
    variable is_vertical_line: boolean;
    variable x0, y0, x1, y1: integer;
    begin
        x0 := in_x0;
        y0 := in_y0;
        x1 := in_x1;
        y1 := in_y1;
        m := 0;
        b := 0;
        y_line := 0;
        
        -- Check if start or end point
        if (x = x0 and y = y0) or (x = x1 and y = y1) then
            return true;
        end if;
        
        -- Check for a vertical line
        if x0 = x1 then
            is_vertical_line := true;
        else
            is_vertical_line := false;
            -- Calculate slope (m) and y-intercept (b), scaled by 1000 for precision
            m := (y1 - y0) * 1000 / (x1 - x0);
            b := y0 * 1000 - m * x0;
        end if;
    
        if is_vertical_line then
            -- For vertical lines, just check if x matches and y is within bounds
            if x = x0 and y >= min(y0, y1) and y <= max(y0, y1) then
                return true;
            else
                return false;
            end if;
        else
            -- Calculate y value on the line for given x, and compare with actual y
            y_line := (m * x + b) / 1000; -- Adjusting back the scaling
            -- Check if the calculated y_line matches the input y within a tolerance
            if abs(y - y_line) <= 0 then -- Tolerance of 0 units
                -- Additionally, ensure x is within the segment's x bounds
                if x >= min(x0, x1) and x <= max(x0, x1) then
                    return true;
                end if;
            end if;
            return false;
        end if;
end function;

    
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
                    
                        -- Ball 1:
                            -- Outer layer
                        if (abs(currently_drawing_row - line1_y) = 2 and abs(j - line1_x) < 2) or (abs(currently_drawing_row - line1_y) < 2 and abs(j - line1_x) = 2) then
                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= darken(line1_rgb); 
                        end if;
                            -- Core    
                        if abs(currently_drawing_row - line1_y) <= 1 and abs(j - line1_x) <= 1 then
                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= line1_rgb;
                        end if; 
                            -- Line
                        if should_place_dot(j, currently_drawing_row, start_x, start_y, line1_x, line1_y) = true then
                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= line1_rgb; -- RGB for the pixel
                        end if;        
                        
                        -- Ball 2:
                            -- Outer layer   
                        if (abs(currently_drawing_row - line2_y) = 2 and abs(j - line2_x) < 2) or (abs(currently_drawing_row - line2_y) < 2 and abs(j - line2_x) = 2) then
                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= darken(line2_rgb);
                        end if; 
                            -- Core
                        if abs(currently_drawing_row - line2_y) <= 1 and abs(j - line2_x) <= 1 then
                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= line2_rgb;
                        end if;
                            -- Line
                        if should_place_dot(j, currently_drawing_row, start_x, start_y, line2_x, line2_y) = true then
                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= line2_rgb; -- RGB for the pixel
                        end if;
                                                          
--                        -- Draw the ball outer layer
--                        if (abs(currently_drawing_row - line1_y) = 2 and abs(j - line1_x) < 2) or (abs(currently_drawing_row - line1_y) < 2 and abs(j - line1_x) = 2) then
--                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= darken(line1_rgb);
--                        elsif (abs(currently_drawing_row - line2_y) = 2 and abs(j - line2_x) < 2) or (abs(currently_drawing_row - line2_y) < 2 and abs(j - line2_x) = 2) then
--                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= darken(line2_rgb);
--                        end if; 
                        
--                        -- Line pixels
--                        if should_place_dot(j, currently_drawing_row, start_x, start_y, line1_x, line1_y) = true then
--                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= line1_rgb; -- RGB for the pixel
--                        end if;
                        
--                        if should_place_dot(j, currently_drawing_row, start_x, start_y, line2_x, line2_y) = true then
--                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= line2_rgb; -- RGB for the pixel
--                        end if;
                                              
--                        -- Draw the ball core
--                        if abs(currently_drawing_row - line1_y) <= 1 and abs(j - line1_x) <= 1 then
--                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= line1_rgb;
--                        elsif abs(currently_drawing_row - line2_y) <= 1 and abs(j - line2_x) <= 1 then
--                            DATA_WRITE((j * 12) to ((j * 12) + 11)) <= line2_rgb;
--                        end if;
                                                                        
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
