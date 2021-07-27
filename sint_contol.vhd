LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

USE WORK.my_convert_p.ALL;

entity sint_control is
  port (	p_i_clk:	in std_logic;
			p_i_rx:		inout std_logic;
			p_o_tx:		inout std_logic;

			p_i_len:	in integer;
			p_i_data: 	in std_logic_vector(143 downto 0);
			p_i_ena: 	in std_logic

		);
end entity ; -- dzu_read

architecture sint_control_behav of sint_control is

-- модуль порта
	component uart1 IS
		generic(
			c_clk_freq:	integer		:= 50_000_000;	-- частота системного генератора 50 МГц
			c_baud_rate:integer		:= 115200;		-- скорость обмена данными 
			c_os_rate:	integer		:= 16;			-- частота передискретизации для обнаружения временного центра принимаемого бита
			c_d_width:	integer		:= 8; 			-- размер передаваемых данных
			c_parity:	integer		:= 0;			-- бит четности 0 - без бита, 1 - с битом
			c_parity_eo:std_logic	:= '0');		-- 0 - четные биты четности, 1 - нечетные биты четности
		port(
			p_i_clk		:	in	std_logic;				
			p_i_reset_n	:	in	std_logic;	-- асинхронный сброс

			p_i_tx_ena	:	in	std_logic;	-- сигнал разрешения передачи
			p_i_tx_data	:	in	std_logic_vector(c_d_width - 1 downto 0);  		-- данные для передач
			p_o_tx		:	out	std_logic;	-- линия передачи данных
			p_o_tx_busy	:	out	std_logic;	-- сигнал "передача осуществляется

			p_i_rx		:	in	std_logic;	-- линия приема данных
			p_o_rx_busy	:	out	std_logic;	-- сигнал "осуществляется прием"
			p_o_rx_error:	out	std_logic;	-- сигнал ошибки приема данных (старт/стоп-бит, бит четности)
			p_o_rx_data	:	out	std_logic_vector(c_d_width - 1 downto 0)); 		-- принятые данные 
	end component;

-- данные 
	SIGNAL s_MEM_COUNTER: integer := 0;												-- условный счетчик
	SIGNAL s_MEM_CELL:	std_logic_vector(143 downto 0) := (others => '0');			-- подготовленный набор бит для передачи в порт

-- порт
	SIGNAL s_RST: std_logic := '0';
	SIGNAL s_TX_ENA, s_TX_BUSY, s_RX_BUSY, s_RX_ERR: std_logic;
	SIGNAL s_RX_PORT, s_TX_PORT: std_logic;
	SIGNAL s_TX_DATA: std_logic_vector(7 downto 0);
	SIGNAL s_RX_DATA: std_logic_vector(7 downto 0);
	
-- автомат управления
	type t_state is (st_idle, st_wait_data, st_read_data, st_delay, st_set_data, st_transmitt_data, st_write_data, st_wait_end_write_data);
	SIGNAL s_FSM: t_state := st_idle;
	
	SIGNAL s_TEMP_COUNTER: integer:=0; 				-- счетчик переданных байт
	SIGNAL s_I:	integer := 0; 						-- вспомогательтный счетчик
	SIGNAL s_INDEX: integer:=0;


begin
	uart1_module: uart1 port map ( 	p_i_clk => 			p_i_clk,
												p_i_reset_n =>		s_RST,
												p_i_tx_ena =>		s_TX_ENA,
												p_i_tx_data =>		s_TX_DATA,
												p_o_tx =>			s_TX_PORT,
												p_o_tx_busy => 	s_TX_BUSY,
												p_i_rx =>			s_RX_PORT,
												p_o_rx_busy => 	s_RX_BUSY,
												p_o_rx_error =>	s_RX_ERR,
												p_o_rx_data => 	s_RX_DATA
	);

----------------------------------------------------------------------------------------
	process(p_i_clk) begin
	
	p_i_rx <= 'Z';
	
		if rising_edge(p_i_clk) then

			case s_FSM is

				when st_idle =>	if s_I >= 5 then
									s_I <= 0;
									s_RST <= '1';
									s_TX_DATA <= (others => '0');

									s_FSM <= st_wait_data;
								end if;
								s_I <= s_I + 1;
								
								s_TX_ENA <= '0';
								s_TX_DATA <= (others => '0');
														
				-- ожидание входных данных
				when st_wait_data => if p_i_ena = '1' then	-- по появленю старт бита на линии приема (RX)
										s_FSM <= st_read_data;		-- переход к считывантю данных на выходе модуля приема
									end if;
									
				-- ожидание снятия сигнала разрешения 
				when st_read_data =>if p_i_ena = '0' then		-- по снятию сигнала занятости приемника (принят байт данных)

			
											
											s_I <= 0;
											p_i_rx <= 'Z';
											--s_FSM <= st_set_data;
											s_FSM <= st_delay;
										

									end if;
-- после получения управляющего слова - задержка для устаканикания линии rx
				when st_delay =>	if s_I >= 20000 then
										s_I <= 0;
										s_FSM <= st_set_data;
									end if;
									s_I <= s_I + 1;
-- передача содержимого памяти
				-- получение очередного слова данных из памяти				
				when st_set_data => 
										s_MEM_CELL <= p_i_data;
										s_MEM_COUNTER <= p_i_len;
										s_INDEX <= p_i_len *8 - 1;
										s_TEMP_COUNTER <= 0;
										s_FSM <= st_transmitt_data;
									

				-- передача очередного байта в порт
				when st_transmitt_data => 	if s_TEMP_COUNTER >= s_MEM_COUNTER then
												s_TEMP_COUNTER <= 0;
												s_I <= 0;
												s_FSM <= st_idle;
												
											else
												s_TEMP_COUNTER <= s_TEMP_COUNTER + 1;
												s_TX_DATA <= s_MEM_CELL(s_INDEX downto s_INDEX - 7);
												--s_MEM_CELL <= s_MEM_CELL (23 downto 0) & x"00";
												s_TX_ENA <= '1';
												s_I <= 0;

												s_FSM <= st_write_data;
											end if;

				-- удержание сигнала разрешения передачи 5 тиков
				when st_write_data => 	s_I <= s_I + 1;
												if s_I >= 5 then 
													s_I <= 0;
													s_TX_ENA <= '0';
													s_MEM_CELL(s_INDEX downto 0) <= s_MEM_CELL (s_INDEX - 8 downto 0) & x"00";
													s_FSM <= st_wait_end_write_data;
												end if;
												
				-- ожидание окончания передачи байтй данных в порт												
				when st_wait_end_write_data => 	if s_TX_BUSY = '0' then
																s_FSM <= st_transmitt_data;
															end if;


				when others =>	s_FSM <= st_idle;

			end case;

		end if;

	end process;
	
--------------------------------------------------------------	
-- процесс для конвертации протокола при передаче
	process(p_i_clk) begin
		if rising_edge(p_i_clk) then
			
			if s_TX_BUSY = '1' then	
				p_o_tx <= not s_TX_PORT;
				p_i_rx <=  s_TX_PORT;
			else
				p_i_rx <= 'Z';
				p_o_tx <= 'Z';
				s_RX_PORT <= p_i_rx;
			end if;
				
		end if;
		
	end process;
-------------------------------------------------------------

end architecture ; -- arch
