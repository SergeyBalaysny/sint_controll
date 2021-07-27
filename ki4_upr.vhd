
-- модуль управления для блока КИ-4 (в.1)

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

entity ki4_upr is
	port (	p_i_clk:		in std_logic;
		-- сигналы с внешнего разъема
			p_i_rst:		in std_logic;		-- сигнал сброса (низки уровень - сброс)
			p_i_diap_1:		in std_logic;		-- диапазон шина 1	// код поддиапазона (литеры)
			p_i_diap_2:		in std_logic;		-- диапалон шина 2
			p_i_zone_1:		in std_logic;		-- Зона 1 (Остановка счетчика ТИ, при поступлении ТИ счетчик не изменяет свое значение, СВЧ сигнал на выходе должен присутствовать, частота СВЧ сигнала не изменяется)
			p_i_zone_2:		in std_logic;		-- Зона 2 (Прекращение выдачи СВЧ сигнала, увеличение счетчика продолжается в соответствии с ТИ, при в=разрешении выдачи СВЧ, частота устанавливается в соответствии со знечением счетчика)		
			p_i_reverse:	in std_logic;		-- направление счета (инкремент/декремент)
			p_i_main_tick:	in std_logic;		-- тактовые импульсы при перестроке частоты с шагом в два МГц (счетчик изменяется на 1)
			p_i_cnt_tick:	in std_logic;		-- выбор инкремента счетчика (1/16)
			p_o_end_diap:	out std_logic;		-- окончание диапазаона (формируется при достижении счетчиком максималльного значения) МЕТКА НД
			p_o_ak_sr_kp:	out std_logic; 		-- сингал окончания диапазона формируется синхронно с сигналом НД, но дополнительно может поступать с АК СР и КП

			-- сигналы управления синтезатором
			p_o_sint_change:	out std_logic;	-- сигнал установки нового состояния синтезатора
			p_o_sint_freq_code: out std_logic_vector(10 downto 0);	-- текущий код частоты
			p_o_sint_diap:		out std_logic_vector(1 downto 0);	-- текущий код поддиапазона

			-- сигналы управления внутренними частями блока
			p_o_diap_13:		out std_logic;		-- сигнал о работе в первом или третьем поддиапазоне
			p_o_diap_24:		out std_logic;		-- сигнал о работе во втором или четвертом поддиапазоне
			p_o_diap_2:			out std_logic;		-- сигнал о работе во втором поддиапазоне			
			p_o_diap_4:			out std_logic;		-- сигнал о работе в четвертом поддиапазоне
			p_i_end_diap_from_res:	in std_logic	-- сигнал о окончании диапазона от контрольных резонаторов

		);
end entity ; -- ki4_upr

architecture ki4_upr_behav of ki4_upr is
	SIGNAL s_DELAY:	integer;
	SIGNAL s_COUNTER: std_logic_vector(11 downto 0) := (others => '0');			-- счетчик тиков
	SIGNAL s_DELTA:	std_logic_vector(11 downto 0);								-- величина приращения счетчика тиков
	SIGNAL s_MAIN_TICK_FILTER: 	std_logic_vector(3 downto 0);					-- фильтр основного тактового сигнала
	SIGNAL s_CNT_TICK_FILTER:	std_logic_vector(3 downto 0);					-- фильтр конторольного тактирующего сигнала
	SIGNAL s_DIAP1_FILTER:		std_logic_vector(3 downto 0); 					-- фильт сигнала переключения поддиапазона 1
	SIGNAL s_DIAP2_FILTER:		std_logic_vector(3 downto 0);					-- фильт сигнала переключения поддиапазона 2
	SIGNAL s_END_DIAP_FROM_RES_FILTER: std_logic_vector(3 downto 0);			-- фильт сигнала от контрольных резонаторов
	SIGNAL s_CR_FILTER:			std_logic_vector(3 downto 0);
	SIGNAL s_RST_FILTER:		std_logic_vector(3 downto 0);
	SIGNAL s_CHANGE_SGN:	std_logic := '1';

	SIGNAL s_DIAP_DECODE: std_logic_vector(1 downto 0);



	SIGNAL s_END_DIAP:	std_logic := '1';

-- флаги
	SIGNAL s_MT_FLAG, s_CNT_FLAG, s_D1_FLAG, s_D2_FLAG, s_CR_FLAG, s_RST_FLAG: std_logic := '0';

	SIGNAL s_MAIN_TICK_COUNTER_F, s_MAIN_TICK_COUNTER_B: integer := 0;			-- счетчик количества фронтов и срезов тактовых импульсов



	type t_state is (st_check_RST, st_change_counter, st_check_TICK, st_check_DIAP, st_set_new_state, st_check_cnt_tick,st_check_counter,st_set_end_diap_sgn);
	SIGNAL s_FSM: t_state;

begin
	
	process(p_i_clk) begin
		if rising_edge(p_i_clk) then

		s_DIAP_DECODE(0) <= p_i_diap_1;
		s_DIAP_DECODE(1) <= p_i_diap_2;
-- выдача информации о входных сигналах на внутренние узлы

	-- сиганалы для слока контрольных резонаторов
		p_o_diap_13 <= p_i_diap_1 and (not p_i_zone_2);
		p_o_diap_24 <= (not p_i_diap_1) and (not p_i_zone_2);
		p_o_diap_2 <= (not p_i_diap_1) and (not p_i_diap_2);
		p_o_diap_4 <= (not p_i_diap_1) and p_i_diap_2;


		p_o_ak_sr_kp <= s_END_DIAP;
		p_o_end_diap <= s_END_DIAP;
-- управление включением синтезаторов
-- включение синтезатора с заданным кодом диапазона производится при наличии сигнала разрешения работы синтезаторов (Зона 2),
		p_o_sint_freq_code <= s_COUNTER(10 downto 0);
		p_o_sint_change <= s_CHANGE_SGN;
		p_o_sint_diap(0) <= p_i_diap_1;
		p_o_sint_diap(1) <= p_i_diap_2;

-- фильтрация входных сигналов
		
		s_MAIN_TICK_FILTER <= p_i_main_tick & s_MAIN_TICK_FILTER(3 downto 1);
		s_CNT_TICK_FILTER <= p_i_cnt_tick & s_CNT_TICK_FILTER(3 downto 1);
		s_DIAP1_FILTER <= p_i_diap_1 & s_DIAP1_FILTER(3 downto 1);
		s_DIAP2_FILTER <= p_i_diap_2 & s_DIAP2_FILTER(3 downto 1);
		--s_CR_FILTER <= p_i_end_diap_from_res & s_CR_FILTER(3 downto 1);
		s_RST_FILTER <= p_i_rst & s_RST_FILTER(3 downto 1);

-- фиксация входящих сигналов

--основной такитирующий импульс
		if s_MAIN_TICK_FILTER(1) = '0' and s_MAIN_TICK_FILTER(0) = '1' then 
			s_MT_FLAG <= '1';
			s_MAIN_TICK_COUNTER_F <= s_MAIN_TICK_COUNTER_F + 1;
		end if;

		if s_MAIN_TICK_FILTER(1) = '1' and s_MAIN_TICK_FILTER(0) = '0' then 
			s_MAIN_TICK_COUNTER_B <= s_MAIN_TICK_COUNTER_B + 1;
		end if;
-- контрольный тактирующий импульс
		if s_CNT_TICK_FILTER(1) = '0' and s_CNT_TICK_FILTER(0) = '1' then
			s_CNT_FLAG <= '1';
		end if;

-- сигналы переключения диапазонов
		if (s_DIAP1_FILTER(1) = '1' and s_DIAP1_FILTER(0) = '0') or (s_DIAP1_FILTER(1) = '0' and s_DIAP1_FILTER(0) = '1') then
			s_D1_FLAG <= '1';
		end if;
		
		if (s_DIAP2_FILTER(1) = '1' and s_DIAP2_FILTER(0) = '0') or (s_DIAP2_FILTER(1) = '0' and s_DIAP2_FILTER(0) = '1') then
			s_D2_FLAG <= '1';
		end if;

-- сигнал от контрольных резонаторов
--		if s_CR_FILTER(1) = '0' and s_CR_FILTER(0) = '1' then
--			s_CR_FLAG <= '1';
--		end if;


		if s_RST_FILTER(1) = '0' and s_RST_FILTER(0) = '1' then
			s_RST_FLAG <= '1';
		end if;
	
		case s_FSM is

-- проверка сигнала сброса 
			when st_check_RST =>	if s_RST_FLAG = '1' and  p_i_rst = '0' then				-- при низком уровне сигнала сброса - обнуление счетчика
			 							s_COUNTER <= (others => '0');
			 							s_RST_FLAG <= '0';
			 							s_DELAY <= 0;
			 							s_MAIN_TICK_COUNTER_F <= 0;
			 							s_MAIN_TICK_COUNTER_B <= 0;
			 							s_FSM <= st_set_new_state; 		-- переход в состояние генерации сигнала изменения состояния синтезатора

			 						elsif s_RST_FLAG = '0' and p_i_rst = '0' then			-- после обработки появления сигнала сброса ожидания снятия сигнала
			 							s_FSM <= st_check_RST;

			 						else 
			 							s_FSM <= st_check_TICK;			-- при высоком уровне сигнала счетчика - проверка состояния основного тактового 

			 						end if;

-- проверка состояния основного тактового сигала
			when st_check_TICK => 	if (s_MT_FLAG = '1') and (p_i_cnt_tick = '1') then	-- был переход основного тактового сигнала с высокого уровня на низкий
										s_DELTA <= "000000000001";		-- шаг перестройки счетчика 1
										s_FSM <= st_change_counter;		-- переход к изменению состояния проверки счетчика контрольных тактов

									else 
										s_FSM <= st_check_cnt_tick;

									end if;

-- проверка состояния флага тактовых импульсов самоконтроля
			when st_check_cnt_tick => 	if s_CNT_FLAG = '1' then 		-- сработал флаг на прием тактовых импульсов по линиии ТИ самопроверки
											s_DELTA <= "000000010000";		-- шаг перестройки счетчика 64 
											s_FSM <= st_change_counter;

										else
											s_FSM <= st_check_DIAP;

										end if;

-- проверка состояния флага переключения 
			when st_check_DIAP => 	if (s_D1_FLAG = '1') or (s_D2_FLAG = '1') then
										s_D1_FLAG <= '0';
										s_D2_FLAG <= '0';
										s_DELAY <= 0;
										
										s_FSM <= st_set_new_state;
									else
										s_FSM <= st_check_RST;
									end if;


-- попытка изменить значение счетчика импульсов
			when st_change_counter => 	if p_i_zone_1 = '0' then

											if p_i_reverse = '1' then
											 	s_COUNTER <= s_COUNTER + s_DELTA;

											elsif p_i_reverse = '0' then 
												s_COUNTER <= s_COUNTER - s_DELTA;

											end if;

											s_FSM <= st_check_counter;

										else
											s_MT_FLAG <= '0';
											s_CNT_FLAG <= '0';
											s_FSM <= st_check_RST;

										end if;

-- проверка счетчика на превышение над порогом
			when st_check_counter => 	if s_COUNTER(11) = '1' and s_DIAP_DECODE /= "01"  then 			-- произошло переполнение счетчика (для 1, 2, 3 диапазонов переполнение при 2048 импульсах)
											s_COUNTER <= (others => '0');
											s_MAIN_TICK_COUNTER_B <= 0;
											s_MAIN_TICK_COUNTER_F <= 0;
											s_FSM <= st_set_end_diap_sgn;		-- переход к формированию сигнала КОНЕЦ ДИАПАЗОНА
										elsif s_COUNTER = "011000000000" and s_DIAP_DECODE = "01" then -- для 4 диапазаона переполнение при 1536 импульсах
											s_COUNTER <= (others => '0');
											s_MAIN_TICK_COUNTER_B <= 0;
											s_MAIN_TICK_COUNTER_F <= 0;
											s_FSM <= st_set_end_diap_sgn;		-- переход к формированию сигнала КОНЕЦ ДИАПАЗОНА
										else
											s_DELAY <= 0;
											
											s_FSM <= st_set_new_state;

										end if;

-- сигнал установки нового состояни у синетзатора
			when st_set_new_state => 	s_DELAY <= s_DELAY + 1;
										s_CHANGE_SGN <= '0';
										if s_DELAY >= 8 then
											s_DELAY <= 0;
											s_CHANGE_SGN <= '1';
											s_MT_FLAG <= '0';
											s_CNT_FLAG <= '0';
											s_FSM <= st_check_RST;
										end if;
-- установка сигнала конец диапазона
			when st_set_end_diap_sgn => if (p_i_reverse = '1') and (p_i_cnt_tick = '1') and (s_MT_FLAG = '1') and (s_CNT_FLAG = '0') then	-- сигнал КД формируется при РЕВЕРС = "1", 128МП = "1" и тактированию по линии основных ТИ 

											-- проверка на наличие синала от контрольнных резонаторов

											-- от блока контрольеных резонаторов поступил сигнал

											--if s_CR_FLAG = '1' and p_i_end_diap_from_res = '0' then 
											if p_i_end_diap_from_res = '0' then 
												-- длительность сигнала КД равна трем полным тактовым импульсам по линии основного тактирования
												if s_MAIN_TICK_COUNTER_F < 3 and s_MAIN_TICK_COUNTER_B < 3 then 
													s_END_DIAP <= '0';
												else 
													s_END_DIAP <= '1';
													s_MAIN_TICK_COUNTER_B <= 0;
													s_MAIN_TICK_COUNTER_F <= 0;

													s_DELAY <= 0;
													s_FSM <= st_set_new_state;
												end if;

											-- от блока контрольных резонаторов не поступил сигнал 
											--elsif s_CR_FLAG = '0' and p_i_end_diap_from_res = '1' then
											elsif p_i_end_diap_from_res = '1' then

												-- длительность сигнала КД равна 194 полным тактовым импульсам по линии основного тактирования
												if s_MAIN_TICK_COUNTER_F < 194 and s_MAIN_TICK_COUNTER_B < 194 then 
													s_END_DIAP <= '0';
												else 
													s_END_DIAP <= '1';
													s_MAIN_TICK_COUNTER_B <= 0;
													s_MAIN_TICK_COUNTER_F <= 0;

													s_DELAY <= 0;
													s_FSM <= st_set_new_state;
												end if;

											else 
												s_END_DIAP <= '1';

											end if;
										else
											s_END_DIAP <= '1';
											
										end if;				

			when others => s_FSM <= st_check_RST;

		end case;

		end if;
	end process;

end architecture ; -- ki4