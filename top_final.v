/*top_final实现思路：
实际上两个模块（频率计和脉冲计）都会正常产生数据，但是最终在硬件引脚上，通过
en1，en2实现oled引脚的选通输出。
*/
module top_final(
    input sys_clk,
    input sys_rst_n,
    input clk_fx,
    input sw4,
    input[3:0] row,

    output oled_dat,
    output oled_rst,
    output oled_dcn,
    output oled_clk,

    output[3:0] col,
    output[7:0] seg_sel,
    output[7:0] seg_led,
    output[4:1] led
);
parameter DIV_N = 26'd100;
parameter CNT_GATE_LOW = 30'd12_500_000;
parameter CLK_FS_FREQ = 30'd100_000_000;
parameter DATAWIDTH = 8'd59;

wire    oled_rst_1;//连接到频率计
wire    oled_dcn_1;
wire    oled_clk_1;
wire    oled_dat_1;

wire    oled_rst_2;//连接到脉冲计
wire    oled_dcn_2;
wire    oled_clk_2;
wire    oled_dat_2;

wire[7:0]    seg_led_1;
wire[7:0]    seg_led_2;
wire[7:0]    seg_sel_1;
wire[7:0]    seg_sel_2;
wire[4:1]    led1;
wire[4:1]    led2;

wire[1:0]    choose;//1使能频率计，2使能脉冲计

wire[3:0]    col1;
wire[3:0]    col2;
wire[3:0]    row1;
wire[3:0]    row2;

//en信号实现 输出给外设的信号的 双路选通
assign oled_rst = (choose == 2'd2) ? oled_rst_2 : oled_rst_1;//复位情况下，oled_1信号也是0，不用考虑
assign oled_dcn = (choose == 2'd2) ? oled_dcn_2 : oled_dcn_1;
assign oled_clk = (choose == 2'd2) ? oled_clk_2 : oled_clk_1;
assign oled_dat = (choose == 2'd2) ? oled_dat_2 : oled_dat_1;
assign seg_led  = (choose == 2'd2) ? seg_led_2 : seg_led_1;
// assign seg_led[6:0]  = 7'b0000_001; //Debug
assign seg_sel  = (choose == 2'd2) ? seg_sel_2 : seg_sel_1;
assign led      = (choose == 2'd2) ? led2 : led1;
assign col      = (choose == 2'd2) ? col2 : col1;

assign row1 = row;
assign row2 = row;


single_key top_key_pattern(
    .sw4(sw4),//主板的四个key，用来切换 频率计（周期）/ 脉冲/占空比测量
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .choose(choose)
);

top_cymometer #(
.DIV_N(DIV_N),
.CNT_GATE_LOW(CNT_GATE_LOW),
.CLK_FS_FREQ(CLK_FS_FREQ),
.DATAWIDTH(DATAWIDTH)
)
u_top_cymometer(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .clk_fx(clk_fx),
    .row(row1),

    .oled_dat(oled_dat_1),
    .oled_rst(oled_rst_1),
    .oled_dcn(oled_dcn_1),
    .oled_clk(oled_clk_1),

    .col(col1),
    .seg_sel(seg_sel_1),
    .seg_led(seg_led_1),
    .led(led1)
);

//脉冲计
top_duty u_top_duty(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    
    .clk_fx(clk_fx),//待测信号
    .row(row2),

    .oled_dat(oled_dat_2),
    .oled_rst(oled_rst_2),
    .oled_dcn(oled_dcn_2),
    .oled_clk(oled_clk_2),

    .col(col2),
    .seg_sel(seg_sel_2),
    
    .seg_led(seg_led_2),
    .led(led2)
);



endmodule