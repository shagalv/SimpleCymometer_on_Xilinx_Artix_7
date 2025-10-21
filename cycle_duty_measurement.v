module cycle_duty_measurement#(
    parameter DATAWIDTH = 8'd30 
)
(
    input wire sys_clk,
    input wire sys_rst_n,
    input wire clk_fx,           // 待测脉冲输入
    output wire [29:0] cycle_duty, // 占空�??
    output wire measurement_valid      // 测量有效信号
);

// 内部信号
wire [29:0] cycle_duty; // 占空�?
wire [29:0] pulse_width_count;      // 原始计数�?????
wire [29:0] pulse_width_count_reg;
wire [29:0] cycle_width_count;      // 原始计数�?????
wire pulse_count_valid;       // 脉冲宽度计数值有�??
wire cycle_count_valid;       // 整周期计数�?�有�??
wire div_ready;               // 除法器就�?????
wire div_valid;               // 除法结果有效
wire [29:0] quotient;         // 商（整数部分�?????
wire [29:0] remainder;        // 余数
reg en_reg;//除法器使能型号寄存器
reg [29:0]dividend_reg;
reg [29:0]divisor_reg;
reg div_valid_reg;//除法器输出的使能信号比计算结果输出早�???个周期导致数据没法导入oled显示程序
assign pulse_width_count_reg=pulse_width_count*10000;
pulse_width_counter counter_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .pulse_in(clk_fx),
    .width_count(pulse_width_count),
    .valid(pulse_count_valid)
);

//再获得整个周期的计数�??
entire_cycle_measurer cycle_measurer(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .pulse_in(clk_fx),
    .cycle_count(cycle_width_count),
    .valid(cycle_count_valid)
);

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        en_reg <= 0;
        div_valid_reg <= 0;
        dividend_reg<=0;
        divisor_reg<=0;
    end
    else begin
        en_reg<=pulse_count_valid;
        dividend_reg<=pulse_width_count_reg;
        divisor_reg<=cycle_width_count;
        div_valid_reg <= div_valid;
    end
end

//调用除法器将两个计数值相除即可得到结�?? 
div_fsm #(
    .DATAWIDTH(DATAWIDTH)  // 使用32位位�?????
) div_inst (
    .clk(sys_clk),
    .rst_n(sys_rst_n),
    .en(en_reg),           // 当计数完成时启动除法
    .dividend(dividend_reg),     // 被除�????? = 计数�?????
    .divisor(divisor_reg),     // 除数 = 时钟频率（MHz�?????
    .ready(div_ready),
    .quotient(quotient),        // �????? = 脉宽的整数部分（μs�?????
    .remainder(remainder),      // 余数 = 小数部分的基�?????
    .vld_out(div_valid)         // 除法完成信号
);
reg [29:0] cycle_duty_reg;  // 閿佸瓨鏈�缁堢殑鑴夊缁撴灉

always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        cycle_duty_reg <= 30'd0;  // 澶嶄綅鏃舵竻闆�
    end
    else if (div_valid_reg) begin      // 褰撻櫎娉曠粨鏋滄湁鏁堟椂鏇存柊閿佸瓨鍊�
        cycle_duty_reg <= quotient;
    end
end

// 输出分配
assign cycle_duty = cycle_duty_reg;  // 输出锁存后的�??
assign measurement_valid = div_valid;     // 有效信号仍为单周�??

// ila_0 your_instance_name (
// 	.clk(sys_clk), // input wire clk


// 	.probe0(pulse_width_count), // input wire [29:0]  probe0  
// 	.probe1(cycle_width_count), // input wire [29:0]  probe1 
// 	.probe2(cycle_duty_reg), // input wire [29:0]  probe2 
// 	.probe3(quotient), // input wire [29:0]  probe3 
// 	.probe4(pulse_width_count_reg), // input wire [29:0]  probe4 
// 	.probe5(div_valid_reg), // input wire [0:0]  probe5
// 	.probe6(en_reg), // input wire [0:0]  probe6 
// 	.probe7(div_valid), // input wire [0:0]  probe7
// 	.probe8(pulse_count_valid), // input wire [0:0]  probe8 
// 	.probe9(cycle_count_valid) // input wire [0:0]  probe9
// );
endmodule