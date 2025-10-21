module pulse_width_measurement #(
    parameter CLK_FREQ_MHZ = 50,  // 系统时钟固定�?????????100MHz
    parameter DATAWIDTH = 8'd30 
)(
    input wire sys_clk,
    input wire sys_rst_n,        // 由外部的按键控制刷新
    input wire clk_fx,           // 待测脉冲输入
    //input en,                     //��ģ��ʹ���ź�
    output wire [29:0] pulse_width_us, // 脉冲宽度（μs�?????????
    output wire measurement_valid      // 测量有效信号
);
//wire [31:0] pulse_width_us;
// 内部信号
wire [29:0] width_count;      // 原始计数�?????????
wire count_valid;             // 计数值有�?????????
wire div_ready;               // 除法器就�?????????
wire div_valid;               // 除法结果有效
wire [29:0] quotient;         // 商（整数部分�?????????
wire [29:0] remainder;        // 余数
reg en_reg;//除法器使能型号寄存器
reg [29:0]dividend_reg;

pulse_width_counter counter_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .pulse_in(clk_fx),
    .width_count(width_count),
    .valid(count_valid)
);

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        en_reg<=0;
        dividend_reg<=0;
    end
    else begin
        en_reg<=count_valid;
        dividend_reg<=width_count;
    end
end

div_fsm #(
    .DATAWIDTH(DATAWIDTH)  // 使用32位位�?????????
) div_inst (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .en(en_reg),           // 当计数完成时启动除法
    .dividend(dividend_reg),     // 被除�????????? = 计数�?????????
    .divisor(CLK_FREQ_MHZ),     // 除数 = 时钟频率（MHz�?????????
    
    .ready(div_ready),
    .quotient(quotient),        // �????????? = 脉宽的整数部分（μs�?????????
    .remainder(remainder),      // 余数 = 小数部分的基�?????????
    .vld_out(div_valid)         // 除法完成信号
);
reg div_valid_reg;//除法器输出的使能信号比计算结果输出早�???个周期导致数据没法导入oled显示程序
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        div_valid_reg <= 0;  //复位
    end
    else begin
        div_valid_reg<=div_valid;
    end
end

reg [29:0] pulse_width_reg;  // 閿佸瓨鏈�缁堢殑鑴夊缁撴灉

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        pulse_width_reg <= 32'd0;  // 澶嶄綅鏃舵竻闆�
    end
    else if (div_valid_reg) begin      // 前面的打拍让这个信号可以正常读进OLED
        pulse_width_reg <= quotient + 30'd1;
    end
end

// 杈撳嚭鍒嗛厤
assign pulse_width_us = pulse_width_reg;  // 杈撳嚭閿佸瓨鍚庣殑鍊�????
assign measurement_valid = div_valid;     // 鏈夋晥淇″彿浠嶄负鍗曞懆�????

// ila_0 your_instance_name (
// 	.clk(sys_clk), // input wire clk


// 	.probe0(pulse_width_reg), // input wire [31:0]  probe0  
// 	.probe1(dividend_reg), // input wire [31:0]  probe1 
// 	.probe2(quotient), // input wire [31:0]  probe2 
// 	.probe3(count_valid), // input wire [0:0]  probe3 
// 	.probe4(en_reg), // input wire [0:0]  probe4
// 	.probe5(div_valid_reg) // input wire [0:0]  probe5
// );
endmodule