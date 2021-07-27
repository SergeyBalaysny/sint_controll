LIBRARY ieee;
USE ieee.std_logic_1164.all;
use IEEE.STD_LOGIC_ARITH.ALL;
use IEEE.STD_LOGIC_UNSIGNED.ALL;


entity sint_control_tb is
end entity ; -- sint_control_tb


architecture sint_control_tb_behav of sint_control_tb is

	
	component sint_control is
  	port (	
  			p_i_clk:	in std_logic;
			p_i_rx:		inout std_logic;
			p_o_tx:		inout std_logic;

			p_i_len:	in integer;
			p_i_data: 	in std_logic_vector(143 downto 0);
			p_i_ena: 	in std_logic

		);
	end component ; -- dzu_read


	SIGNAL s_CLK, s_RX, s_TX, s_ENA: std_logic;
	SIGNAL s_LEN: integer;
	SIGNAL s_DATA: std_logic_vector(143 downto 0) := (others => '0');




begin
	
	sint_control_module: sint_control port map ( 	p_i_clk => 	s_CLK,	
													p_i_rx => 	s_RX,
													p_o_tx => 	s_TX,
													p_i_len => 	s_LEN,
													p_i_data => s_DATA,
													p_i_ena => 	s_ENA
		);



	process begin
		s_CLK <= '1';
		wait for 1 ns;
		s_CLK <= '0';
		wait for 1 ns;
	end process;


	process begin
		s_LEN <= 4;
		s_DATA(31 downto 0) <= X"1234560A";
		s_ENA <= '0';
		wait for 30 ns;
		s_ENA <= '1';
		wait for 10 ns;
		s_ENA <= '0';
		wait;
	end process;



end architecture ; -- arch