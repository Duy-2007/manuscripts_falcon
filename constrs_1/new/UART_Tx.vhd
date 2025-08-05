library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_tx is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        baud_tick   : in std_logic;                  
        tx_start    : in std_logic;                  
        tx_data     : in std_logic_vector(7 downto 0); 
        tx          : out std_logic;                
        tx_done     : out std_logic                 
    );
end UART_tx;

architecture behavior of UART_tx is
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;
    signal bit_index : integer range 0 to 7;
    signal shift_reg : std_logic_vector(7 downto 0);
begin
    process (clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            tx <= '1'; 
            tx_done <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    tx_done <= '0';
                    if tx_start = '1' then
                        state <= START_BIT;
                        shift_reg <= tx_data;
                        bit_index <= 0;
                    end if;

                when START_BIT =>
                    if baud_tick = '1' then
                        tx <= '0'; 
                        state <= DATA_BITS;
                    end if;

                when DATA_BITS =>
                    if baud_tick = '1' then
                        tx <= shift_reg(bit_index);
                        if bit_index = 7 then
                            state <= STOP_BIT;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    end if;

                when STOP_BIT =>
                    if baud_tick = '1' then
                        tx <= '1'; 
                        state <= IDLE;
                        tx_done <= '1';
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end architecture;