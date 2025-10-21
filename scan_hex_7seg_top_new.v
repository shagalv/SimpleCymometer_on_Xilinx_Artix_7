`timescale 1ns / 1ps

module scan_hex_7seg_top(
    input sys_clk,
    input [4:1] key,
	input [4:1] sw,
	input sys_rst_n,
	input [29:0] data_in,//测量得到的信号频率
	output [7:0] seg_sel,
	output [7:0] seg_led
    );
	
	localparam SEG_LED_WIDTH = 30;

	wire[7:0] dp_in;

	wire		u1_ready;
	wire	[29:0] u1_quotient;
	wire [29:0] u1_remainder;
	wire			u1_vld_out;//输出有效信号 

	wire		u2_ready;
	wire	[29:0] u2_quotient;
	wire [29:0] u2_remainder;
	wire			u2_vld_out;//输出有效信号

	wire		u3_ready;
	wire	[29:0] u3_quotient;
	wire [29:0] u3_remainder;
	wire			u3_vld_out;//输出有效信号

	wire		u4_ready;
	wire	[29:0] u4_quotient;
	wire [29:0] u4_remainder;
	wire			u4_vld_out;//输出有效信号

	wire		u5_ready;
	wire	[29:0] u5_quotient;
	wire [29:0] u5_remainder;
	wire			u5_vld_out;//输出有效信号

	wire		u6_ready;
	wire	[29:0] u6_quotient;
	wire [29:0] u6_remainder;
	wire			u6_vld_out;//输出有效信号

	wire		u7_ready;
	wire	[29:0] u7_quotient;
	wire [29:0] u7_remainder;
	wire			u7_vld_out;//输出有效信号

	wire		u8_ready;
	wire	[29:0] u8_quotient;
	wire [29:0] u8_remainder;
	wire			u8_vld_out;//输出有效信号


	wire[31:0] data_result;//最终输入给具体 哪一个七段管的数值

	assign dp_in = {key,sw};
	
	div_fsm#(
		.DATAWIDTH(SEG_LED_WIDTH)
	) u1_div_fsm
	(
		.clk(sys_clk),
		.rst_n(sys_rst_n),
		.en(1'b1),
		.dividend(data_in),	//对输入信号进行位数量化
		.divisor(30'd10),	//除数设置为10
		.ready(u1_ready),
		.quotient(u1_quotient),
		.remainder(u1_remainder),
		.vld_out(u1_vld_out)
	);


	div_fsm#(
		.DATAWIDTH(SEG_LED_WIDTH)
	) u2_div_fsm
	(
		.clk(sys_clk),
		.rst_n(sys_rst_n),
		.en(1'b1),
		.dividend(u1_quotient),	//第二个除法器的输入，是上一个除法器输出的商
		.divisor(30'd10),	//除数设置为10
		.ready(u2_ready),
		.quotient(u2_quotient),
		.remainder(u2_remainder),
		.vld_out(u2_vld_out)
	);

	div_fsm#(
		.DATAWIDTH(SEG_LED_WIDTH)
	) u3_div_fsm
	(
		.clk(sys_clk),
		.rst_n(sys_rst_n),
		.en(1'b1),
		.dividend(u2_quotient),	
		.divisor(30'd10),	//除数设置为10
		.ready(u3_ready),
		.quotient(u3_quotient),
		.remainder(u3_remainder),
		.vld_out(u3_vld_out)
	);

div_fsm#(
		.DATAWIDTH(SEG_LED_WIDTH)
	) u4_div_fsm
	(
		.clk(sys_clk),
		.rst_n(sys_rst_n),
		.en(1'b1),
		.dividend(u3_quotient),	
		.divisor(30'd10),	//除数设置为10
		.ready(u4_ready),
		.quotient(u4_quotient),
		.remainder(u4_remainder),
		.vld_out(u4_vld_out)
	);

div_fsm#(
		.DATAWIDTH(SEG_LED_WIDTH)
	) u5_div_fsm
	(
		.clk(sys_clk),
		.rst_n(sys_rst_n),
		.en(1'b1),
		.dividend(u4_quotient),	
		.divisor(30'd10),	//除数设置为10
		.ready(u5_ready),
		.quotient(u5_quotient),
		.remainder(u5_remainder),
		.vld_out(u5_vld_out)
	);

div_fsm#(
		.DATAWIDTH(SEG_LED_WIDTH)
	) u6_div_fsm
	(
		.clk(sys_clk),
		.rst_n(sys_rst_n),
		.en(1'b1),
		.dividend(u5_quotient),	
		.divisor(30'd10),	//除数设置为10
		.ready(u6_ready),
		.quotient(u6_quotient),
		.remainder(u6_remainder),
		.vld_out(u6_vld_out)
	);

div_fsm#(
		.DATAWIDTH(SEG_LED_WIDTH)
	) u7_div_fsm
	(
		.clk(sys_clk),
		.rst_n(sys_rst_n),
		.en(1'b1),
		.dividend(u6_quotient),	
		.divisor(30'd10),	//除数设置为10
		.ready(u7_ready),
		.quotient(u7_quotient),
		.remainder(u7_remainder),
		.vld_out(u7_vld_out)
	);

div_fsm#(
		.DATAWIDTH(SEG_LED_WIDTH)
	) u8_div_fsm
	(
		.clk(sys_clk),
		.rst_n(sys_rst_n),
		.en(1'b1),
		.dividend(u7_quotient),	
		.divisor(30'd10),	//除数设置为10
		.ready(u8_ready),
		.quotient(u8_quotient),
		.remainder(u8_remainder),
		.vld_out(u8_vld_out)
	);

	assign data_result = {u8_remainder[3:0],u7_remainder[3:0],u6_remainder[3:0],u5_remainder[3:0],u4_remainder[3:0],u3_remainder[3:0],u2_remainder[3:0],u1_remainder[3:0]};


	scan_hex_7seg U1(
      .clk(sys_clk),
	  .rst(1'b0),
      .hex7(data_result[3:0]),
	  .hex6(data_result[7:4]),
	  .hex5(data_result[11:8]),
	  .hex4(data_result[15:12]),
	  .hex3(data_result[19:16]),
	  .hex2(data_result[23:20]),
	  .hex1(data_result[27:24]),
	  .hex0(data_result[31:27]),
      .dp_in(dp_in),
      .seg_sel(seg_sel),
      .seg_led(seg_led)
  
    );
endmodule
  