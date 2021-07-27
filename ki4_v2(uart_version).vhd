-- модуль управления для блока КИ-4 (в.3)
-- UART


-- добавить задержку перед первой выдачей сиганала на включение синтезатора после подачи питания (около 10 с)


library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

library work;
use work.parameters.all;

use work.my_convert_p.all;

entity ki4_v2 is
	port (	p_i_clk:		in std_logic;
		-- сигналы с внешнего разъема
			p_i_reset:		in std_logic;		-- сигнал сброса (низки уровень - сброс)
			p_i_diap_1:		in std_logic;		-- диапазон шина 1	// код поддиапазона (литеры)
			p_i_diap_2:		in std_logic;		-- диапалон шина 2
			p_i_zone_1:		in std_logic;		-- Зона 1 (Остановка счетчика ТИ, при поступлении ТИ счетчик не изменяет свое значение, СВЧ сигнал на выходе должен присутствовать, частота СВЧ сигнала не изменяется)
			p_i_zone_2:		in std_logic;		-- Зона 2 (Прекращение выдачи СВЧ сигнала, увеличение счетчика продолжается в соответствии с ТИ, при в=разрешении выдачи СВЧ, частота устанавливается в соответствии со знечением счетчика)		
			p_i_reverse:	in std_logic;		-- направление счета (инкремент/декремент)
			p_i_main_tick:	in std_logic;		-- тактовые импульсы при перестроке частоты с шагом в два МГц (счетчик изменяется на 1 или 2 МГц в зависимости от поддиапазона)
			p_i_cnt_tick:	in std_logic;		-- выбор инкремента счетчика (1/16)
			p_o_end_diap:	out std_logic;		-- окончание диапазаона (формируется при достижении счетчиком максималльного значения) МЕТКА НД
			p_o_ak_sr_kp:	out std_logic; 		-- сингал окончания диапазона формируется синхронно с сигналом НД, но дополнительно может поступать с АК СР и КП

			-- сигналы управления синтезатором по SPI
			p_io_rx: 		inout std_logic; -- RX
			p_io_tx:		inout std_logic; -- TX

			-- сигналы управления внутренними частями блока
			p_o_diap_13:		out std_logic;		-- сигнал о работе в первом или третьем поддиапазоне
			p_o_diap_24:		out std_logic;		-- сигнал о работе во втором или четвертом поддиапазоне
			p_o_diap_2:			out std_logic;		-- сигнал о работе во втором поддиапазоне			
			p_o_diap_4:			out std_logic;		-- сигнал о работе в четвертом поддиапазоне
			p_i_end_diap_from_res:	in std_logic	-- сигнал о окончании диапазона от контрольных резонаторов (Срез)
		);
end entity ; -- ki4_upr

architecture ki4_upr_behav of ki4_v2 is
	
-- uart signals
	SIGNAL s_UART_RST, s_TX_ENA, s_TX_BUSY, s_TX, s_RX, s_RX_BUSY, s_RX_ERR: std_logic;
	SIGNAL s_TX_DATA, s_RX_DATA : std_logic_vector (7 downto 0) := (others => '0');
	SIGNAL s_TEMP_DATA : std_logic_vector (c_UATR_SET_NEW_FREQ_LEN - 1 downto 0);
	SIGNAL s_UART_COMMAND_LEN : integer := 0;
	
-- фильтры 
	SIGNAL s_MAIN_TICK_FILTER: 	std_logic_vector(31 downto 0);					-- фильтр основного тактового сигнала
	SIGNAL s_CNT_TICK_FILTER:	std_logic_vector(31 downto 0);					-- фильтр конторольного тактирующего сигнала
	SIGNAL s_DIAP1_FILTER:		std_logic_vector(31 downto 0); 					-- фильт сигнала переключения поддиапазона 1
	SIGNAL s_DIAP2_FILTER:		std_logic_vector(31 downto 0);					-- фильт сигнала переключения поддиапазона 2			
	SIGNAL s_CR_FILTER:			std_logic_vector(31 downto 0);					-- фильт сигнала от контрольных резонаторов				
	SIGNAL s_RST_FILTER:		std_logic_vector(31 downto 0);
	SIGNAL s_ZONE1_FILTER:		std_logic_vector(31 downto 0);					-- фильтр отслеживания сигнала "ЗОНА 1"
	SIGNAL s_ZONE2_FILTER:		std_logic_vector(31 downto 0); 					-- фильтр отслеживания стгнала "ЗОНА 2"

	SIGNAL s_DIAP_DECODE: std_logic_vector(1 downto 0);

	SIGNAL s_END_DIAP:	std_logic := '1';

-- флаги
	SIGNAL s_MT_FLAG, s_CNT_FLAG, s_D1_FLAG, s_D2_FLAG, s_CR_FLAG, s_RST_FLAG, s_ZON1_SET_FLAG, s_ZON2_SET_FLAG, s_ZON1_RST_FLAG, s_ZON2_RST_FLAG: std_logic := '0';

	type t_state is (st_idle, st_check_tick, st_wait_end_out, st_check_zone1, st_calculate_new_freq, st_check_freq_scoupe, st_res_begin_freq, st_res_end_freq,
		st_check_zone2, st_check_end_diap, st_check_diap, st_set_new_freq, st_send_command, st_res_diap, st_wait_1, st_check_end_command);
	SIGNAL s_FSM: t_state;
-- временный счетчик
	SIGNAL s_TEMP_COUNT : integer := 0;
-- текущая частота
	SIGNAL s_CURR_FREQ : integer := 0;
-- текущая частота в виде строки
	SIGNAL s_CURR_FREQ_STR : std_logic_vector(39 downto 0) := (others => '0');

-- счетчики тиков для поддипазонов с разным шагом
	SIGNAL s_FREQ_COUNT_1 : integer	:= c_UART_BEGIN_FREQ_DIAP_1;
	SIGNAL s_FREQ_COUNT_2 :	integer := c_UART_BEGIN_FREQ_DIAP_2;
	SIGNAL s_FREQ_COUNT_3 :	integer := c_UART_BEGIN_FREQ_DIAP_3;
	SIGNAL s_FREQ_COUNT_4 :	integer := c_UART_BEGIN_FREQ_DIAP_4;
-- приращение частоты
	SIGNAL s_CURR_FREQ_INC_1_2 : integer := 0;
	SIGNAL s_CURR_FREQ_INC_3_4 : integer := 0;

	SIGNAL s_FIRST_RES_ZONE_2:	std_logic := '1'; 		-- сигнал первого выключения сигнала ЗОНА 2 



begin

		
	

	-- UART port unit
	uart_unit: entity work.uart1
		generic map(
			c_clk_freq 	=> 50_000_000,	-- частота системного генератора 50 МГц
			c_baud_rate	=> 19_200,		-- скорость обмена данными 
			c_os_rate 	=> 16,			-- частота передискретизации для обнаружения временного центра принимаемого бита
			c_d_width	=> 8, 			-- максимальный размер передаваемых данных
			c_parity 	=> 1,			-- бит четности 0 - без бита, 1 - с битом
			c_parity_eo => '0')		-- 0 - четные биты четности, 1 - нечетные биты четности
		port map (
			p_i_clk		=> p_i_clk,				
			p_i_reset_n	=> s_UART_RST,

			p_i_tx_ena	=> s_TX_ENA,	-- сигнал разрешения передачи
			p_i_tx_data	=> s_TX_DATA,  		-- данные для передач
			p_o_tx		=> s_TX,	-- линия передачи данных
			p_o_tx_busy	=> s_TX_BUSY,	-- сигнал "передача осуществляется

			p_i_rx		=> s_RX,	-- линия приема данных
			p_o_rx_busy	=> s_RX_BUSY,	-- сигнал "осуществляется прием"
			p_o_rx_error=> s_RX_ERR,	-- сигнал ошибки приема данных (старт/стоп-бит, бит четности)
			p_o_rx_data	=> s_RX_DATA ); 		-- принятые данные 
	


	process(p_i_clk) begin
		if rising_edge(p_i_clk) then

	--	s_DIAP_DECODE(0) <= p_i_diap_1;
	--	s_DIAP_DECODE(1) <= p_i_diap_2;

-- 	Shmitt trigger mode
		s_DIAP_DECODE(0) <= not p_i_diap_1;
		s_DIAP_DECODE(1) <= not p_i_diap_2;


-- выдача информации о входных сигналах на внутренние узлы

	-- сиганалы выбора поддипазона для блока контрольных резонаторов
--		p_o_diap_13 <= p_i_diap_1 and (not p_i_zone_2);
--		p_o_diap_24 <= (not p_i_diap_1) and (not p_i_zone_2);
--
--		p_o_diap_2 <= (not p_i_diap_1) and (not p_i_diap_2);
--		p_o_diap_4 <= (not p_i_diap_1) and p_i_diap_2;


-- 	Shmitt trigger mode
		p_o_diap_13 <= ( not p_i_diap_1 ) and ( p_i_zone_2 );
		p_o_diap_24 <= ( p_i_diap_1 ) and ( p_i_zone_2 );

		p_o_diap_2 <= ( p_i_diap_1 ) and ( p_i_diap_2 );
		p_o_diap_4 <= ( p_i_diap_1 ) and ( not p_i_diap_2 );


	-- формирование сигнала "КОНЕЦ" диапазона
		p_o_ak_sr_kp <= s_END_DIAP;
		p_o_end_diap <= s_END_DIAP;

	-- фильтрация входных сигналов		
		s_MAIN_TICK_FILTER <= p_i_main_tick & s_MAIN_TICK_FILTER(31 downto 1);		-- линия приема сигналво основного тактирования
		s_CNT_TICK_FILTER <= p_i_cnt_tick & s_CNT_TICK_FILTER(31 downto 1); 			-- линия према сигналов тактирования в режиме самопроверки
		s_DIAP1_FILTER <= p_i_diap_1 & s_DIAP1_FILTER(31 downto 1); 					-- линии приема сигналов выбора поддиапазона
		s_DIAP2_FILTER <= p_i_diap_2 & s_DIAP2_FILTER(31 downto 1);
		s_RST_FILTER <= p_i_reset & s_RST_FILTER(31 downto 1); 						-- линия према сигнала сброса


		s_ZONE1_FILTER <= p_i_zone_1 & s_ZONE1_FILTER(31 downto 1);
		s_ZONE2_FILTER <= p_i_zone_2 & s_ZONE2_FILTER(31 downto 1);

		s_CR_FILTER <= p_i_end_diap_from_res & s_CR_FILTER(31 downto 1);
---------------------------------------------------------------------------------------------
-- фиксация входящих сигналов

--основной такитирующий импульс
		if s_MAIN_TICK_FILTER = X"00000001" then s_MT_FLAG <= '1';
		end if;

-- контрольный тактирующий импульс
		if s_CNT_TICK_FILTER = X"00000001" then s_CNT_FLAG <= '1';
		end if;

-- сигналы переключения диапазонов
		if ( s_DIAP1_FILTER = X"FFFFFFFE" ) or ( s_DIAP1_FILTER = X"00000001" ) then
			s_D1_FLAG <= '1';
		end if;
		
		if ( s_DIAP2_FILTER = X"FFFFFFFE" ) or ( s_DIAP2_FILTER = X"00000001" ) then
			s_D2_FLAG <= '1';
		end if;

-- сигнал от контрольных резонаторов
		if s_CR_FILTER = X"00000001" then s_CR_FLAG <= '1';
		end if;

-- сигнал сброса
		if s_RST_FILTER = X"00000001" then s_RST_FLAG <= '1';
		end if;

-- установка сигнала зона 1
		if s_ZONE1_FILTER = X"00000001" then s_ZON1_SET_FLAG <= '1';
		end if;

-- установка сигнал зона 2
		if s_ZONE2_FILTER = X"00000001" then s_ZON2_SET_FLAG <= '1';
		end if;
	

	

-- снятие сиганал зона 2
		if s_ZONE2_FILTER = X"FFFFFFFE" then s_ZON2_RST_FLAG <= '1';
		end if;



-------------------------------------------------------------------------
-- автомат управления
-------------------------------------------------------------------------	
		case s_FSM is

			when st_idle =>	if  s_RST_FLAG = '1' then
								s_RST_FLAG <= '0';
								s_FSM <= st_res_diap; 
							else
								s_FSM <= st_check_tick;
							end if;
							s_UART_RST <= '0';
							s_TX_ENA <= '0';

-- обнаружен сигнал сброса
-- в зависимости от кода диапазона, установка начального значения частоты
			when st_res_diap => 	if s_DIAP_DECODE = "01" then 		-- 1 диапазон
										s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_1;
										
									elsif s_DIAP_DECODE = "00" then		-- 2 диапазон
										s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_2;

									elsif s_DIAP_DECODE = "11" then		-- 3 диапазон
										s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_3;

									elsif s_DIAP_DECODE = "10" then		-- 4 диапазон
										s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_4;

									end if;

									s_FREQ_COUNT_1 <= c_UART_BEGIN_FREQ_DIAP_1;
									s_FREQ_COUNT_2 <= c_UART_BEGIN_FREQ_DIAP_2;
									s_FREQ_COUNT_3 <= c_UART_BEGIN_FREQ_DIAP_3;
									s_FREQ_COUNT_4 <= c_UART_BEGIN_FREQ_DIAP_4;

									s_FSM <= st_set_new_freq; -- переход в устновке частоты

-- проверка появления тактового импульса
			when st_check_tick => 	if s_MT_FLAG = '1' and p_i_cnt_tick = '1' then -- появился ТИ на главной линии и на линии самопроверки высокий уровень
										s_CURR_FREQ_INC_1_2 <= c_UART_BASE_STEP_FREQ_DIAP_1_2;  -- базовое значение приращения частоты
										s_CURR_FREQ_INC_3_4 <= c_UART_BASE_STEP_FREQ_DIAP_3_4;
										s_FSM <= st_check_zone1;

									elsif s_CNT_FLAG = '1' and p_i_cnt_tick = '1' then -- появился ТИ на лини 128 мп
										s_CURR_FREQ_INC_1_2 <= c_UART_CONTR_STEP_FREQ_DIAP_1_2;  -- приращение частоты при работе в режиме самоконтроля
										s_CURR_FREQ_INC_3_4 <= c_UART_CONTR_STEP_FREQ_DIAP_3_4;
										s_FSM <= st_check_zone1;

									else
										s_FSM <= st_check_zone2;

									end if;

									if s_FIRST_RES_ZONE_2 = '1' then
										if s_DIAP_DECODE = "01" then 		-- 1 диапазон
											s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_1;
											
										elsif s_DIAP_DECODE = "00" then		-- 2 диапазон
											s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_2;

										elsif s_DIAP_DECODE = "11" then		-- 3 диапазон
											s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_3;

										elsif s_DIAP_DECODE = "10" then		-- 4 диапазон
											s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_4;

										end if;
									end if;

-- проверка состояния сигнала зона 1
			--when st_check_zone1 =>	if s_ZON1_SET_FLAG = '1' or p_i_zone_1 = '1' then 			-- установлен сигнал зона 1 (изменения счетчика не происходят)
-- 	Shmitt trigger mode
			when st_check_zone1 =>	if s_ZON1_SET_FLAG = '1' or p_i_zone_1 = '1' then 			-- установлен сигнал зона 1 (изменения счетчика не происходят)
										--s_ZON1_SET_FLAG <= '0';
										s_CURR_FREQ_INC_1_2 <= 0;
										s_CURR_FREQ_INC_3_4 <= 0;
									end if;
									
									s_FSM <= st_calculate_new_freq;

-- вычисление нового значения частоты
			when  st_calculate_new_freq =>	if p_i_reverse = '1' then 
														s_FREQ_COUNT_1 <= s_FREQ_COUNT_1 + s_CURR_FREQ_INC_1_2;
														s_FREQ_COUNT_2 <= s_FREQ_COUNT_2 + s_CURR_FREQ_INC_1_2;
														s_FREQ_COUNT_3 <= s_FREQ_COUNT_3 + s_CURR_FREQ_INC_3_4;
														s_FREQ_COUNT_4 <= s_FREQ_COUNT_4 + s_CURR_FREQ_INC_3_4;
													elsif p_i_reverse = '0' then
														s_FREQ_COUNT_1 <= s_FREQ_COUNT_1 - s_CURR_FREQ_INC_1_2;
														s_FREQ_COUNT_2 <= s_FREQ_COUNT_2 - s_CURR_FREQ_INC_1_2;
														s_FREQ_COUNT_3 <= s_FREQ_COUNT_3 - s_CURR_FREQ_INC_3_4;
														s_FREQ_COUNT_4 <= s_FREQ_COUNT_4 - s_CURR_FREQ_INC_3_4;
													end if;

													s_FSM <= st_check_freq_scoupe; 		-- проверка не вышла ли частота за границу диапазона
									
-- проверка превышения вычисленного нового значения частоты грниц диапазона
			when st_check_freq_scoupe =>	
								-- 1 поддиапазон
											if s_DIAP_DECODE = "01" then 						
												if s_FREQ_COUNT_1 > c_END_FREQ_DIAP_1 then 	-- счетчик частоты больше масимального значения для 1 поддиапазона

													s_FSM <= st_res_begin_freq;

												elsif s_FREQ_COUNT_1 < c_BEGIN_FREQ_DIAP_1 then	-- счетчик частоты меньше минимльного значения для 1 поддиапазона
													s_FSM <= st_res_end_freq;
												else
													
													s_CURR_FREQ <= s_FREQ_COUNT_1;
													s_FSM <= st_set_new_freq;

												end if;
								-- 2 поддиапзон
											elsif s_DIAP_DECODE = "00" then 					
												if s_FREQ_COUNT_2 > c_END_FREQ_DIAP_2 then 	-- счетчик частоты больше масимального значения для 2 поддиапазона

													s_FSM <= st_res_begin_freq;

												elsif s_FREQ_COUNT_2 < c_BEGIN_FREQ_DIAP_2 then -- счетчик частоты меньше минимльного значения для 2 поддиапазона
													
													s_FSM <= st_res_end_freq;
												else
													s_CURR_FREQ <= s_FREQ_COUNT_2;
													s_FSM <= st_set_new_freq;

												end if;
								-- 3 поддиапзон
											elsif s_DIAP_DECODE = "11" then 					
												if s_FREQ_COUNT_3 > c_END_FREQ_DIAP_3 then 	-- счетчик частоты больше масимального значения для 3 поддиапазона

													s_FSM <= st_res_begin_freq;

												elsif s_FREQ_COUNT_3 < c_BEGIN_FREQ_DIAP_3 then -- счетчик частоты меньше минимльного значения для 3 поддиапазона
													
													s_FSM <= st_res_end_freq;
												else
													s_CURR_FREQ <= s_FREQ_COUNT_3;
													s_FSM <= st_set_new_freq;

												end if;
								-- 4 поддиапзон
											elsif s_DIAP_DECODE = "10" then 				
												if s_FREQ_COUNT_4 > c_END_FREQ_DIAP_4 then 	-- счетчик частоты больше масимального значения для 4 поддиапазона

													s_FSM <= st_res_begin_freq;

												elsif s_FREQ_COUNT_4 < c_BEGIN_FREQ_DIAP_4 then -- счетчик частоты меньше минимльного значения для 4 поддиапазона
													
													s_FSM <= st_res_end_freq;
												else
													s_CURR_FREQ <= s_FREQ_COUNT_4;
													s_FSM <= st_set_new_freq;

												end if;
											
											end if;

-- установка частоты на мимнимальную у всех счетчиков частоты с одновременной установкой 
			when st_res_begin_freq => 	s_END_DIAP <= '0'; 							-- сигнал КД появляется только при увеличении частоты
										s_FREQ_COUNT_1 <= c_UART_BEGIN_FREQ_DIAP_1;
										s_FREQ_COUNT_2 <= c_UART_BEGIN_FREQ_DIAP_2;
										s_FREQ_COUNT_3 <= c_UART_BEGIN_FREQ_DIAP_3;
										s_FREQ_COUNT_4 <= c_UART_BEGIN_FREQ_DIAP_4; 			
										s_FSM <= st_set_new_freq;

-- установка часьльы на максимальную у всех счетчиков
			when st_res_end_freq => 	s_FREQ_COUNT_1 <= c_UART_END_FREQ_DIAP_1;
										s_FREQ_COUNT_2 <= c_UART_END_FREQ_DIAP_2;
										s_FREQ_COUNT_3 <= c_UART_END_FREQ_DIAP_3;
										s_FREQ_COUNT_4 <= c_UART_END_FREQ_DIAP_4;
										s_FSM <= st_set_new_freq;

-- проверка сигнала состяния зона 2
			when st_check_zone2 => 	if s_ZON2_SET_FLAG = '1' then 	 -- установлен сигнал зона 2 (синтезатор выключение синтезатора)
										
										s_ZON2_SET_FLAG <= '0';

										s_TEMP_DATA <= c_UART_OFF;
										s_UART_COMMAND_LEN <= c_UART_OFF_LEN;

										--s_FSM <= st_send_command;
										s_FSM <= st_check_end_command;

									elsif s_ZON2_RST_FLAG = '1' or s_FIRST_RES_ZONE_2 = '1' then 

										s_FIRST_RES_ZONE_2 <= '0';		--	 для первоначального включения синтезатора , в лучае , если сигнал ЗОНА 2 сразу при включении установлен на разрешение реботы синтезатора

										s_ZON2_RST_FLAG <= '0';

										s_TEMP_DATA <= c_UART_ON;
										s_UART_COMMAND_LEN <= c_UART_ON_LEN;

										--s_FSM <= st_send_command;
										s_FSM <= st_check_end_command;

									elsif s_MT_FLAG = '1' or s_CNT_FLAG = '1' then

										s_MT_FLAG <= '0';
										s_CNT_FLAG <= '0';

										s_FSM <= st_set_new_freq;
									else

										s_FSM <= st_check_end_diap;

									end if;

-- проверка сигнала КД от резонаторов
-- сигнал от резонаторов приходит в момент прохождения частоты через начальную частоту диапазона
			when st_check_end_diap => 	if s_CR_FLAG = '1' then   -- появился сигнал с контрольного резонатора
											s_CR_FLAG <= '0';
											s_END_DIAP <= '1';					-- снятие сиганала КД
										
										end if;

										s_FSM <= st_check_diap;

-- проверка изменения кода диапазона 
			when st_check_diap => 	if s_D1_FLAG = '1' or s_D2_FLAG = '1' then  -- если изменился флаг диапазона, перестраиваем частоту на начальную частоту нового диапазона + количество импульсов

										s_D1_FLAG <= '0';
										s_D2_FLAG <= '0';

										if s_DIAP_DECODE = "01" then 		-- 1 диапазон
											s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_1 + s_FREQ_COUNT_1;

										elsif s_DIAP_DECODE = "00" then		-- 2 диапазон
											s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_2 + s_FREQ_COUNT_2;

										elsif s_DIAP_DECODE = "11" then		-- 3 диапазон
											s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_3 + s_FREQ_COUNT_3;

										elsif s_DIAP_DECODE = "10" then		-- 4 диапазон
											s_CURR_FREQ <= c_UART_BEGIN_FREQ_DIAP_4 + s_FREQ_COUNT_4;

										end if;

										s_FSM <= st_set_new_freq;
									else
										s_FSM <= st_idle;

									end if;

-- изменение значения частоты

		when st_set_new_freq => if s_ZON1_SET_FLAG = '1' or p_i_zone_1 = '1' then

										s_ZON1_SET_FLAG <= '0';
										s_FSM <= st_idle;

									elsif p_i_zone_2 = '0' then

										s_FSM <= st_idle;
									else 
			-- формирование команды изменения частоты синтезатором
-- преобразование частоты из целочисленного типа в строковый 
-- запись полученного значения в разряды нового значения частоты в команду изменения частоты
										s_TEMP_DATA (c_UATR_SET_NEW_FREQ_BEG_FREG  downto c_UATR_SET_NEW_FREQ_BEG_FREG - c_UART_FREQ_CODE_LEN) <= fIntToLogVect(s_CURR_FREQ);				
										s_UART_COMMAND_LEN <= c_UATR_SET_NEW_FREQ_LEN;

										--s_FSM <= st_send_command;

										s_FSM <= st_check_end_command;
									end if;

-- проверка, окончания команды
			when st_check_end_command => if s_UART_COMMAND_LEN = 0 then
											s_FSM <= st_check_end_diap;
										else
											s_TX_DATA <= s_TEMP_DATA(c_UATR_SET_NEW_FREQ_LEN - 1 downto c_UATR_SET_NEW_FREQ_LEN - 8);
											s_TEMP_DATA <= s_TEMP_DATA(c_UATR_SET_NEW_FREQ_LEN - 9 downto 0) & X"00";
											s_UART_COMMAND_LEN <= s_UART_COMMAND_LEN - 8;
											s_FSM <= st_send_command;
										end if;



-- пересылка команды в синтезатор
			when st_send_command => s_UART_RST <= '1';
									s_TX_ENA <= '1';

									s_TEMP_COUNT <= 0;
									s_FSM <= st_wait_1;

-- задержка перед переходом на ожидание окончания пердаче
			when st_wait_1 =>  if s_TEMP_COUNT >= 5 then
										s_TEMP_COUNT <= 0;
										s_TX_ENA <= '0';
										s_FSM <= st_wait_end_out;
									end if;
									s_TEMP_COUNT <= s_TEMP_COUNT + 1;

-- ожидание окончания передачи команды в синтезатор
			when st_wait_end_out => if s_TX_BUSY = '0' then
			 							--s_TX_ENA <= '0';
			 							s_UART_RST <= '0';

			 							s_MT_FLAG <= '0';
										s_CNT_FLAG <= '0';
			 							s_FSM <= st_check_end_command;
			 						else
			 							s_FSM <= st_wait_end_out;

			 						end if;
			
			when others => s_FSM <= st_idle;

		end case;

		end if;
	end process;

	--------------------------------------------------------------	
-- процесс для конвертации протокола при передаче
	process(p_i_clk) begin
		if rising_edge(p_i_clk) then
			
			if s_TX_BUSY = '1' then	
				p_io_tx <= not s_TX;
				p_io_rx <=  s_TX;
			else
				p_io_rx <= 'Z';
				p_io_tx <= 'Z';
				s_RX <= p_io_rx;
			end if;
				
		end if;
		
	end process;
-------------------------------------------------------------

end architecture ; -- ki4