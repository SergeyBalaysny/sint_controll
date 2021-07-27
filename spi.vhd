library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.parameters.all;

entity spi is
	generic (
			c_clk:	integer := 50_000_000;	-- частота тактового генератора (Гц)
			c_speed: integer := 500_000 	-- частота передачи бит данных(Гц)
			
	);
 	port (	p_i_clk: 		in std_logic;

  	-- выход spi
  			p_o_spi_cs:		out std_logic;
  			p_o_spi_mosi: 	out std_logic;
  			p_o_spi_clk:	out std_logic;

  	-- внутренний интерфейс
  			p_i_rst:		in std_logic;
  			p_i_data:		in std_logic_vector(c_LEN downto 0);
  			p_i_data_len:	in integer := 0;
  			p_i_set_data:	in std_logic; 		-- строб установки данных
  			p_o_out_busy:	out std_logic 		-- строб занятости выдачи данных
  	) ;
end entity ; -- spi


architecture spi_behav of spi is


	type t_state is (st_idle, st_set_data, st_first_front, st_second_front);
	SIGNAL s_FSM : t_state;

	SIGNAL s_BUFFER: std_logic_vector(c_LEN downto 0);
	SIGNAL s_BUF_CNT: integer := 0;
	SIGNAL s_COUNTER: integer := 0;

	constant c_DELAY: integer := c_clk / c_speed; 		-- коэффициент деления тактового импульса

	SIGNAL s_SPI_CLK: std_logic := '0';
	SIGNAL s_SPI_CS:std_logic := '1';
	SIGNAL s_SPI_DATA: std_logic := '0';
	SIGNAL s_BUSY: std_logic := '0';


begin

	p_o_spi_clk <= s_SPI_CLK;
	p_o_spi_cs <= s_SPI_CS;
	p_o_spi_mosi <= s_SPI_DATA;
	p_o_out_busy <= s_BUSY;

	process(p_i_clk) begin
		if rising_edge(p_i_clk) then

			case s_FSM is
-- начальное состояние - проверяем сигнал сброса
				when st_idle =>	if p_i_rst = '1' then
									s_BUFFER <= (others => '0');
									s_SPI_CS <= '1';
									s_SPI_CLK <= '0';
									s_SPI_DATA <= '0';
									s_FSM <= st_idle;

								else 
									s_FSM <= st_set_data;
									
								end if;
-- считывание данных в регистр
				when st_set_data =>	if p_i_set_data = '1' then
										s_BUFFER <= p_i_data;
										s_BUF_CNT <= p_i_data_len;
										s_COUNTER <= 0;

										s_SPI_CS <= '0';
										s_SPI_CLK <= '0';
										s_BUSY <= '1';


										s_FSM <= st_first_front;
									else
										s_SPI_CS <= '1';
										s_SPI_CLK <= '0';
										s_SPI_DATA <= '0';
										s_FSM <= st_idle;
									end if;
-- формирование перехода с высокого уровня на низкий на линии SPI_CLK с выставлением на линии MOSI очередного бита данных из регистра
				when st_first_front =>	s_COUNTER <= s_COUNTER + 1;

										if s_COUNTER >= c_DELAY then
											s_COUNTER <= 0;
											
											if s_BUF_CNT = 0 then 		-- при опустошении буфера отпускание линии передачи 
												s_BUSY <= '0'; 			-- снятие сигнала заяности
												s_SPI_CS <= '1';
												s_SPI_DATA <= '0';
												s_FSM <= st_idle;

											else
												s_BUF_CNT <= s_BUF_CNT - 1;
												s_SPI_CLK <= '0';
												s_SPI_DATA <= s_BUFFER(c_LEN);
												s_BUFFER <= s_BUFFER(c_LEN - 1 downto 0) & '0';
												s_FSM <= st_second_front;

											end if;
										end if;
-- форрирование перехода с низкого уровня на высокий на линии SPI_CLK, по которому ведомый считывает бит с линии SPI_MOSI
				when st_second_front => s_COUNTER <= s_COUNTER + 1;

										if s_COUNTER >= c_DELAY then
											s_COUNTER <= 0;
											s_SPI_CLK <= '1';
											s_FSM <= st_first_front;
										end if;




				when others => 	s_FSM <= st_idle;

			end case;

		end if;
	end process;

end architecture ; -- arch