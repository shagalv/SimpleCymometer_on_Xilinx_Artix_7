module top_oled(
    input	sys_clk,    //系统时钟的输入
    input   sys_rst_n,  //复位信号
    input[29:0] data_fx,
    input[2:0] pattern,
    output	oled_rst,	//oled复位	
    output	oled_dcn,	//oled数据/命令控制
    output	oled_clk,	//SPI时钟信号
    output	oled_dat    //SPI数据信号
);
//wire	[26:0]  WaveFreq;
// 在你的顶层模块中
OLED12864 oled_display (
    .sys_clk(sys_clk),         // 提供50MHz时钟
    .sys_rst_n(sys_rst_n),     // 复位信号
    .sw(4'b0000),              // 开关全部关闭
    .wave(2'b00),              // 选择正弦波，把这个改成模式的选择与显示
    .WaveFreq(data_fx),  // 1MHz频率
    .oled_csn(oled_csn),       // 连接到OLED
    .oled_rst(oled_rst),
    .oled_dcn(oled_dcn), 
    .oled_clk(oled_clk),
    .oled_dat(oled_dat),
    .pattern(pattern)
);
endmodule
