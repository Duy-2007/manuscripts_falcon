library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL; 

entity main_system is
    port (
        clk             : in std_logic;
        reset           : in std_logic;
        rx              : in std_logic;
        tx              : out std_logic;
        random_enable   : in std_logic;
        f_enable        : in std_logic;
        g_enable        : in std_logic
    );
end entity main_system;

architecture behavioral of main_system is
    constant MAX_N : INTEGER := 1024;
    constant F_G_BUF_DEPTH : INTEGER := 2 * MAX_N;
    constant VRFY_BUF_DEPTH : INTEGER := 3 * MAX_N * 2;

    signal element_count : unsigned(10 downto 0) := (others => '0');
    signal h_read_count : unsigned(10 downto 0) := (others => '0');
    signal seed_count : unsigned(10 downto 0) := (others => '0');
    signal vrfy_count : unsigned(12 downto 0) := (others => '0');
    signal previous_data : std_logic_vector(7 downto 0) := (others => '0');

    signal rx_done      : std_logic;
    signal tx_done      : std_logic;
    signal data_rx      : std_logic_vector(7 downto 0);
    signal tx_start     : std_logic;
    signal data_tx      : std_logic_vector(7 downto 0);

    signal wr_f_g_buff         : std_logic;
    signal wr_f_g_dataBuff     : std_logic_vector(7 downto 0);
    signal rd_f_g_buff         : std_logic;
    signal rd_f_g_dataBuff     : std_logic_vector(7 downto 0);
    signal rd_f_g_valid        : std_logic;
    signal empty_f_g_buff      : std_logic;
    signal full_f_g_buff       : std_logic;
    signal fill_f_g_count      : integer range 0 to F_G_BUF_DEPTH;

    signal wr_seed_buff        : std_logic;
    signal wr_seed_dataBuff    : std_logic_vector(7 downto 0);
    signal rd_seed_buff        : std_logic;
    signal rd_seed_dataBuff    : std_logic_vector(7 downto 0);
    signal rd_seed_valid       : std_logic;
    signal empty_seed_buff     : std_logic;
    signal full_seed_buff      : std_logic;
    signal fill_seed_count     : integer range 0 to 8;

    signal wr_vrfy_buff        : std_logic;
    signal wr_vrfy_dataBuff    : std_logic_vector(7 downto 0);
    signal rd_vrfy_buff        : std_logic;
    signal rd_vrfy_dataBuff    : std_logic_vector(7 downto 0);
    signal rd_vrfy_valid       : std_logic;
    signal empty_vrfy_buff     : std_logic;
    signal full_vrfy_buff      : std_logic;
    signal fill_vrfy_count     : integer range 0 to 1024;

    signal add_x_in : std_logic_vector(31 downto 0);
    signal add_y_in : std_logic_vector(31 downto 0);
    signal add_d_out : std_logic_vector(31 downto 0);
    signal compute_h_start : std_logic := '0';
    signal compute_h_done : std_logic := '0';

    signal f_address : unsigned(9 downto 0);
    signal f_ce : std_logic;
    signal g_address : unsigned(9 downto 0);
    signal g_ce : std_logic;
    signal h_address : unsigned(9 downto 0);
    signal h_we : std_logic;

    type f_mem_type is array (0 to MAX_N-1) of STD_LOGIC_VECTOR(7 downto 0);
    signal f_bram_mem : f_mem_type := (others => (others => '0'));
    type g_mem_type is array (0 to MAX_N-1) of STD_LOGIC_VECTOR(7 downto 0);
    signal g_bram_mem : g_mem_type := (others => (others => '0'));
    type h_mem_type is array (0 to MAX_N-1) of STD_LOGIC_VECTOR(31 downto 0);
    signal h_bram_mem : h_mem_type := (others => (others => '0'));

    signal apv_ctrl_0_done  : STD_LOGIC;
    signal apv_ctrl_0_idle  : STD_LOGIC;
    signal apv_ctrl_0_ready : STD_LOGIC;
    signal apv_ctrl_0_start : STD_LOGIC := '0';
    signal apv_return_0     : STD_LOGIC_VECTOR(31 downto 0);
    signal c0_0_vrfy        : STD_LOGIC_VECTOR(15 downto 0);
    signal h_0_vrfy         : STD_LOGIC_VECTOR(15 downto 0);
    signal logn_0_vrfy      : STD_LOGIC_VECTOR(31 downto 0) := x"0000000D";
    signal s2_0_vrfy        : STD_LOGIC_VECTOR(15 downto 0);
    signal tmp_0_vrfy       : STD_LOGIC_VECTOR(7 downto 0);
    signal tmp_ap_vld_0     : STD_LOGIC;

    -- State machine for VRFY output transmission
    type tx_vrfy_state_type is (IDLE_TX_VRFY, SEND_VRFY_BYTE);
    signal tx_vrfy_state : tx_vrfy_state_type := IDLE_TX_VRFY;

    signal dummy_empty_next : std_logic;
    signal dummy_full_next : std_logic;

    component UART_TOP
        port (
            clk         : in std_logic;
            reset       : in std_logic;
            rx          : in std_logic;
            tx_start_in : in std_logic;
            data_tx     : in std_logic_vector(7 downto 0);
            rx_done     : out std_logic;
            tx_done     : out std_logic;
            tx          : out std_logic;
            data_rx     : out std_logic_vector(7 downto 0)
        );
    end component;

    component ring_buffer
        generic (
            RAM_WIDTH : natural;
            RAM_DEPTH : natural
        );
        port (
            clk        : in std_logic;
            rst        : in std_logic;
            wr_en      : in std_logic;
            wr_data    : in std_logic_vector(RAM_WIDTH - 1 downto 0);
            rd_en      : in std_logic;
            rd_valid   : out std_logic;
            rd_data    : out std_logic_vector(RAM_WIDTH - 1 downto 0);
            empty      : out std_logic;
            empty_next : out std_logic;
            full       : out std_logic;
            full_next  : out std_logic;
            fill_count : out integer range 0 to RAM_DEPTH
        );
    end component;

    component random_seed
        Port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            en    : in  std_logic;
            data  : out std_logic_vector(7 downto 0)
        );
    end component;
    
    component mq_Add is
        Port (
            clk   : in  std_logic;
            rst   : in  std_logic;
            x     : in  std_logic_vector(31 downto 0);
            y     : in  std_logic_vector(31 downto 0);
            d_out : out std_logic_vector(31 downto 0)
        );
    end component;

    component design_verify_raw_wrapper is
        port (
            ap_clk_0        : in STD_LOGIC;
            ap_return_0     : out STD_LOGIC_VECTOR ( 31 downto 0 );
            ap_rst_0        : in STD_LOGIC;
            c0_0            : in STD_LOGIC_VECTOR ( 15 downto 0 );
            h_0             : in STD_LOGIC_VECTOR ( 15 downto 0 );
            logn_0          : in STD_LOGIC_VECTOR ( 31 downto 0 );
            s2_0            : in STD_LOGIC_VECTOR ( 15 downto 0 );
            tmp_0           : out STD_LOGIC_VECTOR ( 7 downto 0 );
            tmp_ap_vld_0    : out STD_LOGIC;
            ap_ctrl_0_start : in STD_LOGIC;
            ap_ctrl_0_done  : out STD_LOGIC;
            ap_ctrl_0_idle  : out STD_LOGIC;
            ap_ctrl_0_ready : out STD_LOGIC
        );
    end component;

begin
    UART_INST : UART_TOP
        port map (
            clk         => clk,
            reset       => reset,
            rx          => rx,
            tx_start_in => tx_start,
            data_tx     => data_tx,
            rx_done     => rx_done,
            tx_done     => tx_done,
            tx          => tx,
            data_rx     => data_rx
        );

    FANDGFIFO: ring_buffer
        generic map (
            RAM_WIDTH => 8,
            RAM_DEPTH => F_G_BUF_DEPTH
        )
        port map (
            clk         => clk,
            rst         => reset,
            wr_en       => wr_f_g_buff,
            wr_data     => wr_f_g_dataBuff,
            rd_en       => rd_f_g_buff,
            rd_valid    => rd_f_g_valid,
            rd_data     => rd_f_g_dataBuff,
            empty       => empty_f_g_buff,
            empty_next  => dummy_empty_next,
            full        => full_f_g_buff,
            full_next   => dummy_full_next,
            fill_count  => fill_f_g_count
        );

    SEEDFIFO: ring_buffer
        generic map (
            RAM_WIDTH => 8,
            RAM_DEPTH => 8
        )
        port map (
            clk         => clk,
            rst         => reset,
            wr_en       => wr_seed_buff,
            wr_data     => wr_seed_dataBuff,
            rd_en       => rd_seed_buff,
            rd_valid    => rd_seed_valid,
            rd_data     => rd_seed_dataBuff,
            empty       => empty_seed_buff,
            empty_next  => dummy_empty_next,
            full        => full_seed_buff,
            full_next   => dummy_full_next,
            fill_count  => fill_seed_count
        );

    VRFYFIFO: ring_buffer
        generic map (
            RAM_WIDTH => 8,
            RAM_DEPTH => 1024
        )
        port map (
            clk         => clk,
            rst         => reset,
            wr_en       => wr_vrfy_buff,
            wr_data     => wr_vrfy_dataBuff,
            rd_en       => rd_vrfy_buff,
            rd_valid    => rd_vrfy_valid,
            rd_data     => rd_vrfy_dataBuff,
            empty       => empty_vrfy_buff,
            empty_next  => dummy_empty_next,
            full        => full_vrfy_buff,
            full_next   => dummy_full_next,
            fill_count  => fill_vrfy_count
        );

    random_inst : random_seed
        port map (
            clk   => clk,
            rst   => reset,
            en    => random_enable,
            data  => wr_seed_dataBuff
        );
    
    mq_Add_inst: mq_Add
        port map (
            clk   => clk,
            rst   => reset,
            x     => add_x_in,
            y     => add_y_in,
            d_out => add_d_out
        );

    vrft_sign: design_verify_raw_wrapper
        port map (
            ap_clk_0        => clk,
            ap_ctrl_0_idle  => apv_ctrl_0_idle,
            ap_ctrl_0_ready => apv_ctrl_0_ready,
            ap_ctrl_0_start => apv_ctrl_0_start,
            ap_return_0     => apv_return_0,
            ap_rst_0        => reset,
            c0_0            => c0_0_vrfy,
            h_0             => h_0_vrfy,
            logn_0          => logn_0_vrfy,
            s2_0            => s2_0_vrfy,
            tmp_0           => tmp_0_vrfy,
            tmp_ap_vld_0    => tmp_ap_vld_0
        );

    f_bram_process : process (clk, reset)
    begin
        if reset = '1' then
            for i in 0 to MAX_N-1 loop
                f_bram_mem(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if f_ce = '1' then
                 add_x_in(7 downto 0) <= f_bram_mem(to_integer(f_address));
                 add_x_in(31 downto 8) <= (others => '0');
            end if;
        end if;
    end process f_bram_process;

    g_bram_process : process (clk, reset)
    begin
        if reset = '1' then
            for i in 0 to MAX_N-1 loop
                g_bram_mem(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if g_ce = '1' then
                add_y_in(7 downto 0) <= g_bram_mem(to_integer(g_address));
                add_y_in(31 downto 8) <= (others => '0');
            end if;
        end if;
    end process g_bram_process;
    
    h_bram_process : process (clk, reset)
    begin
        if reset = '1' then
            for i in 0 to MAX_N-1 loop
                h_bram_mem(i) <= (others => '0');
            end loop;
        elsif rising_edge(clk) then
            if h_we = '1' then
                h_bram_mem(to_integer(h_address)) <= add_d_out;
            end if;
        end if;
    end process h_bram_process;
    

    RANDOM : process(clk, reset)
    begin
        if reset = '1' then
            wr_seed_buff <= '0';
        elsif rising_edge(clk) then
            if random_enable = '1' and fill_seed_count < 8 then
                wr_seed_buff <= '1';
            else
                wr_seed_buff <= '0';
            end if;
        end if;
    end process RANDOM;

    DATA_REC : process(clk, reset)
    begin
        if reset = '1' then
            wr_f_g_buff <= '0';
            wr_f_g_dataBuff <= (others => '0');
            element_count <= (others => '0');
        elsif rising_edge(clk) then
            wr_f_g_buff <= '0';
            wr_vrfy_buff <= '0';
            if rx_done = '1' then
                if f_enable = '1' then
                    if fill_f_g_count < F_G_BUF_DEPTH then
                        wr_f_g_buff <= '1';
                        wr_f_g_dataBuff <= data_rx;
                    end if;
                elsif g_enable = '1' then
                    if fill_vrfy_count < VRFY_BUF_DEPTH then
                        wr_vrfy_buff <= '1';
                        wr_vrfy_dataBuff <= data_rx;
                    end if;
                end if;
            end if;

            if f_enable = '1' and rd_f_g_valid = '1' then
                rd_f_g_buff <= '1';
                if element_count < MAX_N then
                    g_bram_mem(to_integer(element_count)) <= rd_f_g_dataBuff;
                    element_count <= element_count + 1;
                elsif element_count < 2 * MAX_N then
                    f_bram_mem(to_integer(element_count - MAX_N)) <= rd_f_g_dataBuff;
                    element_count <= element_count + 1;
                end if;
            else
                rd_f_g_buff <= '0';
            end if;
        end if;
    end process DATA_REC;

    CONTROL_MQ_ADD : process(clk, reset)
    begin
        if reset = '1' then
            h_address <= (others => '0');
            f_address <= (others => '0');
            g_address <= (others => '0');
            f_ce <= '0';
            g_ce <= '0';
            h_we <= '0';
            compute_h_start <= '0';
            compute_h_done <= '0';
        elsif rising_edge(clk) then
            f_ce <= '0';
            g_ce <= '0';
            h_we <= '0';
            
            if f_enable = '1' and element_count = 2 * MAX_N and compute_h_start = '0' then
                compute_h_start <= '1';
                f_address <= (others => '0');
                g_address <= (others => '0');
                h_address <= (others => '0');
            end if;
            
            if compute_h_start = '1' and h_address < to_unsigned(MAX_N, h_address'length) then
                f_ce <= '1';
                g_ce <= '1';
                h_we <= '1';
                h_bram_mem(to_integer(h_address)) <= add_d_out;
                f_address <= f_address + 1;
                g_address <= g_address + 1;
                h_address <= h_address + 1;
            else
                compute_h_start <= '0';
                if h_address = to_unsigned(MAX_N, h_address'length) then
                    compute_h_done <= '1';
                    element_count <= (others => '0');
                end if;
            end if;
        end if;
    end process CONTROL_MQ_ADD;
    
    CONTROL_VRFY : process(clk, reset)
    begin
        if reset = '1' then
            apv_ctrl_0_start <= '0';
            vrfy_count <= (others => '0');
            tx_vrfy_state <= IDLE_TX_VRFY;
            data_tx <= (others => '0');
            tx_start <= '0';
        elsif rising_edge(clk) then
            apv_ctrl_0_start <= '0';
            tx_start <= '0';

            case tx_vrfy_state is
                when IDLE_TX_VRFY =>
                    if g_enable = '1' and fill_vrfy_count >= (3 * MAX_N * 2) / 8 and apv_ctrl_0_idle = '1' then
                           apv_ctrl_0_start <= '1';
                           vrfy_count <= (others => '0');
                    elsif apv_ctrl_0_done = '1' then
                        tx_vrfy_state <= SEND_VRFY_BYTE;
                    end if;

                    if g_enable = '1' and rd_vrfy_valid = '1' then
                        rd_vrfy_buff <= '1';
                        if vrfy_count < MAX_N * 2 then
                            if vrfy_count mod 2 = 0 then
                                previous_data <= rd_vrfy_dataBuff;
                            else
                                c0_0_vrfy <= previous_data & rd_vrfy_dataBuff;
                            end if;
                        elsif vrfy_count < 2 * MAX_N * 2 then
                            if vrfy_count mod 2 = 0 then
                                previous_data <= rd_vrfy_dataBuff;
                            else
                                s2_0_vrfy <= previous_data & rd_vrfy_dataBuff;
                            end if;
                        elsif vrfy_count < 3 * MAX_N * 2 then
                            if vrfy_count mod 2 = 0 then
                                previous_data <= rd_vrfy_dataBuff;
                            else
                                h_0_vrfy <= previous_data & rd_vrfy_dataBuff;
                            end if;
                        end if;
                        vrfy_count <= vrfy_count + 1;
                    else
                        rd_vrfy_buff <= '0';
                    end if;

                when SEND_VRFY_BYTE =>
                    if tmp_ap_vld_0 = '1' then
                        data_tx <= tmp_0_vrfy;
                        tx_start <= '1';
                        tx_vrfy_state <= IDLE_TX_VRFY;
                    end if;

                when others =>
                    tx_vrfy_state <= IDLE_TX_VRFY;
            end case;
        end if;
    end process CONTROL_VRFY;

    UART_TX_Arbiter : process(clk, reset)
    begin
        if reset = '1' then
            data_tx <= (others => '0');
            tx_start <= '0';
        elsif rising_edge(clk) then
            data_tx <= (others => '0');
            tx_start <= '0';

            if random_enable = '1' and empty_seed_buff = '0' then
                rd_seed_buff <= '1';
                data_tx <= rd_seed_dataBuff;
                tx_start <= '1';
            elsif tx_vrfy_state = SEND_VRFY_BYTE then
                data_tx <= tmp_0_vrfy;
                tx_start <= tmp_ap_vld_0;
            end if;
        end if;
    end process UART_TX_Arbiter;

end behavioral;