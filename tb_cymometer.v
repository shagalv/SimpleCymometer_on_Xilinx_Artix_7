//说明：加了按键选择功能后的频率计模块功能性测试
//实例化的模块：matrix_key, cymometer
`timescale 1ns/1ps
module tb_cymometer_v2(
);

parameter CNT_GATE_LOW = 30'd12_500_000;
parameter CLK_FS_FREQ = 30'd100_000_000;
parameter DATAWIDTH = 8'd59;

parameter SYS_CLK_PERIOD = 20;
parameter CLK_FS_PERIOD = 10;
parameter CLK_FX_PERIOD = 50;
parameter CLK_SELF_PERIOD = 1000;//校准时钟1MHz


reg      sys_clk;
reg      clk_fs;
reg      clk_fx;
reg 	 clk_self;

reg      sys_rst_n;
wire[2:0] pattern;
wire      ready;
wire[58:0] quotient;
wire[58:0] remainder;
wire       vld_out;


wire[29:0] CNT_GATE_MAX;
wire[29:0] CNT_TIME_MAX;
wire[29:0] data_fx;
wire[29:0] cycle_fx;
wire[58:0] dividend;
wire[58:0] divisor;
wire       en;
wire[3:0] col;
wire[3:0] row;




initial
begin
    sys_rst_n <= 1'd0;
    sys_clk <= 1'd0;
    clk_fs <= 1'd0;
    clk_fx <= 1'd0;
    clk_self <= 1'd0;
    #20000 sys_rst_n <= 1'd1;

end

always #(SYS_CLK_PERIOD/2) sys_clk = ~sys_clk;//系统时钟频率为50MHz
always #(CLK_FS_PERIOD/2) clk_fs = ~clk_fs;//基准时钟频率为100MHz
always #(CLK_FX_PERIOD/2) clk_fx = ~clk_fx;//待测时钟频率为20MHz 
always #(CLK_SELF_PERIOD/2) clk_self = ~clk_self;//校准时钟频率为1MHz

cymometer#(
.CNT_GATE_LOW (CNT_GATE_LOW), // 闸门为低的时间 0.25s
.CLK_FS_FREQ (CLK_FS_FREQ )
)
u_cymometer(
.sys_clk (sys_clk ), // 系统时钟， 50M
.clk_fs (clk_fs ), // 基准时钟， 100M，由PLL产生
.sys_rst_n (sys_rst_n ), // 系统复位，低电平有效
.Pattern(pattern),
.clk_fx_1 (clk_fx ), // 被测时钟信号，是外部输入值，由input产生
.clk_self(clk_self),//自校时钟

.CNT_GATE_MAX(CNT_GATE_MAX),
.CNT_TIME_MAX(CNT_TIME_MAX),

.data_fx_result (data_fx ), // 实际测量得到的 被测时钟频率值
.cycle_fx(cycle_fx),
.dividend (dividend ), // 被除数
.divisor (divisor ), // 除数
.en (en ),//输出使能信号
.ready (ready ),//输入
.quotient (quotient ), //输入 商
.remainder (remainder ), //输入 余数
.vld_out (vld_out )//输入 值有效信号
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

.ready (ready ), //输出
.quotient (quotient ), //输出 商，相当于中间变量
.remainder (remainder ),//输出 余数，相当于中间变量
.vld_out (vld_out ) //输出有效信号 ，相当于vld_out是中间变量
);



key_pattern u_key_pattern(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .col(col),
    .key_gate_time(CNT_GATE_MAX),
    .key_time_max(CNT_TIME_MAX),
    .pattern(pattern),
    .row(row)
);

endmodule