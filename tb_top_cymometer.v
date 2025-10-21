`timescale 1ns/1ps
module tb_top_cymometer();
// top_cymometer Parameters
parameter CNT_GATE_LOW = 30'd12_500_000 ; // 闸门为低的时间
parameter CLK_FS_FREQ = 30'd100_000_000 ;
parameter DIV_N = 26'd10 ; // 分频系数
 // top_cymometer Inputs
reg sys_clk;
reg sys_rst_n;
reg clk_fx;
reg [3:0] col;

wire oled_dat;
wire oled_rst;
wire oled_dcn;
wire oled_clk;
wire clk_out1;
wire clk_out2;
wire [3:0] row;

assign row = 4'b1110;
//初始化系统时钟、全局复位
initial begin
sys_clk <= 1'b0;
sys_rst_n <= 1'b0;
clk_fx <= 1'b0;
col <= 4'd0;
#40;
sys_rst_n <= 1'b1;
#1_000_000_000 
// row = 4'b1110;//模拟按键1按下 //测量频率
col <= 4'b1101; 
#1_000_000_000
// row = 4'd1110;//模拟按键2按下 //测量周期
col <= 4'b1011;
#1_000_000_000
// row = 4'b1110;//模拟按键3按下 //测量脉冲
col <= 4'b0111;
// #40
// // row = 4'b1101;//模拟按键5按下，自校验1MHz
// col <= 4'b1101;

// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//1
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//2
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//3
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//4
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//5
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//6
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//7
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//8
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//9
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//10
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//11
// #40
// // row = 4'b1101;//模拟按键4按下 //自校验 1MHz
// col <= 4'b1110;//11

// row,col 
//8'b1110_1101:key_value<=4'H1;
// 8'b1110_1011:key_value<=4'H2;
// 8'b1110_0111:key_value<=4'H3;
// 8'b1101_1110:key_value<=4'H4;
// 8'b1101_1101:key_value<=4'H5;
// 8'b1101_1011:key_value<=4'H6;
// 8'b1101_0111:key_value<=4'H7;
// 8'b1011_1110:key_value<=4'H8;
// 8'b1011_1101:key_value<=4'H9;
// 8'b1011_1011:key_value<=4'Ha;
// 8'b1011_0111:key_value<=4'Hb;
// 8'b0111_1110:key_value<=4'Hc;
// 8'b0111_1101:key_value<=4'Hd;
// 8'b0111_1011:key_value<=4'He;
// 8'b0111_0111:key_value<=4'Hf; 

end

//sys_clk:每 10ns 电平翻转一次，产生一个 50MHz 的时钟信号
always #10 sys_clk = ~sys_clk;

//模拟被测时钟
always #100 clk_fx = ~clk_fx;//在这个tb中，待测时钟信号为5MHz，输入top_cymometer模块中


//top_cymometer
top_cymometer #(
.DIV_N (DIV_N ),
.CNT_GATE_LOW (CNT_GATE_LOW),
.CLK_FS_FREQ (CLK_FS_FREQ )
)
u_top_cymometer(
.sys_clk ( sys_clk ),
.sys_rst_n ( sys_rst_n ),
.clk_fx ( clk_fx ),
.col(col),
.oled_dat(oled_dat),
.oled_rst(oled_rst),
.oled_dcn(oled_dcn),
.oled_clk(oled_clk),
.clk_out1(clk_out1),
.clk_out2(clk_out2),
.row(row)
);

endmodule