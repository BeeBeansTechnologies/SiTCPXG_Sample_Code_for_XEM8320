//----------------------------------------------------------------------//
//
//	Copyright (c) 2020 BeeBeans Technologies All rights reserved
//
//		System		: XEM8320
//
//		Module		: XEM8320_SiTCP_XG_EEPROM
//
//		Description	: SiTCPXG(10GbE SiTCP) test bench on XEM8320
//
//		file		: XEM8320_SiTCP_EEPROM.v
//
//		Note	: 
//
//		history	:
//			20260407	Ver 1.0		---------	Created by BBT for Release test
//
//----------------------------------------------------------------------//
 
module
	XEM8320_SiTCP_XG_EEPROM(
	// System
		input	wire			SYSCLK_100MP_IN		,	// From 100MHz Oscillator module
		input	wire			SYSCLK_100MN_IN		,	// From 100MHz Oscillator module
		input	wire			SFPXG_MGT_CLK0_P	,	
		input	wire			SFPXG_MGT_CLK0_N	,	
	// SFP+
		input	wire			SFP1_RX_N		,	
		input	wire			SFP1_RX_P		,	
		output	wire			SFP1_TX_N		,	
		output	wire			SFP1_TX_P		,	
		output	wire			SFP1_TDIS		,	
		output	wire	[ 1:0]	SFP1_RATE_SELECT,
		
	//connect EEPROM
		output	wire			EEPROM_CS		,
		output	wire			EEPROM_SK		,
		output	wire			EEPROM_DI		,
		input	wire			EEPROM_DO		,
		
	// SW, LED
		input	wire			GPIO_SW5_EXP	,	//	in	: Push Switch SW5 on daughter board "XEM8320_EXP_BOARD"
		input					GPIO_SW4_EXP	,	//	in	: Push Switch SW4 on daughter board "XEM8320_EXP_BOARD" (KC705_Source:"GPIO_SW_S")
		input	wire			GPIO_SW3_EXP	,	//	in	: Push Switch SW3 on daughter board "XEM8320_EXP_BOARD"
		input	wire			GPIO_SW2_EXP	,	//	in	: System reset, Push Switch SW2 on daughter board "XEM8320_EXP_BOARD" (KC705_Source:"CPU_RESET")
		input	wire 	[7:0]	GPIO_DIP_SW		,	//	in	: SW[7:0]				GPIO_DIP_SW[7]	SW1 switch No.8 "DIP7" on daughter board "XEM8320_EXP_BOARD"
													//					[Not Use]	GPIO_DIP_SW[6]	SW1 switch No.7 "DIP6" on daughter board "XEM8320_EXP_BOARD"
													//					[Not Use]	GPIO_DIP_SW[5]	SW1 switch No.6 "DIP5" on daughter board "XEM8320_EXP_BOARD"
													//					[Not Use]	GPIO_DIP_SW[4]	SW1 switch No.5 "DIP4" on daughter board "XEM8320_EXP_BOARD"
													//								GPIO_DIP_SW[3]	SW1 switch No.4 "DIP3" on daughter board "XEM8320_EXP_BOARD"
													//					[Not Use]	GPIO_DIP_SW[2]	SW1 switch No.3 "DIP2" on daughter board "XEM8320_EXP_BOARD"
													//					[Not Use]	GPIO_DIP_SW[1]	SW1 switch No.2 "DIP1" on daughter board "XEM8320_EXP_BOARD"
													//								GPIO_DIP_SW[0]	SW1 switch No.1 "DIP0" on daughter board "XEM8320_EXP_BOARD"
		output	[9:0]			GPIO_LED			//	out	: LED[9:0]	GPIO_LED[9]		D6 on mother board "XEM8320"
													//					GPIO_LED[8]		D5 on mother board "XEM8320"
													//					GPIO_LED[7]		D4 on mother board "XEM8320"
													//					GPIO_LED[6]		D3 on mother board "XEM8320"
													//					GPIO_LED[5]		D2 on mother board "XEM8320"
													//					GPIO_LED[4]		D1 on mother board "XEM8320"
													//					GPIO_LED[3]		D4 on daughter board "XEM8320_EXP_BOARD"
													//					GPIO_LED[2]		D3 on daughter board "XEM8320_EXP_BOARD"
													//					GPIO_LED[1]		D2 on daughter board "XEM8320_EXP_BOARD"
													//					GPIO_LED[0]		D1 on daughter board "XEM8320_EXP_BOARD"

	);

	wire	[31:0]	REG_FPGA_VER	;
	wire	[31:0]	REG_FPGA_ID		;

	wire			CLK156M			;

	wire			SiTCPXG_OPEN_REQ	;
	wire			SiTCPXG_ESTABLISHED	;
	wire			SiTCPXG_CLOSE_REQ	;
	wire			SiTCPXG_CLOSE_ACK	;
	wire			SiTCPXG_TX_AFULL	;
	wire	[63:0]	SiTCPXG_TX_D		;
	wire	[3:0]	SiTCPXG_TX_B		;
	wire	[15:0]	SiTCPXG_RX_SIZE		;
	wire			SiTCPXG_RX_CLR_ENB	;
	wire			SiTCPXG_RX_CLR_REQ	;
	wire	[15:0]	SiTCPXG_RX_RADR		;
	wire 	[15:0]	SiTCPXG_RX_WADR		;
	wire	[ 7:0]	SiTCPXG_RX_WENB		;
	wire	[63:0]	SiTCPXG_RX_WDAT		;

	reg		[29:0]	INICNT			;
	reg				SYS_RSTn		;

	wire	[63:0]	xgmii_rxd		;
	wire	[7:0]	xgmii_rxc		;
	wire	[7:0]	xgmii_txc		;
	wire	[63:0]	xgmii_txd		;

	wire			SiTCP_RESET		;
	wire	[31:0]	RBCP_ADDR		;
	wire			RBCP_WE			;
	wire	[7:0]	RBCP_WD			;
	wire			RBCP_RE			;
	wire			RBCP_ACK		;
	wire	[7:0]	RBCP_RD			;

	wire			RBCP_LOOPBACK	;
	wire			RBCP_SEL_SEQ	;
	wire			RBCP_DATA_GEN	;
	wire	[ 7:0]	RBCP_TX_RATE	;
	wire	[23:0]	RBCP_BLK_SIZE	;
	wire	[31:0]	RBCP_SEQ_PTN	;
	wire	[63:0]	RBCP_NUM_OF_DAT	;

	wire			CLK_200M		;
	wire			LOCKED			;

	reg 	[25:0]	tgbeCnt			;
	reg		[23:0]	tx_count		;
	reg		[ 2:0]	rx_high			;
	reg		[ 2:0]	rx_low			;
	reg		[ 3:0]	rx_up			;
	reg		[23:0]	rx_count		;
	
	//Switch check
	reg		[3:0] 	EXP_LED			;
	
    assign  REG_FPGA_VER[31:0]      = 32'h2511_1910;    // Build date
    assign  REG_FPGA_ID[31:0]       = 32'h0000_0000;    // Lib ID
    
    wire FD_disable;
    assign FD_disable = GPIO_DIP_SW[3];
    
    wire FD_enable;
    assign FD_enable = !GPIO_DIP_SW[3];
    
    wire INS_ERROR;
    assign INS_ERROR = GPIO_SW4_EXP & !GPIO_DIP_SW[7];
    
	clk_wiz_0 clk_wiz_0
	(
		// Clock out ports
		.clk_out1(CLK_200M),     // output clk_out1
		// Status and control signals
		.locked(LOCKED),       // output locked
	   // Clock in ports
		.clk_in1_p(SYSCLK_100MP_IN),    // input clk_in1_p
		.clk_in1_n(SYSCLK_100MN_IN)    // input clk_in1_n
	);

	always @(posedge CLK_200M) begin
		if (GPIO_DIP_SW[7]) begin
			EXP_LED[3:0]	<=	GPIO_DIP_SW[6] ? 	3'd7 :
								GPIO_DIP_SW[5] ? 	3'd6 :
								GPIO_DIP_SW[4] ? 	3'd5 :
								GPIO_DIP_SW[3] ? 	3'd4 :
								GPIO_DIP_SW[2] ? 	3'd3 :
								GPIO_DIP_SW[1] ? 	3'd2 :
								GPIO_DIP_SW[0] ? 	3'd1 :
													3'd0;
		end else begin 
			EXP_LED[0]		<=	GPIO_SW2_EXP;
			EXP_LED[1]		<=	GPIO_SW3_EXP;
			EXP_LED[2]		<=	GPIO_SW4_EXP;
			EXP_LED[3]		<=	GPIO_SW5_EXP;
		end 
	end
	
	always@(posedge CLK_200M or negedge LOCKED)begin
		if ((GPIO_SW2_EXP&& (!GPIO_DIP_SW[7])) || LOCKED == 1'b0 ) begin
			INICNT[29:0]	<=	30'd0;
			SYS_RSTn		<=   1'b0;
		end else begin
			INICNT[29:0]	<=	INICNT[29]? INICNT[29:0]:	(INICNT[29:0] + 30'd1);
			SYS_RSTn		<=	INICNT[29];
		end
	end
	

//------------------------------------------------------------------------------
//	SiTCP-XG
//------------------------------------------------------------------------------
	WRAP_SiTCPXG_XCAUP_128K	#(
		.RxBufferSize				("LongLong"					)	// "Byte":8bit width ,"Word":16bit width ,"LongWord":32bit width , "LongLong":64bit width
	)
	WRAP_SiTCPXG_XCAUP_128K	(
		.REG_FPGA_VER				(REG_FPGA_VER[31:0] 		),	// in	: User logic Version(For example, the synthesized date)
		.REG_FPGA_ID				(REG_FPGA_ID[31:0]  		),	// in	: User logic ID (We recommend using the lower 4 bytes of the MAC address.)
		//		==== System I/F ====
		.FORCE_DEFAULTn				(FD_disable					),	// in	: Force to set default values
		.XGMII_CLOCK				(CLK156M					),	// in	: XGMII Clock 156.25MHz
		.RSTs						(~SYS_RSTn					),	// in	: System reset (Sync.)
		//		==== XGMII I/F ====
		.XGMII_RXC					(xgmii_rxc[7:0]				),	// in	: Rx control[7:0]
		.XGMII_RXD					(xgmii_rxd[63:0]			),	// in	: Rx data[63:0]
		.XGMII_TXC					(xgmii_txc[7:0]				),	// out  : Control bits[7:0]
		.XGMII_TXD					(xgmii_txd[63:0]			), 	// out  : Data[63:0]
		//		==== 93C46 I/F ====
		.EEPROM_CS					(EEPROM_CS					),	// out	: Chip select
		.EEPROM_SK					(EEPROM_SK					),	// out	: Serial data clock
		.EEPROM_DI					(EEPROM_DI					),	// out	: Serial write data
		.EEPROM_DO					(EEPROM_DO					),	// in	: Serial read data
		//		==== User I/F ====
		.SiTCP_RESET_OUT			(SiTCP_RESET				),	// out	: System reset for user's module
		//			--- RBCP ---
		.RBCP_ACT					(							),	// out	: Indicates that bus access is active.
		.RBCP_ADDR					(RBCP_ADDR[31:0]			),	// out	: Address[31:0]
		.RBCP_WE					(RBCP_WE					),	// out	: Write enable
		.RBCP_WD					(RBCP_WD[7:0]				),	// out	: Data[7:0]
		.RBCP_RE					(RBCP_RE					),	// out	: Read enable
		.RBCP_ACK					(RBCP_ACK					),	// in	: Access acknowledge
		.RBCP_RD					(RBCP_RD[7:0]				),	// in	: Read data[7:0]
		//			--- TCP ---
		.USER_SESSION_OPEN_REQ		(SiTCPXG_OPEN_REQ			),	// in	: Request for opening the new session
		.USER_SESSION_ESTABLISHED	(SiTCPXG_ESTABLISHED		),	// out	: Establish of a session
		.USER_SESSION_CLOSE_REQ		(SiTCPXG_CLOSE_REQ			),	// out	: Request for closing session.
		.USER_SESSION_CLOSE_ACK		(SiTCPXG_CLOSE_ACK			),	// in	: Acknowledge for USER_SESSION_CLOSE_REQ.
		.USER_TX_D					(SiTCPXG_TX_D[63:0]			),	// in	: Write data
		.USER_TX_B					(SiTCPXG_TX_B[3:0]			),	// in	: Byte length of USER_TX_DATA(Set to 0 if not written)
		.USER_TX_AFULL				(SiTCPXG_TX_AFULL			),	// out	: Request to stop TX
		.USER_RX_SIZE				(SiTCPXG_RX_SIZE[15:0]		),	// in	: Receive buffer size(byte) caution:Set a value of 4000 or more and (memory size-16) or less
		.USER_RX_CLR_ENB			(SiTCPXG_RX_CLR_ENB			),	// out	: Receive buffer Clear Enable
		.USER_RX_CLR_REQ			(SiTCPXG_RX_CLR_REQ			),	// in	: Receive buffer Clear Request
		.USER_RX_RADR				(SiTCPXG_RX_RADR[15:0]		),	// in	: Receive buffer read address in bytes (unused upper bits are set to 0)
		.USER_RX_WADR				(SiTCPXG_RX_WADR[15:0]		),	// out	: Receive buffer write address in bytes (lower 3 bits are not connected to memory)
		.USER_RX_WENB				(SiTCPXG_RX_WENB[ 7:0]		),	// out	: Receive buffer byte write enable (big endian)
		.USER_RX_WDAT				(SiTCPXG_RX_WDAT[63:0]		)	// out	: Receive buffer write data (big endian)
	);

//
//	TCP Checker
//

	TCP_TEST	TCP_TEST(
		/* [System] */
		.CLK156M					(CLK156M					),	// Tx clock
		.TX_RATE					(RBCP_TX_RATE[7:0]			),	// Transmission data rate in units of 100 Mbps
		.NUM_OF_DATA				(RBCP_NUM_OF_DAT[63:0]		),	// Number of bytes of transmitted data
		.DATA_GEN					(RBCP_DATA_GEN				),	// Data transmission enable
		.LOOPBACK					(RBCP_LOOPBACK				),	// Loopback mode
		.WORD_LEN					(GPIO_DIP_SW[2:0]			),	// Word length of test data
		.SELECT_SEQ					(RBCP_SEL_SEQ				),	// Selection of sequence data
		.SEQ_PATTERN				(RBCP_SEQ_PTN[31:0]			),	// sequence data(The default value is 0x60808040)
		.BLK_SIZE					(RBCP_BLK_SIZE[23:0]		),	// Transmission block size in bytes
		.INS_ERROR					(INS_ERROR					),	// Data error insertion
		/* [SiTCP-XG I/F] */
		.SiTCPXG_ESTABLISHED		(SiTCPXG_ESTABLISHED		),	// Establish of a session
		.SiTCPXG_RX_SIZE			(SiTCPXG_RX_SIZE[15:0]		),	// Receive buffer size(byte) caution:Set a value of 4000 or more and (memory size-16) or less
		.SiTCPXG_RX_CLR_ENB			(SiTCPXG_RX_CLR_ENB			),	// Receive buffer Clear Enable
		.SiTCPXG_RX_CLR_REQ			(SiTCPXG_RX_CLR_REQ			),	// Receive buffer Clear Request
		.SiTCPXG_RX_RADR			(SiTCPXG_RX_RADR[15:0]		),	// Receive buffer read address in bytes (unused upper bits are set to 0)
		.SiTCPXG_RX_WADR			(SiTCPXG_RX_WADR[15:0]		),	// Receive buffer write address in bytes (lower 3 bits are not connected to memory)
		.SiTCPXG_RX_WENB			(SiTCPXG_RX_WENB[ 7:0]		),	// Receive buffer byte write enable (big endian)
		.SiTCPXG_RX_WDAT			(SiTCPXG_RX_WDAT[63:0]		),	// Receive buffer write data (big endian)
		.SiTCPXG_TX_AFULL			(SiTCPXG_TX_AFULL			),	// TX fifo, almost full
		.SiTCPXG_TX_D				(SiTCPXG_TX_D[63:0]			),	// Tx data[63:0]
		.SiTCPXG_TX_B				(SiTCPXG_TX_B[3:0]			)	// Byte length of USER_TX_DATA(Set to 0 if not written)
	);

	RBCP_TEST			RBCP_TEST(
		// System
		.CLK						(CLK156M					),	// in	 : XGMII Rx clock 157MHz
		.RSTs						(~SYS_RSTn					),	// in	 : System reset
		.REG_FPGA_VER				(REG_FPGA_VER[31:0]			),
		// Processor I/F
		.LOC_ADDR					(RBCP_ADDR[31:0]			),	// in	 : Address[31:0]
		.LOC_WE						(RBCP_WE					),	// in	 : Write enable
		.LOC_WD						(RBCP_WD[7:0]				),	// in	 : Write data[7:0]
		.LOC_RE						(RBCP_RE					),	// in	 : Read enable
		.LOC_ACK					(RBCP_ACK					),	// out	 : Read valid
		.LOC_RD						(RBCP_RD[7:0]				),	// out   : Read data[7:0]
		.SiTCPXG_OPEN_REQ			(SiTCPXG_OPEN_REQ			),	// Request for opening the new session
		.SiTCPXG_ESTABLISHED		(SiTCPXG_ESTABLISHED		),	// Establish of a session
		.SiTCPXG_CLOSE_REQ			(SiTCPXG_CLOSE_REQ			),	// Request for closing session.
		.SiTCPXG_CLOSE_ACK			(SiTCPXG_CLOSE_ACK			),	// Acknowledge for USER_SESSION_CLOSE_REQ.
		.LOOPBACK					(RBCP_LOOPBACK				),	// Loopback mode
		.SELECT_SEQ					(RBCP_SEL_SEQ				),	// Selection of sequence data
		.DATA_GEN					(RBCP_DATA_GEN				),	// Data transmission e nable
		.TX_RATE					(RBCP_TX_RATE[7:0]			),	// Transmission data rate in units of 100 Mbps
		.BLK_SIZE					(RBCP_BLK_SIZE[23:0]		),	// Transmission block size in bytes
		.SEQ_PATTERN				(RBCP_SEQ_PTN[31:0]			),	// sequence data(The default value is 0x60808040)
		.NUM_OF_DATA				(RBCP_NUM_OF_DAT[63:0]		)	// Number of bytes of transmitted data
	);


//------------------------------------------------------------------------------
//	10GbE PCS/PMA
//------------------------------------------------------------------------------

	assign	SFP1_TDIS	= 1'b0;
	assign	SFP1_RATE_SELECT[1:0]	= 2'b11;

	wire			dclk;

	xxv_ethernet_0	xxv_ethernet_0	(
		.gt_rxp_in_0							(SFP1_RX_P			),			// input wire gt_rxp_in_0
		.gt_rxn_in_0							(SFP1_RX_N			),			// input wire gt_rxn_in_0
		.gt_txp_out_0							(SFP1_TX_P			),			// output wire gt_txp_out_0
		.gt_txn_out_0							(SFP1_TX_N			),			// output wire gt_txn_out_0
		.rx_core_clk_0							(CLK156M			),			// input wire rx_core_clk_0
		.txoutclksel_in_0						(3'b101				),			// input wire [2 : 0] txoutclksel_in_0   101?
		.rxoutclksel_in_0						(3'b101				),			// input wire [2 : 0] rxoutclksel_in_0
		.gtwiz_reset_tx_datapath_0				(~SYS_RSTn			),			// input wire gtwiz_reset_tx_datapath_0
		.gtwiz_reset_rx_datapath_0				(~SYS_RSTn			),			// input wire gtwiz_reset_rx_datapath_0
		.rxrecclkout_0							(					),			// output wire rxrecclkout_0
		.sys_reset								(~SYS_RSTn			),			// input wire sys_reset
		.dclk									(dclk				),			// input wire dclk
		.tx_mii_clk_0							(CLK156M			),			// output wire tx_mii_clk_0
		.rx_clk_out_0							(					),			// output wire rx_clk_out_0
		.gt_refclk_p							(SFPXG_MGT_CLK0_P	),			// input wire gt_refclk_p
		.gt_refclk_n							(SFPXG_MGT_CLK0_N	),			// input wire gt_refclk_n
		.gt_refclk_out							(dclk				),			// output wire gt_refclk_out
		.gtpowergood_out_0						(					),			// output wire gtpowergood_out_0
		.rx_reset_0								(~SYS_RSTn			),			// input wire rx_reset_0
		.user_rx_reset_0						(					),			// output wire user_rx_reset_0
		.rx_mii_d_0								(xgmii_rxd[63:0]	),			// output wire [63 : 0] rx_mii_d_0
		.rx_mii_c_0								(xgmii_rxc[7:0]		),			// output wire [7 : 0] rx_mii_c_0
		.ctl_rx_wdt_disable_0					(1'b1				),			// input wire ctl_rx_wdt_disable_0
		.ctl_rx_test_pattern_0					(1'b0				),			// input wire ctl_rx_test_pattern_0
		.ctl_rx_data_pattern_select_0			(1'b0				),			// input wire ctl_rx_data_pattern_select_0
		.ctl_rx_test_pattern_enable_0			(1'b0				),			// input wire ctl_rx_test_pattern_enable_0
		.ctl_rx_prbs31_test_pattern_enable_0	(1'b0				),			// input wire ctl_rx_prbs31_test_pattern_enable_0
		.stat_rx_framing_err_0					(					),			// output wire stat_rx_framing_err_0
		.stat_rx_framing_err_valid_0			(					),			// output wire stat_rx_framing_err_valid_0
		.stat_rx_local_fault_0					(					),			// output wire stat_rx_local_fault_0
		.stat_rx_block_lock_0					(					),			// output wire stat_rx_block_lock_0
		.stat_rx_valid_ctrl_code_0				(					),			// output wire stat_rx_valid_ctrl_code_0
		.stat_rx_status_0						(					),			// output wire stat_rx_status_0
		.stat_rx_hi_ber_0						(					),			// output wire stat_rx_hi_ber_0
		.stat_rx_bad_code_0						(					),			// output wire stat_rx_bad_code_0
		.stat_rx_bad_code_valid_0				(					),			// output wire stat_rx_bad_code_valid_0
		.stat_rx_error_0						(					),			// output wire [7 : 0] stat_rx_error_0
		.stat_rx_error_valid_0					(					),			// output wire stat_rx_error_valid_0
		.stat_rx_fifo_error_0					(					),			// output wire stat_rx_fifo_error_0
		.tx_reset_0								(~SYS_RSTn			),			// input wire tx_reset_0
		.user_tx_reset_0						(					),			// output wire user_tx_reset_0
		.tx_mii_d_0								(xgmii_txd[63:0]	),			// input wire [63 : 0] tx_mii_d_0
		.tx_mii_c_0								(xgmii_txc[7:0]		),			// input wire [7 : 0] tx_mii_c_0
		.stat_tx_local_fault_0					(					),			// output wire stat_tx_local_fault_0
		.ctl_tx_test_pattern_0					(1'b0				),			// input wire ctl_tx_test_pattern_0
		.ctl_tx_test_pattern_enable_0			(1'b0				),			// input wire ctl_tx_test_pattern_enable_0
		.ctl_tx_test_pattern_select_0			(1'b0				),			// input wire ctl_tx_test_pattern_select_0
		.ctl_tx_data_pattern_select_0			(1'b0				),			// input wire ctl_tx_data_pattern_select_0
		.ctl_tx_test_pattern_seed_a_0			(56'd0				),			// input wire [57 : 0] ctl_tx_test_pattern_seed_a_0
		.ctl_tx_test_pattern_seed_b_0			(56'd0				),			// input wire [57 : 0] ctl_tx_test_pattern_seed_b_0
		.ctl_tx_prbs31_test_pattern_enable_0	(1'b0				),			// input wire ctl_tx_prbs31_test_pattern_enable_0
		.gt_loopback_in_0						(3'b000				),			// input wire [2 : 0] gt_loopback_in_0
		.qpllreset_in_0							(~SYS_RSTn			)			// input wire qpllreset_in_0
	);
		
	always @(posedge CLK156M or posedge SiTCP_RESET) begin
		if(SiTCP_RESET)begin
			tgbeCnt[25:0] <= 25'd0;
		end else begin
			tgbeCnt[25:0] <= tgbeCnt[25:0] + 26'd1;
		end
	end

	always @(posedge CLK156M ) begin
		tx_count[23:0]	<= SiTCPXG_ESTABLISHED?		(tx_count[23:0] + (tx_count[23]?	25'd1:		{20'd0,SiTCPXG_TX_B[3:0]})):	24'd0;
		rx_high[2]	<= (SiTCPXG_RX_WENB[7:4] == 4'b1111);
		rx_high[1]	<= (
			(SiTCPXG_RX_WENB[7:4] == 4'b0111)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1011)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1101)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1110)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1100)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1010)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1001)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0110)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0101)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0011)
		);
		rx_high[0]	<= (
			(SiTCPXG_RX_WENB[7:4] == 4'b0111)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1011)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1101)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1110)|
			(SiTCPXG_RX_WENB[7:4] == 4'b1000)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0100)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0010)|
			(SiTCPXG_RX_WENB[7:4] == 4'b0001)
		);
		rx_low[2]	<= (SiTCPXG_RX_WENB[3:0] == 4'b1111);
		rx_low[1]	<= (
			(SiTCPXG_RX_WENB[3:0] == 4'b0111)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1011)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1101)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1110)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1100)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1010)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1001)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0110)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0101)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0011)
		);
		rx_low[0]	<= (
			(SiTCPXG_RX_WENB[3:0] == 4'b0111)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1011)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1101)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1110)|
			(SiTCPXG_RX_WENB[3:0] == 4'b1000)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0100)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0010)|
			(SiTCPXG_RX_WENB[3:0] == 4'b0001)
		);
		rx_up[3:0]	<= {1'b0,rx_high[2:0]} + {1'b0,rx_low[2:0]};
		rx_count[23:0]	<= SiTCPXG_ESTABLISHED?		(rx_count[23:0] + (rx_count[23]?	24'd1:		{20'd0,rx_up[3:0]})):	24'd0;
	end

	assign	GPIO_LED[0] = EXP_LED[0];
	assign	GPIO_LED[1] = EXP_LED[1];
	assign	GPIO_LED[2] = EXP_LED[2];
	assign	GPIO_LED[3] = EXP_LED[3];
	assign	GPIO_LED[4] = FD_enable;
	assign	GPIO_LED[5] = SiTCP_RESET;
	assign	GPIO_LED[6] = tgbeCnt[25];
	assign	GPIO_LED[7] = SiTCPXG_ESTABLISHED;
	assign	GPIO_LED[8] = tx_count[23];
	assign	GPIO_LED[9] = rx_count[23];

endmodule