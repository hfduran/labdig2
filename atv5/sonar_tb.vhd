--------------------------------------------------------------------
-- Arquivo   : sonar_tb.vhd
-- Projeto   : Experiencia 5 - Sistema de Sonar
--------------------------------------------------------------------
-- Descricao : testbench BÁSICO para circuito do sistema de sonar
--
--             1) array de casos de teste contém valores de  
--                largura de pulso de echo do sensor
-- 
--------------------------------------------------------------------
-- Revisoes  :
--     Data        Versao  Autor             Descricao
--     19/09/2021  1.0     Edson Midorikawa  versao inicial
--     24/09/2022  1.1     Edson Midorikawa  revisao
--     30/09/2022  1.1.1   Edson Midorikawa  revisao
--     24/09/2022  1.1.2   Edson Midorikawa  revisao
--------------------------------------------------------------------
--
library ieee;
use ieee.std_logic_1164.all;

entity sonar_tb is
end entity;

architecture tb of sonar_tb is
  
  -- Componente a ser testado (Device Under Test -- DUT)
  component sonar is
    port (
         clock : in std_logic;
         reset : in std_logic;
         echo : in std_logic;
         liga : in std_logic;
         entrada_serial: in std_logic;
         trigger : out std_logic;
         pwm : out std_logic;
         saida_serial : out std_logic;
         fim_posicao : out std_logic;
         medida0 : out std_logic_vector (6 downto 0);
         medida1 : out std_logic_vector (6 downto 0);
         medida2 : out std_logic_vector (6 downto 0);
         db_estado : out std_logic_vector (6 downto 0);
         db_modo : out std_logic
     );
  end component;
  
  -- Declaração de sinais para conectar o componente a ser testado (DUT)
  --   valores iniciais para fins de simulacao (GHDL ou ModelSim)
  signal clock_in         : std_logic := '0';
  signal reset_in         : std_logic := '0';
  signal ligar_in         : std_logic := '0';
  signal echo_in          : std_logic := '0';
  signal entrada_serial_in: std_logic := '1';
  signal trigger_out      : std_logic := '0';
  signal pwm_out          : std_logic := '0';
  signal saida_serial_out : std_logic := '1';
  signal fim_posicao_out  : std_logic := '0';
  signal db_estado_out    : std_logic_vector (6 downto 0) := "0000000";


  -- Configurações do clock
  constant clockPeriod   : time      := 20 ns; -- clock de 50MHz
  constant bitPeriod   : time := 434*clockPeriod; -- 434 clocks por bit (115.200 bauds)
  signal keep_simulating : std_logic := '0';   -- delimita o tempo de geração do clock
  
  -- Array de posicoes de teste
  type posicoes_teste_type is record
      id    : natural; 
      tempo : integer;     
  end record;

  -- fornecida tabela com 2 posicoes (comentadas 6 posicoes)
  type posicoes_teste_array is array (natural range <>) of posicoes_teste_type;
  constant posicoes_teste : posicoes_teste_array :=
      ( 
        ( 1,  294),   --   5cm ( 294us)
        ( 2,  353),   --   6cm ( 353us)
        ( 3,  353),  --   6cm ( 353us)
        ( 4, 582),  -- 100cm (5882us)
        ( 5, 582),  -- 100cm (5882us)
        ( 6,  882),  --  15cm ( 882us)
        ( 7,  882),  --  15cm ( 882us)
        ( 8, 582),  -- 100cm (5882us)
        ( 9,  588)   --  10cm ( 588us)
        -- inserir aqui outros posicoes de teste (inserir "," na linha anterior)
      );

  signal larguraPulso: time := 1 ns;

  procedure UART_WRITE_BYTE (
      Data_In : in  std_logic_vector(7 downto 0);
      signal Serial_Out : out std_logic ) is
  begin

      -- envia Start Bit
      Serial_Out <= '0';
      wait for bitPeriod;

      -- envia 8 bits seriais
      for ii in 0 to 7 loop
          Serial_Out <= Data_In(ii);
          wait for bitPeriod;
      end loop;  -- loop ii

      -- envia 2 Stop Bits
      Serial_Out <= '1';
      wait for 2*bitPeriod;

  end UART_WRITE_BYTE;

begin
  -- Gerador de clock: executa enquanto 'keep_simulating = 1', com o período
  -- especificado. Quando keep_simulating=0, clock é interrompido, bem como a 
  -- simulação de eventos
  clock_in <= (not clock_in) and keep_simulating after clockPeriod/2;
  
  -- Conecta DUT (Device Under Test)
  dut: sonar
        port map( 
            clock        => clock_in,
            reset        => reset_in,
            liga        => ligar_in,
            echo         => echo_in,
            entrada_serial => entrada_serial_in,
            trigger      => trigger_out,
            pwm          => pwm_out,
            saida_serial => saida_serial_out,
            fim_posicao  => fim_posicao_out,
            medida0      => open,
            medida1      => open,
            medida2      => open,
            db_estado    => db_estado_out
        );

  -- geracao dos sinais de entrada (estimulos)
  stimulus: process is
  begin
  
    assert false report "Inicio das simulacoes" severity note;
    keep_simulating <= '1';
    
    ---- valores iniciais ----------------
    ligar_in <= '0';
    echo_in  <= '0';

    ---- inicio: reset ----------------
    -- wait for 2*clockPeriod;
    reset_in <= '1'; 
    wait for 2 us;
    reset_in <= '0';
    wait until falling_edge(clock_in);

    ---- ligar sonar ----------------
    wait for 20 us;
    ligar_in <= '1';

    ---- espera de 20us
    -- wait for 20 us;

    ---- loop pelas posicoes de teste
    for i in posicoes_teste'range loop
        -- 1) determina largura do pulso echo para a posicao i
        assert false report "Posicao " & integer'image(posicoes_teste(i).id) & ": " &
            integer'image(posicoes_teste(i).tempo) & "us" severity note;
        larguraPulso <= posicoes_teste(i).tempo * 1 us; -- posicao de teste "i"

        assert false report "esperando trigger..." severity note;
        -- 2) espera pelo pulso trigger
        wait until falling_edge(trigger_out);
     
        assert false report "esperando de 400" severity note;
        -- 3) espera por 400us (simula tempo entre trigger e echo)
        wait for 400 us;

        assert false report "esperando larguraPulso" severity note;
        -- 4) gera pulso de echo (largura = larguraPulso)
        echo_in <= '1';
        wait for larguraPulso;
        echo_in <= '0';

        assert false report "esperando fim_posicao" severity note;
        -- 5) espera sinal fim (indica final da medida de uma posicao do sonar)
        wait until fim_posicao_out = '1';

        if (i = 1) then
          assert false report "desligando...." severity note;
          ligar_in <= '0';
          wait for 700 us;
          assert false report "ligando...." severity note;
          ligar_in <= '1';
        end if;

      if (i=3) then
        assert false report "atencao!" severity note;
        UART_WRITE_BYTE ( Data_In=>"01100001", Serial_Out=>entrada_serial_in );
      end if;

      if(i=6) then
        assert false report "volte!" severity note;
        UART_WRITE_BYTE ( Data_In=>"01110110", Serial_Out=>entrada_serial_in );
      end if;

    end loop;

    wait for 400 us;

    ---- final dos casos de teste da simulacao
    assert false report "Fim das simulacoes" severity note;
    keep_simulating <= '0';
    
    wait; -- fim da simulação: aguarda indefinidamente (não retirar esta linha)
  end process;

end architecture;
