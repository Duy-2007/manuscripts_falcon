library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity random_seed is
    Port (
        clk    : in  std_logic;
        rst    : in  std_logic;
        en     : in  std_logic;  
        data   : out std_logic_vector(7 downto 0)
    );
end random_seed;

architecture Behavioral of random_seed is

    -- Signal declaration
    signal r_data : std_logic_vector(7 downto 0) := "00000001";  
begin

    -- Random number generation process
    process(clk, rst)
    begin
        if rst = '1' then
            r_data <= "00000001";
        elsif rising_edge(clk) then
            if en = '1' then
                r_data(0) <= r_data(7);
                r_data(1) <= r_data(0);
                r_data(2) <= r_data(1);
                r_data(3) <= r_data(2) xor r_data(7); 
                r_data(4) <= r_data(3);
                r_data(5) <= r_data(4) xor r_data(7); 
                r_data(6) <= r_data(5);
                r_data(7) <= r_data(6) xor r_data(0);
            end if;
        end if;
    end process;

    -- Output the random data
    data <= r_data;

end Behavioral;
