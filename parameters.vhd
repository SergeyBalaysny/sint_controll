library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;
use IEEE.NUMERIC_STD.ALL;

package parameters is

	constant c_LEN: natural := 127;
	constant c_FREQ_LEN : natural := 47; 		-- длинна кода частоты в битах

	constant  s_SPI_SPEED : natural := 20_00_000; --10_000_000; -- spi speed 

-- команда сброса синтезатора
	constant c_SPI_COMMAND_RES : std_logic_vector(c_LEN downto 0) := X"3E000000000000000000000000000000";
	constant c_SPI_COMMAND_RES_LEN : integer := 8;
-- команда сохренения состояния синтезатора
	constant c_SPI_COMMAND_SAV : std_logic_vector(c_LEN downto 0) := X"3F000000000000000000000000000000";
	constant c_SPI_COMMAND_SAV_LEN : integer := 8;
-- команда включения ВЧ выхода синтезатора
	constant c_SPI_COMMAND_ON : std_logic_vector(c_LEN downto 0) := X"04000000000000000000000000000000";
	constant c_SPI_COMMAND_ON_LEN : integer := 8;
-- команда выключения ВЧ выхода синтезатора
	constant c_SPI_COMMAND_OFF : std_logic_vector(c_LEN downto 0) := X"05000000000000000000000000000000";
	constant c_SPI_COMMAND_OFF_LEN : integer := 8;
-- команда установки нового значения частоты синтезатора
	constant c_SPI_COMMAND_FREQ : std_logic_vector(c_LEN downto 0):= X"01042F055DB000000000000000000000";
	constant c_SPI_COMMAND_FREQ_LEN : integer := 56;                --  11111111111111
-- команда установки нового значения мощности синтезатора
	constant c_SPI_COMMAND_POW : std_logic_vector(c_LEN downto 0) := X"02000A00000000000000000000000000";
	constant c_SPI_COMMAND_POW_LEN : integer := 24;

------------------------------------------------------------------
-- начальные, конечные и контрольные значения частот диапазонов
-- а также шаг изменения частоты, мГц (48 разрядные числа)
------------------------------------------------------------------
--
-- приращения частот при стандартном режиме работы
	constant c_BASE_STEP_FREQ_DIAP_1_2: std_logic_vector( 47 downto 0 ) :=  X"0000003B9ACA";--X"00003B9ACA00"; 	   -- 1 MHz
	constant c_BASE_STEP_FREQ_DIAP_3_4: std_logic_vector( 47 downto 0 ) :=  X"000077359400";--X"000077359400"; 	   -- 2 MHz	

-- приращения частот при работе в режиме самопрогон
	constant c_CONTR_STEP_FREQ_DIAP_1_2: std_logic_vector( 47 downto 0 ) :=  X"000773594000"; 	   -- 32 MHz
	constant c_CONTR_STEP_FREQ_DIAP_3_4: std_logic_vector( 47 downto 0 ) :=  X"000EE6B28000"; 	   -- 64 MHz	


-- 1 поддиапазон
	constant c_BEGIN_FREQ_DIAP_1: std_logic_vector( 47 downto 0 ) := X"06522C47FC00";		-- 6950 MHz
	constant c_END_FREQ_DIAP_1: std_logic_vector( 47 downto 0 ) :=   X"07F544A44C00"; 		-- 8750 MHz

-- 2 поддиапазон 
	constant c_BEGIN_FREQ_DIAP_2: std_logic_vector( 47 downto 0 ) := X"04ADE9E5BA00";		-- 5145 MHz
	constant c_END_FREQ_DIAP_2: std_logic_vector( 47 downto 0 ) :=   X"067518FA5800"; 		-- 7100 MHz

-- 3 поддипазон
	constant c_BEGIN_FREQ_DIAP_3: std_logic_vector( 47 downto 0 ) := X"06522C47FC00";		-- 6950 MHz
	constant c_END_FREQ_DIAP_3: std_logic_vector( 47 downto 0 ) :=   X"098CB8C52800"; 		-- 10500 MHz

-- 4 поддиапазон	
	constant c_BEGIN_FREQ_DIAP_4: std_logic_vector( 47 downto 0 ) := X"0428093A0400";		-- 4570 MHz
	constant c_END_FREQ_DIAP_4: std_logic_vector( 47 downto 0 ) :=   X"067518FA5800"; 		-- 7100 MHz


-- допуски на чатоты срабатывания контрольных резонаторов, МГц
	
-- 1, 3 поддиапазоны
	constant c_FREQ_LIMIT_DIAP_1_3: std_logic_vector( 47 downto 0 ) := X"000342770C00";		-- 14 MHz
	constant c_FREQ_LIMIT_DIAP_2_4: std_logic_vector( 47 downto 0 ) := X"0002540BE400";		-- 10 MHz

--  центральные частоты срабатывания контрольных резонаторов
	constant c_BEGIN_FREQ_RES_1_3: std_logic_vector( 47 downto 0 ) := X"065DD0837000";		-- 7000 MHz
	constant c_BEGIN_FREQ_RES_2: std_logic_vector( 47 downto 0 ) :=   X"04B4E6096600";		-- 5175 MHz
	constant c_BEGIN_FREQ_RES_4: std_logic_vector( 47 downto 0 ) :=   X"042F055DB000";		-- 4600 MHz



-------------------------------------------------------------------------------------------------------------
--               передача данных по UART, с использованием языка SCPI
------------------------------------------------------------------------------------------------------------
-- команда установки нового значения частоты в МГц
	constant c_UATR_SET_NEW_FREQ_LEN : integer := 152;
	constant c_UATR_SET_NEW_FREQ: std_logic_vector (c_UATR_SET_NEW_FREQ_LEN - 1 downto 0) := X"465245513a4357203030303030204d485a0d0a"; --FREQ:CW 00000 MHZ\r\n
	


-- команда включения синтезатора и ее длительность
	constant c_UART_ON : std_logic_vector(c_UATR_SET_NEW_FREQ_LEN - 1 downto 0) := X"4f555450204f4e0d0a00000000000000000000"; -- OUTP ON\r\n
	constant c_UART_ON_LEN :  integer := 72;		   

-- команда выключения синтезатора и ее длительность
	constant c_UART_OFF : std_logic_vector(c_UATR_SET_NEW_FREQ_LEN - 1 downto 0) := X"4f555450204f46460d0a000000000000000000"; -- OUTP OFF\r\n
	constant c_UART_OFF_LEN :  integer := 80; 			


-- номер старшего бита кода частоты  в команде установки нового значения
	constant c_UATR_SET_NEW_FREQ_BEG_FREG : integer := 87;
-- длинна поля кода частоты
	constant c_UART_FREQ_CODE_LEN : integer := 39; 


-- приращения частот при стандартном режиме работы
	constant c_UART_BASE_STEP_FREQ_DIAP_1_2 : integer := 1; -- MHz
	constant c_UART_BASE_STEP_FREQ_DIAP_3_4 : integer := 2; -- MHz	

-- приращения частот при работе в режиме самопрогон
	constant c_UART_CONTR_STEP_FREQ_DIAP_1_2 : integer := 32; -- MHz
	constant c_UART_CONTR_STEP_FREQ_DIAP_3_4 : integer := 64; -- MHz	

-- 1 поддиапазон
	constant c_UART_BEGIN_FREQ_DIAP_1 : integer := 6950; -- MHz
	constant c_UART_END_FREQ_DIAP_1 : integer := 8750; -- MHz

-- 2 поддиапазон 
	constant c_UART_BEGIN_FREQ_DIAP_2 : integer := 5145; -- MHz
	constant c_UART_END_FREQ_DIAP_2 : integer := 7100; -- MHz

-- 3 поддипазон
	constant c_UART_BEGIN_FREQ_DIAP_3 : integer := 6950;-- MHz
	constant c_UART_END_FREQ_DIAP_3 : integer := 10500; -- MHz

-- 4 поддиапазон	
	constant c_UART_BEGIN_FREQ_DIAP_4 : integer := 4570; -- MHz
	constant c_UART_END_FREQ_DIAP_4 : integer := 7100; -- MHz

-- допуски на чатоты срабатывания контрольных резонаторов, МГц
	
-- 1, 3 поддиапазоны
	constant c_UART_FREQ_LIMIT_DIAP_1_3 : integer := 14; -- MHz
	constant c_UART_FREQ_LIMIT_DIAP_2_4 : integer := 10; -- MHz

--  центральные частоты срабатывания контрольных резонаторов
	constant c_UART_BEGIN_FREQ_RES_1_3 : integer := 7000; -- MHz
	constant c_UART_BEGIN_FREQ_RES_2 : integer := 5175; -- MHz
	constant c_UART_BEGIN_FREQ_RES_4 : integer := 4600; -- MHz

end package ; -- parameters_p 
