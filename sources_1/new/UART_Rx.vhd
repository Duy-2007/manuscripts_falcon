library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity UART_rx is
    port (
        clk         : in std_logic;
        reset       : in std_logic;
        baud_tick   : in std_logic;                
        rx          : in std_logic;                  
        rx_data     : out std_logic_vector(7 downto 0); 
        rx_done     : out std_logic                 
    );
end UART_rx;

architecture behavior of UART_rx is
    type state_type is (IDLE, START_BIT, DATA_BITS, STOP_BIT);
    signal state : state_type := IDLE;
    signal bit_index : integer range 0 to 7;
    signal shift_reg : std_logic_vector(7 downto 0);
    signal sample_count : integer range 0 to 15;     
begin
    process (clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            shift_reg <= (others => '0');
            bit_index <= 0;
            rx_done <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    rx_done <= '0';
                    if rx = '0' then                   
                        state <= START_BIT;
                        sample_count <= 0;
                    end if;

                when START_BIT =>
                    if baud_tick = '1' then
                        state <= DATA_BITS;
                        bit_index <= 0;
                    end if;

                when DATA_BITS =>
                    if baud_tick = '1' then
                        shift_reg(bit_index) <= rx;     
                        if bit_index = 7 then
                            state <= STOP_BIT;
                        else
                            bit_index <= bit_index + 1;
                        end if;
                    end if;

                when STOP_BIT =>
                    if baud_tick = '1' then
                        state <= IDLE;
                        rx_done <= '1';                 
                        rx_data <= shift_reg;        
                    end if;

                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end architecture;