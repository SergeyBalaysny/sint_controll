LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity uart1 IS
	generic(
		c_clk_freq:	integer		:= 50_000_000;	-- частота системного генератора 50 МГц
		c_baud_rate:integer		:= 19_200;		-- скорость обмена данными 
		c_os_rate:	integer		:= 16;			-- частота передискретизации для обнаружения временного центра принимаемого бита
		c_d_width:	integer		:= 8; 			-- размер передаваемых данных
		c_parity:	integer		:= 1;			-- бит четности 0 - без бита, 1 - с битом
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
end uart1;
		
architecture logic of uart1 is

	type t_tx_machine is (st_idle, st_transmit);	-- автомат передачи
	type t_rx_machine is (st_idle, st_receive);		-- автомат приема
	SIGNAL	s_tx_FSM:	t_tx_machine;			
	SIGNAL	s_rx_FSM:	t_rx_machine;			

	SIGNAL	s_baud_pulse:	std_logic := '0';	-- флаг бита обмена данными
	SIGNAL	s_os_pulse:		std_logic := '0'; 	-- флаг передискретизации
	SIGNAL	s_parity_error:	std_logic;			-- флаг ошибки четности при приеме
	SIGNAL	s_rx_parity:	std_logic_vector(c_d_width downto 0);	-- массив вычисления четности при приеме
	SIGNAL	s_tx_parity:	std_logic_vector(c_d_width downto 0);  	-- массив расчета четности при передаче
	SIGNAL	s_rx_buffer:	std_logic_vector(c_parity + c_d_width downto 0) := (others => '0');  	-- буфер приема
	SIGNAL	s_tx_buffer:	std_logic_vector(c_parity + c_d_width + 1 downto 0) := (others => '1');	-- буфер передачи

begin
-------------------------------------------------------------------------------------------------------------------------------------
	-- вычисление частоты обмена и частоты передискретизации для опредедения времени считывания состояния принимаемого бита
	process(p_i_reset_n, p_i_clk)
		variable v_count_baud:	integer range 0 to c_clk_freq / c_baud_rate - 1 := 0;				-- счетчик частоты обмена битами
		variable v_count_os:	integer range 0 to c_clk_freq / c_baud_rate / c_os_rate - 1 := 0;	-- счетчик частоты передискретизации

	begin
		if p_i_reset_n = '0'  then								-- асинхронный сброс счетчиков

			s_baud_pulse <= '0';								
			s_os_pulse <= '0';									
			v_count_baud := 0;									
			v_count_os := 0;									

		elsif rising_edge(p_i_clk) then

			-- установка флага периода обмена даными в зависимости от частоты
			if (v_count_baud < c_clk_freq / c_baud_rate - 1) then 	-- пока не отсчитали период
				v_count_baud := v_count_baud + 1;					-- считаем тики
				s_baud_pulse <= '0';								-- флаг окончангия периода = 0
			else													-- если досчитали 
				v_count_baud := 0;									-- сброс счетчика
				s_baud_pulse <= '1';								-- установка флага окончания периода
				v_count_os := 0;									
			end if;

			-- установка флага передискретизации в зависимости от частоты
			if(v_count_os < (c_clk_freq / (c_baud_rate * c_os_rate)) - 1) then	
				v_count_os := v_count_os + 1;						
				s_os_pulse <= '0';										
			else												
				v_count_os := 0;									
				s_os_pulse <= '1';								
			end if;

		end if;

	end process;
------------------------------------------------------------------------------------------------------------------
	-- автомат приема данных
	process(p_i_reset_n, p_i_clk)
			variable v_rx_count:	integer range 0 to c_parity + c_d_width + 2 := 0;	-- счетчик принятых бит
			variable v_os_count:	integer range 0 to c_os_rate - 1 := 0;				-- счетчик передискретизации при приеме
	begin
		if p_i_reset_n = '0' then														-- сброс

			v_os_count := 0;															
			v_rx_count := 0;															
			p_o_rx_busy <= '0';															

			p_o_rx_error <= '0';														
			p_o_rx_data <= (others => '0');												
			s_rx_FSM <= st_idle;														

		elsif rising_edge(p_i_clk) and s_os_pulse = '1' then  					-- сработал флаг на разрешение считывание бита при передискретизации - можно считывыать бит данных

			case s_rx_FSM is

				when st_idle =>	p_o_rx_busy <= '0';								-- сброс флага прием данных											
								if(p_i_rx = '0') then 							-- появился старт-бит
																				
									if(v_os_count < c_os_rate / 2) then			-- с момента появления старт отсчитываем половину периода передескритезации для старт бита
										v_os_count := v_os_count + 1;								
										s_rx_FSM <= st_idle;										
									else										-- досчитали до середины принимаемого бита данных
										v_os_count := 0;											
										v_rx_count := 0;											
										p_o_rx_busy <= '1';											
										s_rx_FSM <= st_receive;					-- переход с состояние чтения бита
									end if;

								else											-- старт бит не появился
									v_os_count := 0;							-- ожидание появления старт бита	
									s_rx_FSM <= st_idle;									
								end if;													
								

				when st_receive =>	if v_os_count < (c_os_rate - 1) then			-- ожидание 1 периода передискретизации перед считванием бита данных 
										v_os_count := v_os_count + 1;		
										s_rx_FSM <= st_receive;				

									elsif v_rx_count < (c_parity + c_d_width) then	-- проверка буфера приема считанных бит 
										v_os_count := 0;  											
										v_rx_count := v_rx_count + 1;								
										s_rx_buffer <= p_i_rx & s_rx_buffer(c_parity + c_d_width downto 1); -- добавление считанного бита в буфер при его недозаполенности
										s_rx_FSM <= st_receive;										

									else													-- буфер приема данных заполнен
										p_o_rx_data <= s_rx_buffer(c_d_width downto 1);		-- считаный байт данных передается из модуля				
										p_o_rx_error <= s_rx_buffer(0) or s_parity_error or not p_i_rx;			-- формирование флага состояния чтения данных (ошибка четности, стоп бита)
										p_o_rx_busy <= '0';									-- сброс флага занятости приема
										s_rx_FSM <= st_idle;							

									end if;				
					
			end case;
		end if;
	end process;
		
	-- вычисление бита четности принятых данных
	s_rx_parity(0) <= c_parity_eo;

	rx_parity_logic: for i in 0 to c_d_width-1 generate
		s_rx_parity(i+1) <= s_rx_parity(i) xor s_rx_buffer(i+1);
	end generate;

	with c_parity select  -- сравнение вычисленного бита четности с флагом проверки бита чтности
		s_parity_error <= 	s_rx_parity(c_d_width) xor s_rx_buffer(c_parity + c_d_width) when 1,	-- при контролбита четности проверяем бит
							'0' when others;														-- без контроля бита четности
	
------------------------------------------------------------------------------------------------------------------------------------------------		
	-- автомат передачи данных
	process(p_i_reset_n, p_i_clk)
		variable v_tx_count:	integer range 0 to c_parity + c_d_width + 3 := 0;  			-- количество перерданных бит данных
	begin
		if p_i_reset_n = '0' then															-- сброс автомата
			v_tx_count := 0;																
			p_o_tx <= '1';																	
			p_o_tx_busy <= '1';																
			s_tx_FSM <= st_idle;
																		
		elsif rising_edge(p_i_clk) then

			case s_tx_FSM is
				when st_idle =>	if(p_i_tx_ena = '1') then													-- разрешение передачи данных
									s_tx_buffer(c_d_width + 1 downto 0) <=  p_i_tx_data & '0' & '1';	-- перемещение в буфер передачи данных со старт-битом

									if(c_parity = 1) then												-- использование бита четности при передаче
										s_tx_buffer(c_parity + c_d_width + 1) <= s_tx_parity(c_d_width);-- добавление в буфер передачи данных вычисленного бита четности
									end if;

									p_o_tx_busy <= '1';													-- выставление флага занятости автомата передачи данных
									v_tx_count := 0;													-- сброс счетчика перданных бит
									s_tx_FSM <= st_transmit;											-- переход к передаче данных

								else																	-- нет сигнала разрешения передачи данных
									p_o_tx_busy <= '0';													-- снятие флага занятости автомата передачи											
									s_tx_FSM <= st_idle;												
								end if;																	
					
-- атомат передачи данных
				when st_transmit =>	if(s_baud_pulse = '1') then											-- ожидание флага периода обмена данными 
				--(флаг выставляется во при достижении счетчика времени величины, связанной со скоростью передачи данных)
										v_tx_count := v_tx_count + 1;									-- увеличение числа переданных бит
										s_tx_buffer <= '1' & s_tx_buffer(c_parity + c_d_width + 1 downto 1);	-- сдвиг буфера передачи данных на 1 бит
									end if;

									if(v_tx_count < c_parity + c_d_width + 3) then						-- не все биты из буфера переданы
										s_tx_FSM <= st_transmit;										-- переход в состояние передачи бит
									else																-- все биты переданы
										s_tx_FSM <= st_idle;											-- переход в состояние ожидания разрешения на передачу
									end if;																
					
			end case;

			p_o_tx <= s_tx_buffer(0);																	-- на линию данных выставляется самый младший бит буфера передачи данных

		end if;

	end process;	
	
	-- вычисление бита четности передаваемых данных
	s_tx_parity(0) <= c_parity_eo;

	tx_parity_logic: for i in 0 to c_d_width - 1 generate
		s_tx_parity(i + 1) <= s_tx_parity(i) xor p_i_tx_data(i);
	end generate;
	
end logic;