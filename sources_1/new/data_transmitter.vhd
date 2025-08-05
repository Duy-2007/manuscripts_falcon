library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity data_transmitter is
    port (
        clk         : in  std_logic;
        reset       : in  std_logic;
        data_16bit  : in  std_logic_vector(15 downto 0); 
        enable      : in  std_logic;                     
        data_8bit   : out std_logic_vector(7 downto 0);  
        data_valid  : out std_logic                     
    );
end data_transmitter;

architecture behavioral of data_transmitter is
    type state_type is (IDLE, SEND_HIGH_BYTE, SEND_LOW_BYTE);
    signal state : state_type := IDLE;
    signal data_reg : std_logic_vector(15 downto 0);  
    signal byte_select : std_logic;                  
begin
    process(clk, reset)
    begin
        if reset = '1' then
            state <= IDLE;
            data_8bit <= (others => '0');
            data_valid <= '0';
            byte_select <= '0';
        elsif rising_edge(clk) then
            case state is
                when IDLE =>
                    data_valid <= '0';
                    if enable = '1' then
                        data_reg <= data_16bit;                 
                        data_8bit <= data_16bit(15 downto 8);   
                        data_valid <= '1'; 
                        state <= SEND_LOW_BYTE;
                        byte_select <= '1';                  
                    end if;
                when SEND_LOW_BYTE =>
                    if byte_select = '1' then
                        data_8bit <= data_reg(7 downto 0);      
                        data_valid <= '1';                    
                        byte_select <= '0';                
                        state <= IDLE; 
                    end if;
                when others =>
                    state <= IDLE;
            end case;
        end if;
    end process;
end architecture behavioral;