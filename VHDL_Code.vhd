library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity project_reti_logiche is
    Port ( i_clk         : in  std_logic;
      i_rst         : in  std_logic;
      i_start       : in  std_logic;
      i_data        : in  std_logic_vector(7 downto 0);
      o_address     : out std_logic_vector(15 downto 0);
      o_done        : out std_logic;
      o_en          : out std_logic;
      o_we          : out std_logic;
      o_data        : out std_logic_vector (7 downto 0)
           );
end project_reti_logiche;

architecture Behavioral of project_reti_logiche is
component datapath is
     Port(
        -- ingressi standard
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        
        --segnali di caricamento dei registri
        load_reg_col : in STD_LOGIC;
        load_reg_row : in STD_LOGIC;
        load_reg_tmp_molt : in STD_LOGIC;
        load_reg_tot_molt : in STD_LOGIC;
        load_reg_address : in STD_LOGIC;
        load_reg_delta_value : in STD_LOGIC;
        
        --segnali selezione mux
        sel_address : in STD_LOGIC;
        sel_tmp_molt : in STD_LOGIC;
        sel_mem : in STD_LOGIC;
        
        --segnali vari
        sig_on_max_min : in STD_LOGIC;
        internal_reset : in STD_LOGIC;
               
        --uscite
        o_address : out std_logic_vector(15 downto 0);
        o_data : out std_logic_vector (7 downto 0);
        o_read_done : out STD_LOGIC;
        o_done_molt : out STD_LOGIC; 
        o_zero : out STD_LOGIC
     );
end component;

--segnali interni:
--signals di caricamento dei registri
signal load_reg_col : STD_LOGIC;
signal load_reg_row : STD_LOGIC;
signal load_reg_tmp_molt : STD_LOGIC;
signal load_reg_tot_molt : STD_LOGIC;
signal load_reg_address : STD_LOGIC;
signal load_reg_delta_value : STD_LOGIC;
--signals selezione mux
signal sel_tmp_molt : STD_LOGIC;
signal sel_address : STD_LOGIC;
signal sel_mem : STD_LOGIC;
--signal per attivare il circuito (asincrono) per il calcolo di massimo e minimo ????????????????
signal sig_on_max_min : STD_LOGIC;
--signal di appoggio per salvare il valore di o_address del datapath
signal appo_address : std_logic_vector(15 downto 0);
--signal per segnalare la fine dell'operazione di moltiplicazione
signal o_done_molt : STD_LOGIC;
--signal per segnalare la fine della lettura della memoria
signal o_read_done : STD_LOGIC;
--signal per segnalare che almeno un valore tra righe e colonne è pari a zero
signal o_zero: STD_LOGIC;
--signal interno per resettare il circuito alla fine della computazione di un'immagine
signal internal_reset : STD_LOGIC;

type S is (S_rst, S_start, SX, S0, pp_S1, p_S1, S1, S2, S3, p_S4, S4, S5, S6, S7, S8, S9, S10, S11);
signal cur_state, next_state : S;


begin
    DATAPATH0: datapath port map(
        i_clk => i_clk,
        i_rst => i_rst,
        i_data => i_data,
        load_reg_col => load_reg_col ,
        load_reg_row => load_reg_row,
        load_reg_tmp_molt => load_reg_tmp_molt,
        load_reg_tot_molt => load_reg_tot_molt,
        load_reg_address => load_reg_address,
        load_reg_delta_value => load_reg_delta_value,
        sel_address => sel_address,
        sel_tmp_molt => sel_tmp_molt,
        sel_mem => sel_mem,
        sig_on_max_min => sig_on_max_min,
        internal_reset => internal_reset,
        o_address => appo_address,
        o_read_done => o_read_done,
        o_data => o_data,
        o_done_molt => o_done_molt,
        o_zero => o_zero
    );
        
    -- process per gestione del valore di o_address
    process(appo_address, cur_state)
    begin
        case cur_state is
            when SX =>
                o_address <= "0000000000000000";
            when S0 =>
                o_address <= "0000000000000001";
            when others =>    
                o_address <= appo_address;
        end case;
    end process;
    
    -- process per definire i flip flop
    process(i_clk, i_rst)
    begin
        if(i_rst = '1') then
            cur_state <= S_start;
        elsif i_clk'event and i_clk = '1' then
            cur_state <= next_state;
        end if;
    end process;
    
    -- processo per calcolo funzione stato prossimo
    process(cur_state, i_rst, i_start, o_done_molt, o_read_done, o_zero) 
    begin
        next_state <= cur_state;
        case cur_state is
            when S_rst =>
                if i_rst = '0' then
                    next_state <= S_rst;
                else
                    next_state <= S_start;
                end if;
            when S_start =>
                if i_start = '0' then
                    next_state <= S_start;
                else
                    next_state <= SX;
                end if;
            when SX =>
                next_state <= S0;
            when S0 =>
                next_state <= pp_S1;
            when pp_S1 =>
                next_state <= p_S1;
            when p_S1 =>
                if o_zero = '1' then
                    next_state <= S10;
                else
                    next_state <= S1;
                end if;                  
             when S1 =>
                next_state <= S2;
             when S2 =>
                if o_done_molt = '0' then
                    next_state <= S2;
                else
                    next_state <= S3;
                end if;
             when S3 => 
                next_state <= p_S4;
             when p_S4 =>
                next_state <= S4;
             when S4 =>
                if o_read_done = '0' then
                    next_state <= S4;
                else
                    next_state <= S5;
                end if;
             when s5 => 
                next_state <= S6;
             when S6 =>
                next_state <= S7;  
             when S7 =>
                next_state <= S8;
             when S8 =>
                next_state <= S9;
             when S9 =>
                if o_read_done ='0' then
                    next_state <= S8;
                else
                    next_state <= S10;
                end if;
              when S10 =>
                 if i_start ='0' then
                    next_state <= S11;
                 else
                    next_state <= S10;
                 end if;    
               when S11 =>
                  next_state <= S_start;   
                  
         end case;
     end process;
     
     -- process per funzione di uscita
     process(cur_state)
     begin
        load_reg_col <= '0';
        load_reg_row <= '0';
        load_reg_tmp_molt <= '0';
        load_reg_tot_molt <= '0';
        load_reg_address <= '0';
        load_reg_delta_value <= '0';
        
        sel_address <= '0';
        sel_tmp_molt <= '0';
        sel_mem <= '0';
        
        sig_on_max_min <= '0';
        internal_reset <= '0';
       
        o_done <= '0';        
        o_en <= '0';
        o_we <= '0';
 
        case cur_state is
            when S_rst =>
            when S_start =>
            when SX =>
                o_en <= '1';
            when S0 =>
                load_reg_col <= '1'; 
                o_en <= '1';
            when pp_S1 => 
                load_reg_row <= '1';
            when p_S1=>
            when S1 =>
                load_reg_tmp_molt <= '1';
            when S2 =>
                load_reg_tmp_molt <= '1';
                load_reg_tot_molt <= '1';
                sel_tmp_molt <= '1';
            when S3 =>
                o_en <= '1'; 
                load_reg_address <= '1';
            when p_S4 =>
                o_en <= '1';
                sel_address <= '1';
                load_reg_address <= '1';
            when S4 =>
                sig_on_max_min <= '1';
                sel_address <= '1';
                load_reg_address <= '1';
                o_en <= '1';
            when S5 =>
                load_reg_delta_value <= '1';
            when S6 =>
                load_reg_address <= '1';
            when S7 =>
                o_en <= '1';
                sel_address <= '1';
            when S8 =>
                o_en <= '1';
                o_we <= '1';
                sel_mem <= '1';
                sel_address <= '1';
                load_reg_address <= '1';
            when S9 =>
                o_en <= '1';
            when S10 =>
                o_done <= '1';
            when S11 =>
                internal_reset <= '1';
        end case;
     end process;
        
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity datapath is
    Port(
        -- ingressi standard
        i_clk : in std_logic;
        i_rst : in std_logic;
        i_data : in std_logic_vector(7 downto 0);
        
        --segnali di caricamento dei registri
        load_reg_col : in STD_LOGIC;
        load_reg_row : in STD_LOGIC;
        load_reg_tmp_molt : in STD_LOGIC;
        load_reg_tot_molt : in STD_LOGIC;
        load_reg_address : in STD_LOGIC;
        load_reg_delta_value : in STD_LOGIC;
        
        --segnali selezione mux
        sel_address : in STD_LOGIC;
        sel_tmp_molt : in STD_LOGIC;
        sel_mem : in STD_LOGIC;
        
        --altri segnali
        sig_on_max_min : in STD_LOGIC;
        internal_reset : in STD_LOGIC;
        
        --uscite
        o_address : out std_logic_vector(15 downto 0);
        o_data : out std_logic_vector (7 downto 0);
        o_read_done : out STD_LOGIC;
        o_done_molt : out STD_LOGIC;
        o_zero : out STD_LOGIC
     );
end datapath;

architecture Behavioral of datapath is
    component moltiplicator is 
        Port(
            i_clk : in std_logic;
            i_rst : in std_logic;
            internal_reset : in std_logic;
            i_multiplier : in std_logic_vector (7 downto 0);
            i_multiplicand : in std_logic_vector (7 downto 0);
            sel_tmp_molt : std_logic;
            load_reg_tmp_molt : in std_logic;
            load_reg_tot_molt : in std_logic;
            o_tot_molt : out std_logic_vector (15 downto 0);
            o_done_molt : out std_logic 
        );
    end component;

    component max_val is 
        Port(
            i_clk : in std_logic;
            i_rst : in std_logic;
            internal_reset : in std_logic;
            i_on : in std_logic;
            i_value : in std_logic_vector(7 downto 0);
            o_max_value : out std_logic_vector(7 downto 0)
        );
    end component;
    
    component min_val is 
        Port(
            i_clk : in std_logic;
            i_rst : in std_logic;
            internal_reset : in std_logic;
            i_on : in std_logic;
            i_value : in std_logic_vector(7 downto 0);
            o_min_value : out std_logic_vector(7 downto 0)
        );
    end component;
    
    component shift_value is
        Port(
            i_delta : in std_logic_vector (7 downto 0);
            o_shift_value :out std_logic_vector(3 downto 0)
        );
    end component;
    
    component tmp_value is
        Port(
            i_value : in std_logic_vector (7 downto 0);
            i_min : in std_logic_vector (7 downto 0);
            i_shift : in std_logic_vector (3 downto 0);
            o_tmp_value :out std_logic_vector(15 downto 0)
        );
    end component;
    
    component new_value is
        Port(
            i_tmp : in std_logic_vector (15 downto 0);
            o_new_value :out std_logic_vector(7 downto 0)
        );  
    end component;
    
    
--segnali interni:
--signals relativi ai registri
signal o_reg_col : STD_LOGIC_VECTOR (7 downto 0);
signal o_reg_row : STD_LOGIC_VECTOR (7 downto 0);
signal o_reg_tot_molt : STD_LOGIC_VECTOR (15 downto 0); --tot
signal o_reg_address : STD_LOGIC_VECTOR (15 downto 0);  --reg_indirizzoDaPrendere
signal o_reg_delta_value : STD_LOGIC_VECTOR (7 downto 0);
--signals relativi ai componenti
signal co_max_value : STD_LOGIC_VECTOR (7 downto 0);
signal co_min_value : STD_LOGIC_VECTOR (7 downto 0);
signal co_shift_value : STD_LOGIC_VECTOR(3 downto 0);
signal co_tmp_value : STD_LOGIC_VECTOR(15 downto 0);
signal co_new_value: STD_LOGIC_VECTOR(7 downto 0);
--signals relativi ai multiplexer
signal mux_reg_address : STD_LOGIC_VECTOR(15 downto 0);
signal mux_multiplicand : STD_LOGIC_VECTOR(7 downto 0);
signal mux_multiplier : STD_LOGIC_VECTOR(7 downto 0);
--signals relativi ai sommatori e sottrattori
signal sub_address : STD_LOGIC_VECTOR(15 downto 0); --sottrattore dell'address
signal add_data : STD_LOGIC_VECTOR(15 downto 0); --somma 1 dopo moltiplicatore
signal add_mem : STD_LOGIC_VECTOR(15 downto 0);
signal sub_delta_value : STD_LOGIC_VECTOR (7 downto 0);
--signals relativi ai comparatori
signal comp_input : STD_LOGIC;
signal comp_row : STD_LOGIC;
signal comp_col : STD_LOGIC;

begin
    --registro reg_col
    process(i_clk, i_rst, internal_reset)
    begin
        if(i_rst = '1' or internal_reset = '1') then
            o_reg_col <= "00000000";
        elsif i_clk'event and i_clk = '1' then
            if(load_reg_col = '1') then
                o_reg_col <= i_data;
            end if;
        end if;
    end process;
    
    --registro reg_row
    process(i_clk, i_rst, internal_reset)
    begin
        if(i_rst = '1' or internal_reset = '1') then
            o_reg_row <= "00000000";
        elsif i_clk'event and i_clk = '1' then
            if(load_reg_row = '1') then
                o_reg_row <= i_data;
            end if;
        end if;
    end process;
    
    --comparatore righe/colonna == 0
    comp_row <= '1' when (o_reg_row = 0) else '0';
    comp_col <= '1' when (o_reg_col = 0) else '0';
    o_zero <= comp_row OR comp_col;
    
    --comparatore numero righe e numero colonne
    comp_input <= '1' when (o_reg_col > o_reg_row) else '0';
    
    --multiplexer mux_multiplicand
    with comp_input select
        mux_multiplicand <= o_reg_row when '0',
                   o_reg_col when '1',
                   "XXXXXXXX" when others;
    
    --multiplexer mux_multiplier
    with comp_input select
        mux_multiplier <= o_reg_col when '0',
                   o_reg_row when '1',
                   "XXXXXXXX" when others;
                   
    --componente per calcolo moltiplicazione
    MOLTIPLICATOR0: moltiplicator port map(
        i_clk => i_clk,
        i_rst => i_rst,
        internal_reset => internal_reset,
        i_multiplier => mux_multiplier,
        i_multiplicand => mux_multiplicand,
        sel_tmp_molt => sel_tmp_molt,
        load_reg_tmp_molt => load_reg_tmp_molt,
        load_reg_tot_molt => load_reg_tot_molt,
        o_tot_molt => o_reg_tot_molt,
        o_done_molt => o_done_molt
    );
    
    --sommatore che somma 1 
    add_data <= (o_reg_tot_molt) + "0000000000000001";
    
    --multiplexer mux_reg_address 
    with sel_address select
       mux_reg_address <= add_data when '0',
                   sub_address when '1',
                   "XXXXXXXXXXXXXXXX" when others;
                    
    --registro reg_address 
    process(i_clk, i_rst, internal_reset)
    begin
        if(i_rst = '1' or internal_reset = '1') then
            o_reg_address <= "0000000000000000";
        elsif i_clk'event and i_clk = '1' then
            if(load_reg_address = '1') then
                o_reg_address <= mux_reg_address;
            end if;
        end if;
    end process;
    
    add_mem <= o_reg_tot_molt + o_reg_address;
    
    --multiplexer mux_mem 
    with sel_mem select
       o_address <= o_reg_address when '0',
                   add_mem when '1',
                   "XXXXXXXXXXXXXXXX" when others;
    
    --comparatore o_read_done per fine lettura della memoria 
    o_read_done <= '1' when (o_reg_address = "0000000000000001") else '0';
    
    --sottrattore 
    sub_address <= (o_reg_address) - "0000000000000001";
    
    --componente per calcolo del valore massimo
    MAXVAL0: max_val port map(
        i_clk => i_clk,
        i_rst => i_rst,
        internal_reset => internal_reset,
        i_on => sig_on_max_min,
        i_value => i_data,
        o_max_value => co_max_value
    );
    
    --componente per calcolo del valore minimo
    MINVAL0: min_val port map(
        i_clk => i_clk,
        i_rst => i_rst,
        internal_reset => internal_reset,
        i_on => sig_on_max_min,
        i_value => i_data,
        o_min_value => co_min_value
    );
    
    --sottrattore per calcolo delta value 
    sub_delta_value <= co_max_value - co_min_value;
    
    --registro reg_delta_value 
    process(i_clk, i_rst, internal_reset)
    begin
        if(i_rst = '1' or internal_reset = '1') then
            o_reg_delta_value <= "00000000";
        elsif i_clk'event and i_clk = '1' then
            if(load_reg_delta_value = '1') then
                o_reg_delta_value <= sub_delta_value;
            end if;
        end if;
    end process;
    
    --componente per calcolo del shift_value dell'immagine
    SHIFT_VALUE0: shift_value port map(
        i_delta => o_reg_delta_value,
        o_shift_value => co_shift_value
    );
    
    --componente per calcolo del tmp_value del pixel
    TMP_VALUE0: tmp_value port map(
        i_value => i_data,
        i_min => co_min_value,
        i_shift => co_shift_value,
        o_tmp_value => co_tmp_value
    );
    
    --componente per calcolo del nuovo valore del pixel
    NEW_VALUE0: new_value port map(
        i_tmp => co_tmp_value,
        o_new_value => o_data
    );
    
end Behavioral;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity moltiplicator is
    Port(
        i_clk : in std_logic;
        i_rst : in std_logic;
        internal_reset : in std_logic;
        i_multiplier : in std_logic_vector (7 downto 0);
        i_multiplicand : in std_logic_vector (7 downto 0);
        sel_tmp_molt : std_logic;
        load_reg_tmp_molt : in std_logic;
        load_reg_tot_molt : in std_logic;
        o_tot_molt : out std_logic_vector (15 downto 0);
        o_done_molt : out std_logic 
    );
end moltiplicator;

architecture moltiplicator of moltiplicator is
--signals relativi ai registri
signal o_reg_tmp_molt : STD_LOGIC_VECTOR (7 downto 0);
signal o_reg_tot_molt : STD_LOGIC_VECTOR (15 downto 0);
--signals relativi ai multiplexer
signal mux_reg_tmp_molt : STD_LOGIC_VECTOR(7 downto 0);
--signals relativi ai sommatori e sottrattori
signal sub_tmp_molt : STD_LOGIC_VECTOR(7 downto 0);
signal add_tot_molt : STD_LOGIC_VECTOR(15 downto 0); 



begin
    --multiplexer mux_reg_tmp_molt
    with sel_tmp_molt select
        mux_reg_tmp_molt <= i_multiplier when '0',
                    sub_tmp_molt when '1',
                    "XXXXXXXX" when others;   
    
    --registro reg_tmp_molt
    process(i_clk, i_rst, internal_reset)
    begin
        if(i_rst = '1' or internal_reset = '1') then
            o_reg_tmp_molt <= "00000000";
        elsif i_clk'event and i_clk = '1' then
            if(load_reg_tmp_molt = '1') then
                o_reg_tmp_molt <= mux_reg_tmp_molt;
            end if;
        end if;
    end process;
    
    --sottrattore che sottrae 1
    sub_tmp_molt <= (o_reg_tmp_molt) - "00000001";
    
    --comparatore
    o_done_molt <= '1' when (sub_tmp_molt = "0000000") else '0';
    
    --sommatore per somme parziali
    add_tot_molt <= ("00000000" & i_multiplicand) + o_reg_tot_molt;
    
    --registro reg_tot_molt
    process(i_clk, i_rst, internal_reset)
    begin
        if(i_rst = '1' or internal_reset = '1') then
            o_reg_tot_molt <= "0000000000000000";
        elsif i_clk'event and i_clk = '1' then
            if(load_reg_tot_molt = '1') then
                o_reg_tot_molt <= add_tot_molt;
            end if;
        end if;
    end process;
    
    o_tot_molt <= o_reg_tot_molt;

end moltiplicator;


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity max_val is
    Port(
        i_clk : in std_logic;
        i_rst : in std_logic;
        internal_reset : in std_logic;
        i_on : in std_logic;
        i_value : in std_logic_vector(7 downto 0);
        o_max_value : out std_logic_vector(7 downto 0)
    );
end max_val;

architecture max_val of max_val is
--signal relativo al registro
signal o_reg_max :std_logic_vector(7 downto 0);
--signal relativo al multiplexer
signal seg_load_max : std_logic;

begin
    --registro reg_max 
    process(i_clk, i_rst, internal_reset, i_on) 
    begin
        if(i_rst = '1' or internal_reset = '1') then
            o_reg_max <= "00000000";
        elsif i_clk'event and i_clk = '1' and i_on = '1' then
            if(seg_load_max = '1') then
                o_reg_max <= i_value;
            end if;
        end if;
    end process;
    
    --processo per attivazione del load del registro
    process(i_on, i_value, o_reg_max)
    begin
        if(i_on = '1') then
            if(i_value > o_reg_max) then
                seg_load_max <= '1';
            else 
                seg_load_max <= '0';
            end if;     
        else 
            seg_load_max <= '0';       
        end if;
    end process;
 
    o_max_value <= o_reg_max;
end max_val;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity min_val is
    Port(
        i_clk : in std_logic;
        i_rst : in std_logic;
        internal_reset : in std_logic;
        i_on : in std_logic;
        i_value : in std_logic_vector(7 downto 0);
        o_min_value : out std_logic_vector(7 downto 0)
    );
end min_val;

architecture min_val of min_val is
--signal relativo al registro
signal o_reg_min :std_logic_vector(7 downto 0);
--signal relativo al multiplexer
signal seg_load_min : std_logic;
--signals relativi ai sommatori e sottrattori
signal sub_min : std_logic_vector(7 downto 0);

begin
    --registro reg_min 
    process(i_clk, i_rst, internal_reset, i_on)
    begin
        if(i_rst = '1' or internal_reset = '1') then
            o_reg_min <= "11111111";
        elsif i_clk'event and i_clk = '1' and i_on = '1' then
            if(seg_load_min = '1') then
                o_reg_min <= i_value;
            end if;
        end if;
    end process;
    
    --processo per attivazione del load del registro
    process(i_on, i_value, o_reg_min)
    begin
        if(i_on = '1') then  
                if(i_value < o_reg_min) then
                seg_load_min <= '1';
            else 
                seg_load_min <='0';
            end if; 
        else
            seg_load_min <= '0';           
        end if;
    end process;
       
    o_min_value <= o_reg_min;
end min_val;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity shift_value is
    Port(
        i_delta : in std_logic_vector (7 downto 0);
        o_shift_value :out std_logic_vector(3 downto 0)
    );
end shift_value;

architecture shift_value of shift_value is
--signal relativo al sommatore
signal add_shift : std_logic_vector(8 downto 0);

begin
    --sommatore
    add_shift <= ("0" & i_delta) + "000000001";
    
    --processo per l'assegnamento di shift_value in base al valore di delta_value + 1 
    process(add_shift)
        begin
            if(add_shift = "000000001") then
                o_shift_value <= "1000";
            elsif(add_shift = "100000000") then 
                o_shift_value <= "0000"; 
            elsif(add_shift(8 downto 1) = "00000001") then 
                o_shift_value <= "0111"; 
            elsif(add_shift(8 downto 2) = "0000001") then 
                o_shift_value <= "0110"; 
            elsif(add_shift(8 downto 3) = "000001") then 
                o_shift_value <= "0101"; 
            elsif(add_shift(8 downto 4) = "00001") then 
                o_shift_value <= "0100";
            elsif(add_shift(8 downto 5) = "0001") then 
                o_shift_value <= "0011"; 
            elsif(add_shift(8 downto 6) = "001") then 
                o_shift_value <= "0010"; 
            elsif(add_shift(8 downto 7) = "01") then 
                o_shift_value <= "0001";
            else
                o_shift_value <= "XXXX";     
            end if;
        
    end process;   
end shift_value;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity tmp_value is
    Port(
        i_value : in std_logic_vector (7 downto 0);
        i_min : in std_logic_vector (7 downto 0);
        i_shift : in std_logic_vector (3 downto 0);
        o_tmp_value :out std_logic_vector(15 downto 0)
    );
end tmp_value;

architecture tmp_value of tmp_value is
--signal relativo al sottrattore
signal sub_tmp : std_logic_vector(15 downto 0);

begin     
    --sottrattore
    sub_tmp <= "00000000" & (i_value - i_min);

    --processo per calcolo del tmp_value in base al valore dello shift_value
    with i_shift select
    o_tmp_value <= sub_tmp when "0000",
           sub_tmp(14 downto 0) & "0" when "0001",
           sub_tmp(13 downto 0) & "00" when "0010",
           sub_tmp(12 downto 0) & "000" when "0011",
           sub_tmp(11 downto 0) & "0000" when "0100",
           sub_tmp(10 downto 0) & "00000" when "0101",
           sub_tmp(9  downto 0) & "000000" when "0110",
           sub_tmp(8  downto 0) & "0000000" when "0111",
           sub_tmp(7  downto 0) & "00000000" when "1000",
           "XXXXXXXXXXXXXXXX" when others;

end tmp_value;

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

entity new_value is
    Port(
        i_tmp : in std_logic_vector (15 downto 0);
        o_new_value :out std_logic_vector(7 downto 0)
    );
end new_value;

architecture new_value of new_value is
--signal relativo al multiplexer
signal sel_mux_new : std_logic;

begin
    --segnale di selezione del multiplexer
    sel_mux_new <= '1' when (i_tmp > "0000000011111111") else '0';
    
    --multiplexer mux_new_value
    with sel_mux_new select
        o_new_value <= i_tmp(7 downto 0) when '0', 
                       "11111111" when '1',                      
                       "XXXXXXXX" when others;

end new_value;

