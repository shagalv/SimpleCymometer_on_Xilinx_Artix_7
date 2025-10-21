module top_cymometer#(
    parameter DIV_N = 26'd100 , // 分频系数
    parameter CNT_GATE_LOW = 30'd12_500_000 , // 闸门为低的时间 0.25s
    parameter CLK_FS_FREQ = 30'd100_000_000 ,
    parameter DATAWIDTH = 8'd59
)(
    input sys_clk , // 时钟信号
    input sys_rst_n , // 复位信号
    input clk_fx , // 被测时钟,
    input[3:0] row, //切记输入为row

    //OLED显示驱动
    output oled_dat,
    output oled_rst,
    output oled_dcn,
    output oled_clk,

    // output clk_out1 , // 输出时钟，由clk_test产生，500KHz
    // output clk_out2, 	// 输出时钟，由PLL产生，在Vivado IPIntegerator中设置为150MHz
    output[3:0] col,
    output[7:0] seg_sel,//输出数码管，总是第一个亮
    output[7:0] seg_led,
    output[4:1] led
);
wire [29:0] data_fx; // 被测信号测量值
wire [29:0] cycle_fx;//被测信号周期值
wire clk_fs; //由Pll产生，100MHz
wire en;
wire [58:0] dividend;
wire [58:0] divisor;
wire ready;
wire [58:0] quotient;
wire [58:0] remainder;
wire vld_out;
wire renew;
// wire[29:0] cnt_gate_fs;//Debug用


wire clk_o2;

wire[29:0]  CNT_GATE_MAX;
wire[29:0]  CNT_TIME_MAX;

// assign CNT_GATE_MAX = 30'd50_000_000;
// assign CNT_TIME_MAX = 30'd50_000_000;

wire[2:0]   pattern;
reg        clk_self;//自校验信号，1MHz 
reg[5:0]   self_cnt;
/*
*************main code*************
*/

//产生基准时钟 1M
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
    begin
        clk_self <= 1'd0;
        self_cnt <= 6'd0;
    end
    else
    begin
        if(self_cnt == 6'd24) 
        begin
            clk_self <= ~clk_self;
            self_cnt <= 6'd0;
        end
        else self_cnt <= self_cnt + 6'd1;
    end
end


//  pll_100m instance_name
//    (
//     // Clock out ports
//     .clk_out1(clk_out1),     // output clk_out1
//     .clk_out2(clk_out2),     // output clk_out2
//     // Status and control signals
//     .reset(~sys_rst_n), // input reset
// //    .locked(locked),       // output locked
//    // Clock in ports
//     .clk_in1(sys_clk)      // input clk_in1
// );

pll_100m instance_name
  (
   // Clock out ports
   .clk_out1(clk_fs),     // output clk_out1
   // Status and control signals
   .reset(~sys_rst_n), // input reset
//    .locked(locked),       // output locked
  // Clock in ports
   .clk_in1(sys_clk)      // input clk_in1
);


//例化等精度频率计模块
cymometer#(
.CNT_GATE_LOW (CNT_GATE_LOW), // 闸门为低的时间 0.25s
.CLK_FS_FREQ (CLK_FS_FREQ )
)
u_cymometer(
.sys_clk (sys_clk ), // 系统时钟， 50M
.clk_fs (clk_fs ), // 基准时钟， 100M，由PLL产生
.sys_rst_n (sys_rst_n ), // 系统复位，低电平有效
.Pattern(pattern),
.clk_fx_1 (clk_fx), // 被测时钟信号，是外部输入值，由input产生//Debug设置为cl_out1
.clk_self(clk_self),//自校时钟

.CNT_GATE_MAX(CNT_GATE_MAX),
.CNT_TIME_MAX(CNT_TIME_MAX),

.data_fx_result (data_fx ), // 实际测量得到的 被测时钟频率值/周期值
.cycle_fx(cycle_fx),
.dividend (dividend ), // 被除数
.divisor (divisor ), // 除数
.en (en ),//输出使能信号
.ready (ready ),//输入
.quotient (quotient ), //输入 商
.remainder (remainder ), //输入 余数
.vld_out (vld_out ),//输入 值有效信号
.led(led),
.renew(renew) //重新启动测量 标志信号
// .cnt_gate_fs(cnt_gate_fs) //Debug
);


div_fsm#( //正确
.DATAWIDTH (DATAWIDTH )
)
u_div_fsm(
.clk (sys_clk ),
.rst_n (sys_rst_n ),
.en (en ),
.dividend (dividend ),
.divisor (divisor ),
.renew(renew),

.ready (ready ), //输出
.quotient (quotient ), //输出 商，相当于中间变量
.remainder (remainder ),//输出 余数，相当于中间变量
.vld_out (vld_out ) //输出有效信号 ，相当于vld_out是中间变量
);


//例化测试时钟模块，产生测试时钟
clk_test#(
.DIV_N (DIV_N )
)
u_clk_test(
.clk_in (sys_clk ),
.rst_n (sys_rst_n ),
.clk_out (clk_o2 ) //产生500kHz 的时钟
);


key_pattern u_key_pattern(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .col(col),
    .key_gate_time(CNT_GATE_MAX),
    .key_time_max(CNT_TIME_MAX),
    .pattern(pattern),
    .row(row),
    .seg_sel(seg_sel),
    .seg_led(seg_led),
    .renew(renew)
);

top_oled u_top_oled(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .data_fx(data_fx),
    .oled_rst(oled_rst),
    .oled_dcn(oled_dcn),
    .oled_clk(oled_clk),
    .oled_dat(oled_dat),
    .pattern(pattern)
);

// //ILA
// ila_0 your_instance_name (
// 	.clk(sys_clk), // input wire clk


// 	.probe0(col), // input wire [3:0]  probe0  
// 	.probe1(row), // input wire [3:0]  probe1 
// 	.probe2(seg_sel), // input wire [7:0]  probe2 
// 	.probe3(seg_led), // input wire [7:0]  probe3 
// 	.probe4(data_fx), // input wire [29:0]  probe4 
//     .probe5(pattern),
//     .probe6(CNT_GATE_MAX),
//     .probe7(CNT_TIME_MAX),
//     .probe8(dividend), // input wire [58:0]  probe8 
// 	.probe9(divisor), // input wire [58:0]  probe9 
// 	.probe10(en), // input wire [0:0]  probe10 
// 	.probe11(quotient), // input wire [58:0]  probe11 
// 	.probe12(remainder), // input wire [58:0]  probe12 
// 	.probe13(ready), // input wire [0:0]  probe13 
// 	.probe14(vld_out) // input wire [0:0]  probe14
//     // .probe15(cnt_gate_fs)//input wire[29:0] probe15
// );


//例化数码管显示模块
//scan_hex_7seg_top u_scan_hex_7seg_top(
//   .clkin_50m(sys_clk),
//   .key(key),
//    .sw(),
//    .seg_sel(seg_sel),
//    .seg_led(seg_led)
//);



endmodule