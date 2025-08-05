library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity baudrate_generator is
    generic (
        CLOCK_FREQ : integer := 50000000;  
        BAUD_RATE  : integer := 9600      
    );
    port (
        clk      : in std_logic;
        reset    : in std_logic;
        tick : out std_logic
    );
end entity;

architecture behavior of baudrate_generator is
    constant BAUD_PERIOD : integer := CLOCK_FREQ / BAUD_RATE;
    signal counter : integer := 0;
begin
    process (clk, reset)
    begin
        if reset = '1' then
            counter <= 0;
            tick <= '0';
        elsif rising_edge(clk) then
            if counter = BAUD_PERIOD - 1 then
                counter <= 0;
                tick <= '1';
            else
                counter <= counter + 1;
                tick <= '0';
            end if;
        end if;
    end process;
end architecture;