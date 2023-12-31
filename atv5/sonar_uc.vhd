library ieee;
use ieee.std_logic_1164.all;

entity sonar_uc is
    port (
         clock              : in std_logic;
         reset              : in std_logic;
         fim_medida         : in std_logic;
         fim_transmissao    : in std_logic;
         transmissao_pronto : in std_logic;
         liga               : in std_logic;
         atencao            : in std_logic;
         transmitir         : out std_logic;
         zera_transmissor   : out std_logic;
         zera_rx            : out std_logic;
         zera_cont_digitos  : out std_logic;
         zera_cont_medir    : out std_logic;
         zera_cont_angulo   : out std_logic;
         conta_digito       : out std_logic;
         conta_medir        : out std_logic;
         conta_angulo       : out std_logic;
         tx_step            : out std_logic;
         pronto             : out std_logic;
         db_estado          : out std_logic_vector(3 downto 0)
     );
end entity;

architecture arch of sonar_uc is
    type tipo_estado is (inicial, rotina, preparacao, espera_medida, tx_distancia,
        tx_angulo, prox_digito_distancia, prox_digito_angulo, zera_digitos, final, final_atencao);
    signal Eatual, Eprox: tipo_estado;
begin

    -- estado
    process (reset, clock)
    begin
        if reset = '1' then
            Eatual <= inicial;
        elsif clock'event and clock = '1' then
            Eatual <= Eprox; 
        end if;
    end process;

    process (clock, fim_medida, fim_transmissao, transmissao_pronto, liga, atencao) 
    begin
      case Eatual is
        when inicial           =>   if liga = '1' then Eprox <= preparacao;
                                      else                  Eprox <= inicial;
                                      end if;

        when preparacao => Eprox <= rotina;

        when rotina => Eprox <= espera_medida;

        when espera_medida  =>  if fim_medida= '1' then  Eprox <= tx_angulo;
                                   else                  Eprox <= espera_medida;
                                   end if;
        
        when tx_angulo   =>  if fim_transmissao='1' then Eprox <= prox_digito_angulo;
                                else                        Eprox <= tx_angulo;
                                end if;

        when prox_digito_angulo  =>  if transmissao_pronto='1' then Eprox <= zera_digitos;
                                    else Eprox <= tx_angulo;
                                    end if;

        when zera_digitos => Eprox <= tx_distancia; 

        when tx_distancia   =>  if fim_transmissao='1' then Eprox <= prox_digito_distancia;
                                else                        Eprox <= tx_distancia;
                                end if;

        when prox_digito_distancia  =>  if transmissao_pronto='1' then
                                            if atencao='0' then Eprox <= final;
                                            else Eprox <= final_atencao;
                                            end if;
                                        else Eprox <= tx_distancia;
                                        end if;

        when final          =>  if liga = '1' then  Eprox <= rotina;
                                else                Eprox <= inicial;
                                end if;

        when final_atencao  => if liga = '1' then  Eprox <= rotina;
                                else                Eprox <= inicial;
                                end if;

        when others         =>  Eprox <= inicial;
      end case;
    end process;

    with Eatual select
        transmitir <= '1' when tx_distancia | tx_angulo, '0' when others;
    with Eatual select
        zera_transmissor <= '1' when prox_digito_distancia | prox_digito_angulo | preparacao, '0' when others;
    with Eatual select
        zera_rx <= '1' when preparacao, '0' when others;
    with Eatual select
        zera_cont_medir <= '1' when rotina, '0' when others;
    with Eatual select
        zera_cont_digitos <= '1' when rotina | zera_digitos, '0' when others;
    with Eatual select
        zera_cont_angulo <= '1' when preparacao, '0' when others;
    with Eatual select
        conta_digito <= '1' when prox_digito_distancia | prox_digito_angulo, '0' when others;
    with Eatual select
        conta_medir <= '1' when espera_medida, '0' when others;
    with Eatual select
        conta_angulo <= '1' when final, '0' when others;
    with Eatual select
        pronto <= '1' when final | final_atencao, '0' when others;
    with Eatual select
        tx_step <= '1' when tx_distancia | prox_digito_distancia, '0' when others;
    with Eatual select
        db_estado <= 
        "0000" when inicial,
        "0001" when preparacao,
        "0010" when rotina,
        "0011" when espera_medida,
        "0100" when tx_angulo,
        "0101" when prox_digito_angulo,
        "0110" when zera_digitos,
        "0111" when tx_distancia,
        "1000" when prox_digito_distancia,
        "1001" when final,
        "1010" when final_atencao,
        "1110" when others;

end architecture;
