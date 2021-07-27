-- Пакет для конвертации целого числа в вид ASCII строку записанную в виде std_logic_vector
-- параметры процедуры pStrToLogVect 
-- sInpInt - входное число типа integer
-- sVect   - перекодированное числов в формат std_logic_vector, причем каждые 8 бит соответствут очередному разряду числа
-- числа кодировка чисел соответсвует таблице ASCII

library IEEE;
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.NUMERIC_STD.ALL;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;

package my_convert_p is
	
	type t_arr is array (0 to 9) of std_logic_vector(7 downto 0);
	constant  cChrArr : t_arr := (X"30", X"31", X"32", X"33", X"34", X"35", X"36", X"37", X"38", X"39");

	function fIntToLogVect(sInpInt: 	in integer) return  std_logic_vector;
	
end package ; -- my_convert_p 

package body my_convert_p is

	function fIntToLogVect(sInpInt: 	in integer) return std_logic_vector is

		variable mod5, mod4, mod3, mod2, mod1: integer;
		variable vData: std_logic_vector(39 downto 0) := (others => '0');	-- выходной массив перекодированных данных
	begin

		mod5 := sInpInt / 10000;
		mod4 := (sInpInt - (mod5*10000)) / 1000;
		mod3 := (sInpInt - (mod5*10000) - (mod4 * 1000)) / 100;
		mod2 := (sInpInt - (mod5*10000) - (mod4 * 1000) - (mod3 * 100)) / 10;
		mod1 := sInpInt - (mod5*10000) - (mod4 * 1000) - (mod3 * 100) - (mod2 * 10);

		vData := cChrArr(mod5) & cChrArr(mod4) & cChrArr(mod3) & cChrArr(mod2) & cChrArr(mod1);

		return vData;
	end;

end my_convert_p;