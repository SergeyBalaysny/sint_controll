-- eth1.vhd

-- This file was auto-generated from altera_eth_tse_hw.tcl.  If you edit it your changes
-- will probably be lost.
-- 
-- Generated using ACDS version 17.1 590

library IEEE;
use IEEE.std_logic_1164.all;
use IEEE.numeric_std.all;

entity eth1 is
	port (
		clk           : in  std_logic                     := '0';             -- control_port_clock_connection.clk
		reset         : in  std_logic                     := '0';             --              reset_connection.reset
		reg_addr      : in  std_logic_vector(7 downto 0)  := (others => '0'); --                  control_port.address
		reg_data_out  : out std_logic_vector(31 downto 0);                    --                              .readdata
		reg_rd        : in  std_logic                     := '0';             --                              .read
		reg_data_in   : in  std_logic_vector(31 downto 0) := (others => '0'); --                              .writedata
		reg_wr        : in  std_logic                     := '0';             --                              .write
		reg_busy      : out std_logic;                                        --                              .waitrequest
		tx_clk        : in  std_logic                     := '0';             --   pcs_mac_tx_clock_connection.clk
		rx_clk        : in  std_logic                     := '0';             --   pcs_mac_rx_clock_connection.clk
		set_10        : in  std_logic                     := '0';             --         mac_status_connection.set_10
		set_1000      : in  std_logic                     := '0';             --                              .set_1000
		eth_mode      : out std_logic;                                        --                              .eth_mode
		ena_10        : out std_logic;                                        --                              .ena_10
		gm_rx_d       : in  std_logic_vector(7 downto 0)  := (others => '0'); --           mac_gmii_connection.gmii_rx_d
		gm_rx_dv      : in  std_logic                     := '0';             --                              .gmii_rx_dv
		gm_rx_err     : in  std_logic                     := '0';             --                              .gmii_rx_err
		gm_tx_d       : out std_logic_vector(7 downto 0);                     --                              .gmii_tx_d
		gm_tx_en      : out std_logic;                                        --                              .gmii_tx_en
		gm_tx_err     : out std_logic;                                        --                              .gmii_tx_err
		m_rx_d        : in  std_logic_vector(3 downto 0)  := (others => '0'); --            mac_mii_connection.mii_rx_d
		m_rx_en       : in  std_logic                     := '0';             --                              .mii_rx_dv
		m_rx_err      : in  std_logic                     := '0';             --                              .mii_rx_err
		m_tx_d        : out std_logic_vector(3 downto 0);                     --                              .mii_tx_d
		m_tx_en       : out std_logic;                                        --                              .mii_tx_en
		m_tx_err      : out std_logic;                                        --                              .mii_tx_err
		m_rx_crs      : in  std_logic                     := '0';             --                              .mii_crs
		m_rx_col      : in  std_logic                     := '0';             --                              .mii_col
		ff_rx_clk     : in  std_logic                     := '0';             --      receive_clock_connection.clk
		ff_tx_clk     : in  std_logic                     := '0';             --     transmit_clock_connection.clk
		ff_rx_data    : out std_logic_vector(31 downto 0);                    --                       receive.data
		ff_rx_eop     : out std_logic;                                        --                              .endofpacket
		rx_err        : out std_logic_vector(5 downto 0);                     --                              .error
		ff_rx_mod     : out std_logic_vector(1 downto 0);                     --                              .empty
		ff_rx_rdy     : in  std_logic                     := '0';             --                              .ready
		ff_rx_sop     : out std_logic;                                        --                              .startofpacket
		ff_rx_dval    : out std_logic;                                        --                              .valid
		ff_tx_data    : in  std_logic_vector(31 downto 0) := (others => '0'); --                      transmit.data
		ff_tx_eop     : in  std_logic                     := '0';             --                              .endofpacket
		ff_tx_err     : in  std_logic                     := '0';             --                              .error
		ff_tx_mod     : in  std_logic_vector(1 downto 0)  := (others => '0'); --                              .empty
		ff_tx_rdy     : out std_logic;                                        --                              .ready
		ff_tx_sop     : in  std_logic                     := '0';             --                              .startofpacket
		ff_tx_wren    : in  std_logic                     := '0';             --                              .valid
		magic_wakeup  : out std_logic;                                        --           mac_misc_connection.magic_wakeup
		magic_sleep_n : in  std_logic                     := '0';             --                              .magic_sleep_n
		ff_tx_crc_fwd : in  std_logic                     := '0';             --                              .ff_tx_crc_fwd
		ff_tx_septy   : out std_logic;                                        --                              .ff_tx_septy
		tx_ff_uflow   : out std_logic;                                        --                              .tx_ff_uflow
		ff_tx_a_full  : out std_logic;                                        --                              .ff_tx_a_full
		ff_tx_a_empty : out std_logic;                                        --                              .ff_tx_a_empty
		rx_err_stat   : out std_logic_vector(17 downto 0);                    --                              .rx_err_stat
		rx_frm_type   : out std_logic_vector(3 downto 0);                     --                              .rx_frm_type
		ff_rx_dsav    : out std_logic;                                        --                              .ff_rx_dsav
		ff_rx_a_full  : out std_logic;                                        --                              .ff_rx_a_full
		ff_rx_a_empty : out std_logic                                         --                              .ff_rx_a_empty
	);
end entity eth1;

architecture rtl of eth1 is
	component altera_eth_tse_mac is
		generic (
			ING_ADDR                 : integer := 0;
			ENABLE_MAC_RX_VLAN       : boolean := false;
			ENABLE_SUP_ADDR          : boolean := false;
			DEVICE_FAMILY            : string  := "ARRIAGX";
			INSERT_TA                : boolean := true;
			ING_FIFO                 : integer := 0;
			ENABLE_ECC               : boolean := false;
			CRC32DWIDTH              : integer := 0;
			ENABLE_ENA               : integer := 32;
			SYNCHRONIZER_DEPTH       : integer := 3;
			ENABLE_MAC_TX_VLAN       : boolean := false;
			RESET_LEVEL              : integer := 0;
			STAT_CNT_ENA             : boolean := false;
			CUST_VERSION             : integer := 0;
			CRC32S1L2_EXTERN         : boolean := false;
			MBIT_ONLY                : boolean := true;
			EG_ADDR                  : integer := 0;
			CORE_VERSION             : integer := 0;
			CRC32GENDELAY            : integer := 0;
			EG_FIFO                  : integer := 0;
			REDUCED_INTERFACE_ENA    : boolean := false;
			ENABLE_MAGIC_DETECT      : boolean := false;
			ENABLE_MDIO              : boolean := false;
			ENABLE_MAC_TXADDR_SET    : boolean := false;
			RAM_TYPE                 : string  := "AUTO";
			CRC32CHECK16BIT          : integer := 0;
			ENABLE_LGTH_CHECK        : boolean := true;
			ENABLE_MAC_FLOW_CTRL     : boolean := false;
			ENABLE_SHIFT16           : boolean := false;
			USE_SYNC_RESET           : boolean := false;
			REDUCED_CONTROL          : boolean := true;
			MDIO_CLK_DIV             : integer := 0;
			ENABLE_PADDING           : boolean := true;
			ENABLE_GMII_LOOPBACK     : boolean := false;
			GBIT_ONLY                : boolean := true;
			ENA_HASH                 : boolean := false;
			ENABLE_EXTENDED_STAT_REG : boolean := false;
			ENABLE_HD_LOGIC          : boolean := false
		);
		port (
			clk             : in  std_logic                     := 'X';             -- clk
			reset           : in  std_logic                     := 'X';             -- reset
			reg_addr        : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- address
			reg_data_out    : out std_logic_vector(31 downto 0);                    -- readdata
			reg_rd          : in  std_logic                     := 'X';             -- read
			reg_data_in     : in  std_logic_vector(31 downto 0) := (others => 'X'); -- writedata
			reg_wr          : in  std_logic                     := 'X';             -- write
			reg_busy        : out std_logic;                                        -- waitrequest
			ff_tx_clk       : in  std_logic                     := 'X';             -- clk
			ff_rx_clk       : in  std_logic                     := 'X';             -- clk
			ff_rx_data      : out std_logic_vector(31 downto 0);                    -- data
			ff_rx_eop       : out std_logic;                                        -- endofpacket
			rx_err          : out std_logic_vector(5 downto 0);                     -- error
			ff_rx_mod       : out std_logic_vector(1 downto 0);                     -- empty
			ff_rx_rdy       : in  std_logic                     := 'X';             -- ready
			ff_rx_sop       : out std_logic;                                        -- startofpacket
			ff_rx_dval      : out std_logic;                                        -- valid
			ff_tx_data      : in  std_logic_vector(31 downto 0) := (others => 'X'); -- data
			ff_tx_eop       : in  std_logic                     := 'X';             -- endofpacket
			ff_tx_err       : in  std_logic                     := 'X';             -- error
			ff_tx_mod       : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- empty
			ff_tx_rdy       : out std_logic;                                        -- ready
			ff_tx_sop       : in  std_logic                     := 'X';             -- startofpacket
			ff_tx_wren      : in  std_logic                     := 'X';             -- valid
			magic_wakeup    : out std_logic;                                        -- export
			magic_sleep_n   : in  std_logic                     := 'X';             -- export
			ff_tx_crc_fwd   : in  std_logic                     := 'X';             -- export
			ff_tx_septy     : out std_logic;                                        -- export
			tx_ff_uflow     : out std_logic;                                        -- export
			ff_tx_a_full    : out std_logic;                                        -- export
			ff_tx_a_empty   : out std_logic;                                        -- export
			rx_err_stat     : out std_logic_vector(17 downto 0);                    -- export
			rx_frm_type     : out std_logic_vector(3 downto 0);                     -- export
			ff_rx_dsav      : out std_logic;                                        -- export
			ff_rx_a_full    : out std_logic;                                        -- export
			ff_rx_a_empty   : out std_logic;                                        -- export
			gm_rx_d         : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- gmii_rx_d
			gm_rx_dv        : in  std_logic                     := 'X';             -- gmii_rx_dv
			gm_rx_err       : in  std_logic                     := 'X';             -- gmii_rx_err
			gm_tx_d         : out std_logic_vector(7 downto 0);                     -- gmii_tx_d
			gm_tx_en        : out std_logic;                                        -- gmii_tx_en
			gm_tx_err       : out std_logic;                                        -- gmii_tx_err
			m_rx_d          : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- mii_rx_d
			m_rx_en         : in  std_logic                     := 'X';             -- mii_rx_dv
			m_rx_err        : in  std_logic                     := 'X';             -- mii_rx_err
			m_tx_d          : out std_logic_vector(3 downto 0);                     -- mii_tx_d
			m_tx_en         : out std_logic;                                        -- mii_tx_en
			m_tx_err        : out std_logic;                                        -- mii_tx_err
			m_rx_crs        : in  std_logic                     := 'X';             -- mii_crs
			m_rx_col        : in  std_logic                     := 'X';             -- mii_col
			set_10          : in  std_logic                     := 'X';             -- set_10
			set_1000        : in  std_logic                     := 'X';             -- set_1000
			eth_mode        : out std_logic;                                        -- eth_mode
			ena_10          : out std_logic;                                        -- ena_10
			tx_clk          : in  std_logic                     := 'X';             -- clk
			rx_clk          : in  std_logic                     := 'X';             -- clk
			rx_clkena       : in  std_logic                     := 'X';             -- rx_clkena
			tx_clkena       : in  std_logic                     := 'X';             -- tx_clkena
			xon_gen         : in  std_logic                     := 'X';             -- export
			xoff_gen        : in  std_logic                     := 'X';             -- export
			mac_eccstatus   : out std_logic_vector(1 downto 0);                     -- mac_eccstatus
			mdc             : out std_logic;                                        -- mdc
			mdio_in         : in  std_logic                     := 'X';             -- mdio_in
			mdio_out        : out std_logic;                                        -- mdio_out
			mdio_oen        : out std_logic;                                        -- mdio_oen
			rgmii_out1_aclr : out std_logic;                                        -- export
			rgmii_out1_din  : out std_logic_vector(1 downto 0);                     -- export
			rgmii_in1_dout  : in  std_logic_vector(1 downto 0)  := (others => 'X'); -- export
			rgmii_in1_ck    : out std_logic;                                        -- export
			rgmii_out4_din  : out std_logic_vector(7 downto 0);                     -- export
			rgmii_out4_ck   : out std_logic;                                        -- export
			rgmii_in1_pad   : out std_logic;                                        -- export
			rgmii_out4_aclr : out std_logic;                                        -- export
			rgmii_out1_pad  : in  std_logic                     := 'X';             -- export
			rgmii_out1_ck   : out std_logic;                                        -- export
			rgmii_in4_dout  : in  std_logic_vector(7 downto 0)  := (others => 'X'); -- export
			rgmii_in4_pad   : out std_logic_vector(3 downto 0);                     -- export
			rgmii_out4_pad  : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- export
			rgmii_in4_ck    : out std_logic;                                        -- export
			rgmii_in        : in  std_logic_vector(3 downto 0)  := (others => 'X'); -- rgmii_in
			rgmii_out       : out std_logic_vector(3 downto 0);                     -- rgmii_out
			rx_control      : in  std_logic                     := 'X';             -- rx_control
			tx_control      : out std_logic                                         -- tx_control
		);
	end component altera_eth_tse_mac;

begin

	i_tse_mac : component altera_eth_tse_mac
		generic map (
			ING_ADDR                 => 11,
			ENABLE_MAC_RX_VLAN       => false,
			ENABLE_SUP_ADDR          => false,
			DEVICE_FAMILY            => "CYCLONEIVE",
			INSERT_TA                => false,
			ING_FIFO                 => 2048,
			ENABLE_ECC               => false,
			CRC32DWIDTH              => 8,
			ENABLE_ENA               => 32,
			SYNCHRONIZER_DEPTH       => 3,
			ENABLE_MAC_TX_VLAN       => false,
			RESET_LEVEL              => 1,
			STAT_CNT_ENA             => true,
			CUST_VERSION             => 0,
			CRC32S1L2_EXTERN         => false,
			MBIT_ONLY                => true,
			EG_ADDR                  => 11,
			CORE_VERSION             => 4353,
			CRC32GENDELAY            => 6,
			EG_FIFO                  => 2048,
			REDUCED_INTERFACE_ENA    => false,
			ENABLE_MAGIC_DETECT      => true,
			ENABLE_MDIO              => false,
			ENABLE_MAC_TXADDR_SET    => true,
			RAM_TYPE                 => "AUTO",
			CRC32CHECK16BIT          => 0,
			ENABLE_LGTH_CHECK        => true,
			ENABLE_MAC_FLOW_CTRL     => false,
			ENABLE_SHIFT16           => false,
			USE_SYNC_RESET           => true,
			REDUCED_CONTROL          => false,
			MDIO_CLK_DIV             => 40,
			ENABLE_PADDING           => true,
			ENABLE_GMII_LOOPBACK     => false,
			GBIT_ONLY                => true,
			ENA_HASH                 => false,
			ENABLE_EXTENDED_STAT_REG => false,
			ENABLE_HD_LOGIC          => true
		)
		port map (
			clk             => clk,           -- control_port_clock_connection.clk
			reset           => reset,         --              reset_connection.reset
			reg_addr        => reg_addr,      --                  control_port.address
			reg_data_out    => reg_data_out,  --                              .readdata
			reg_rd          => reg_rd,        --                              .read
			reg_data_in     => reg_data_in,   --                              .writedata
			reg_wr          => reg_wr,        --                              .write
			reg_busy        => reg_busy,      --                              .waitrequest
			ff_tx_clk       => ff_tx_clk,     --     transmit_clock_connection.clk
			ff_rx_clk       => ff_rx_clk,     --      receive_clock_connection.clk
			ff_rx_data      => ff_rx_data,    --                       receive.data
			ff_rx_eop       => ff_rx_eop,     --                              .endofpacket
			rx_err          => rx_err,        --                              .error
			ff_rx_mod       => ff_rx_mod,     --                              .empty
			ff_rx_rdy       => ff_rx_rdy,     --                              .ready
			ff_rx_sop       => ff_rx_sop,     --                              .startofpacket
			ff_rx_dval      => ff_rx_dval,    --                              .valid
			ff_tx_data      => ff_tx_data,    --                      transmit.data
			ff_tx_eop       => ff_tx_eop,     --                              .endofpacket
			ff_tx_err       => ff_tx_err,     --                              .error
			ff_tx_mod       => ff_tx_mod,     --                              .empty
			ff_tx_rdy       => ff_tx_rdy,     --                              .ready
			ff_tx_sop       => ff_tx_sop,     --                              .startofpacket
			ff_tx_wren      => ff_tx_wren,    --                              .valid
			magic_wakeup    => magic_wakeup,  --           mac_misc_connection.export
			magic_sleep_n   => magic_sleep_n, --                              .export
			ff_tx_crc_fwd   => ff_tx_crc_fwd, --                              .export
			ff_tx_septy     => ff_tx_septy,   --                              .export
			tx_ff_uflow     => tx_ff_uflow,   --                              .export
			ff_tx_a_full    => ff_tx_a_full,  --                              .export
			ff_tx_a_empty   => ff_tx_a_empty, --                              .export
			rx_err_stat     => rx_err_stat,   --                              .export
			rx_frm_type     => rx_frm_type,   --                              .export
			ff_rx_dsav      => ff_rx_dsav,    --                              .export
			ff_rx_a_full    => ff_rx_a_full,  --                              .export
			ff_rx_a_empty   => ff_rx_a_empty, --                              .export
			gm_rx_d         => gm_rx_d,       --           mac_gmii_connection.gmii_rx_d
			gm_rx_dv        => gm_rx_dv,      --                              .gmii_rx_dv
			gm_rx_err       => gm_rx_err,     --                              .gmii_rx_err
			gm_tx_d         => gm_tx_d,       --                              .gmii_tx_d
			gm_tx_en        => gm_tx_en,      --                              .gmii_tx_en
			gm_tx_err       => gm_tx_err,     --                              .gmii_tx_err
			m_rx_d          => m_rx_d,        --            mac_mii_connection.mii_rx_d
			m_rx_en         => m_rx_en,       --                              .mii_rx_dv
			m_rx_err        => m_rx_err,      --                              .mii_rx_err
			m_tx_d          => m_tx_d,        --                              .mii_tx_d
			m_tx_en         => m_tx_en,       --                              .mii_tx_en
			m_tx_err        => m_tx_err,      --                              .mii_tx_err
			m_rx_crs        => m_rx_crs,      --                              .mii_crs
			m_rx_col        => m_rx_col,      --                              .mii_col
			set_10          => set_10,        --         mac_status_connection.set_10
			set_1000        => set_1000,      --                              .set_1000
			eth_mode        => eth_mode,      --                              .eth_mode
			ena_10          => ena_10,        --                              .ena_10
			tx_clk          => tx_clk,        --   pcs_mac_tx_clock_connection.clk
			rx_clk          => rx_clk,        --   pcs_mac_rx_clock_connection.clk
			rx_clkena       => '1',           --                   (terminated)
			tx_clkena       => '1',           --                   (terminated)
			xon_gen         => '0',           --                   (terminated)
			xoff_gen        => '0',           --                   (terminated)
			mac_eccstatus   => open,          --                   (terminated)
			mdc             => open,          --                   (terminated)
			mdio_in         => '0',           --                   (terminated)
			mdio_out        => open,          --                   (terminated)
			mdio_oen        => open,          --                   (terminated)
			rgmii_out1_aclr => open,          --                   (terminated)
			rgmii_out1_din  => open,          --                   (terminated)
			rgmii_in1_dout  => "00",          --                   (terminated)
			rgmii_in1_ck    => open,          --                   (terminated)
			rgmii_out4_din  => open,          --                   (terminated)
			rgmii_out4_ck   => open,          --                   (terminated)
			rgmii_in1_pad   => open,          --                   (terminated)
			rgmii_out4_aclr => open,          --                   (terminated)
			rgmii_out1_pad  => '0',           --                   (terminated)
			rgmii_out1_ck   => open,          --                   (terminated)
			rgmii_in4_dout  => "00000000",    --                   (terminated)
			rgmii_in4_pad   => open,          --                   (terminated)
			rgmii_out4_pad  => "0000",        --                   (terminated)
			rgmii_in4_ck    => open,          --                   (terminated)
			rgmii_in        => "0000",        --                   (terminated)
			rgmii_out       => open,          --                   (terminated)
			rx_control      => '0',           --                   (terminated)
			tx_control      => open           --                   (terminated)
		);

end architecture rtl; -- of eth1
