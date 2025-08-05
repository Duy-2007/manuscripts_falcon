library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;

entity mq_Add is
    Port (
        clk   : in  std_logic;
        rst   : in  std_logic;
        x     : in  std_logic_vector(31 downto 0);
        y     : in  std_logic_vector(31 downto 0);
        d_out : out std_logic_vector(31 downto 0)
    );
end mq_Add;

architecture Behavioral of mq_Add is
    signal d : unsigned(31 downto 0) := (others => '0');
    constant Q : unsigned(31 downto 0) := to_unsigned(12289, 32);
begin
    process(clk, rst)
        variable temp : unsigned(31 downto 0);
    begin
        if rst = '1' then
            d <= (others => '0');
        elsif rising_edge(clk) then
            temp := unsigned(x) + unsigned(y) - Q;
            if temp(31) = '1' then
                d <= temp + Q;
            else
                d <= temp;
            end if;
        end if;
    end process;

    d_out <= std_logic_vector(d);
end Behavioral;
