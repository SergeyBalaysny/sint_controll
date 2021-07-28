LIBRARY ieee;
USE ieee.std_logic_1164.all;

entity ki4_v2_tb is
 
end entity ; -- ki4_v2_tb


architecture arch of ki4_v2_tb is

	SIGNAL s_CLK: std_logic;
	SIGNAL s_D1, s_D2, s_Z1, s_Z2, s_REV, s_RST, s_MT, s_CT, s_END_DIAP, s_AKSR: std_logic;
	SIGNAL s_SPI_MOSI, s_SPI_CS, s_SPI_CLK: std_logic;
	SIGNAL s_RX, s_TX : std_logic;
	SIGNAL s_DIAP13, s_DIAP24, s_DIAP2, s_DIAP4, s_RESONATOR_SIGNAL, s_SINT_POW_ON: std_logic;

	component ki4_v2 is
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
			p_o_spi_cs:		out std_logic; 		-- строб передачи данных
			p_o_spi_clk:	out std_logic; 		-- тактовые импульсы
			p_o_spi_mosi:	out std_logic; 		-- данные
			-- сигналы управления синтезатором по UART
			--p_io_rx: 		inout std_logic; -- RX
			--p_io_tx:		inout std_logic; -- TX

			-- сигналы управления внутренними частями блока
			p_o_diap_13:		out std_logic;		-- сигнал о работе в первом или третьем поддиапазоне
			p_o_diap_24:		out std_logic;		-- сигнал о работе во втором или четвертом поддиапазоне
			p_o_diap_2:			out std_logic;		-- сигнал о работе во втором поддиапазоне			
			p_o_diap_4:			out std_logic;		-- сигнал о работе в четвертом поддиапазоне
			p_i_end_diap_from_res:	in std_logic;	-- сигнал о окончании диапазона от контрольных резонаторов (Срез)

			p_i_sint_power_on:	in std_logic 		-- линия проверки наличия питания синтезатора
		);
	end component ; -- ki4_v2

begin
	
 	ki4_control_unit: ki4_v2 port  map (	

 			p_i_clk 		=> s_CLK,
		-- сигналы с внешнего разъема
			p_i_reset 		=> s_RST,
			p_i_diap_1 		=> s_D1,
			p_i_diap_2 		=> s_D2,
			p_i_zone_1		=> s_Z1,
			p_i_zone_2		=> s_Z2,
			p_i_reverse	 	=> s_REV,
			p_i_main_tick	=> s_MT,
			p_i_cnt_tick  	=> s_CT,
			p_o_end_diap 	=> s_END_DIAP,
			p_o_ak_sr_kp 	=> s_AKSR,

			-- сигналы управления синтезатором по SPI
			p_o_spi_cs		=> s_SPI_CS,
			p_o_spi_clk 	=> s_SPI_CLK,
			p_o_spi_mosi 	=> s_SPI_MOSI,

			-- сигналы управления синтезатором по UART
			--p_io_rx 		=> s_RX,
			--p_io_tx 		=> s_TX,

			-- сигналы управления внутренними частями блока
			p_o_diap_13 	=> s_DIAP13,
			p_o_diap_24		=> s_DIAP24,
			p_o_diap_2 		=> s_DIAP2,
			p_o_diap_4 		=> s_DIAP4,
			p_i_end_diap_from_res => s_RESONATOR_SIGNAL,
			p_i_sint_power_on => s_SINT_POW_ON
		);
	

 	s_CT <= '1';
 	s_REV <= '1';
 	
 	s_Z1 <= '0';
 	s_Z2 <= '1';
 	s_MT<= '1';

 	diap: process begin
 		s_D1 <= '1';
 		s_D2 <= '1';
 --		wait for 40000 ns;
 --		s_D2 <= '0';
 		wait;
 	end process;


 --	maint_tick: process begin
 --		s_MT <= '1';
 --		wait for 10000 ns;
 --		s_MT <= '0';
 --		wait for 10000 ns;
 --	end process;

 
	clk:process begin
		s_CLK <= '1';
		wait for 1 ns;
		s_CLK <= '0';
		wait for 1 ns;
	end process;


	sint_pow_on: process begin
		s_SINT_POW_ON <= '0';
		wait for 100000 ns;
		s_SINT_POW_ON <= '1';
		wait;
	end process;

end architecture ; -- arch