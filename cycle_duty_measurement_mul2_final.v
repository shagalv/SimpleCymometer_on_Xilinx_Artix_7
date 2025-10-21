module cycle_duty_measurement#(
    parameter DATAWIDTH = 8'd30 
)(
    input wire sys_clk,
    input wire sys_rst_n,
    input wire clk_fx,           // 待测脉冲输入
    output wire [29:0] cycle_duty, // 占空�???
    output wire measurement_valid      // 测量有效信号
);
// 内部信号
wire [29:0] pulse_width_count;
wire [29:0] cycle_width_count;
wire [29:0] pulse_width_count_reg;
wire pulse_count_valid;
wire cycle_count_valid;

wire div_ready;
wire div_valid;
wire [29:0] quotient;
wire [29:0] remainder;

reg en_reg;
reg [29:0] cycle_duty_reg;
reg measurement_valid_reg;

reg [29:0] dividend_reg;
reg [29:0] divisor_reg;

assign pulse_width_count_reg=pulse_width_count*100;

pulse_width_counter counter_inst (
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .pulse_in(clk_fx),
    .width_count(pulse_width_count),
    .valid(pulse_count_valid)
);

entire_cycle_measurer cycle_measurer(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .pulse_in(clk_fx),
    .cycle_count(cycle_width_count),
    .valid(cycle_count_valid)
);

reg div_valid_reg;//除法器输出的使能信号比计算结果输出早�?????个周期导致数据没法导入oled显示程序
always @(posedge sys_clk or negedge sys_rst_n) begin
    if (!sys_rst_n) begin
        div_valid_reg <= 0;  //复位
    end
    else begin
        div_valid_reg<=div_valid;
    end
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        en_reg<=0;
    end
    else begin
        en_reg = cycle_count_valid;
    end
end

always @(posedge sys_clk or negedge sys_rst_n) begin
    if(!sys_rst_n) begin
        dividend_reg<=0;
        divisor_reg<=0;
    end
    else begin
    if(pulse_count_valid)begin
        dividend_reg<=pulse_width_count*100;
    end else if(cycle_count_valid)begin
        divisor_reg<=cycle_width_count;
    end
    else begin
        dividend_reg<=dividend_reg;
        divisor_reg<=divisor_reg;
        end
    end
end


//调用除法器将两个计数值相除即可得到结�??? 
div_fsm #(
   .DATAWIDTH(DATAWIDTH)  // 使用32位位�??????
) div_inst (
   .clk(sys_clk),
   .rst_n(sys_rst_n),
   .en(en_reg),           // 当计数完成时启动除法
   .dividend(dividend_reg),     // 被除�?????? = 计数�??????
   .divisor(divisor_reg),     // 除数 = 时钟频率（MHz�??????
   .ready(div_ready),
   .quotient(quotient),        // �?????? = 脉宽的整数部分（μs�??????
   .remainder(remainder),      // 余数 = 小数部分的基�??????
   .vld_out(div_valid)         // 除法完成信号
);

always @(posedge sys_clk or negedge sys_rst_n) begin
   if (!sys_rst_n) begin
       cycle_duty_reg <= 30'd0;  // 澶嶄綅鏃舵竻闆�
   end
   else if (div_valid_reg) begin      // 褰撻櫎娉曠粨鏋滄湁鏁堟椂鏇存柊閿佸瓨鍊�
       cycle_duty_reg <= quotient + 30'd1;
   end
end

// 输出分配
assign cycle_duty = cycle_duty_reg;  // 输出锁存后的�?
assign measurement_valid = div_valid;     // 有效信号仍为单周�?

endmodule