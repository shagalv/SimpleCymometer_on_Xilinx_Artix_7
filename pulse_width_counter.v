module pulse_width_counter (
    input wire sys_clk,        // 系统时钟 (100MHz)
    input wire sys_rst_n,      // 异步复位，低电平有效
    input wire pulse_in,   // 待测脉冲输入
    output reg [31:0] width_count, // 测量到的时钟周期数,在基准信号的上升沿处开始计数，最后输出计数值
    output reg valid       // 测量完成标志，高电平有效一个时钟周期
);

    reg pulse_in_dly;      // 用于边沿检测的延迟寄存器
    reg measuring;         // 测量标志位
    // 边沿检测逻辑：通过延迟一拍来检测上升/下降沿
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            pulse_in_dly <= 1'b0;
        else
            pulse_in_dly <= pulse_in;//系统时钟的上升沿来到时将此时的输入信号值放入存储器
                                    //用于后续判断是否是上升沿
    end

    wire pulse_rise = (!pulse_in_dly) & pulse_in; // 上升沿检测
    wire pulse_fall = pulse_in_dly & (!pulse_in); // 下降沿检测

    // 测量状态机与控制逻辑
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            measuring <= 1'b0;
            width_count <= 32'd0;
            valid <= 1'b0;
        end else begin
            valid <= 1'b0; // 默认valid为0，只在一个周期内有效
            if (pulse_rise) begin
                // 检测到上升沿，开始测量，计数器清零
                measuring <= 1'b1;
                width_count <= 32'd0;
            end else if (measuring) begin
                if (pulse_fall) begin
                    // 检测到下降沿，停止测量，产生有效信号
                    measuring <= 1'b0;
                    valid <= 1'b1;
                end else begin
                    // 测量中且未遇到下降沿，计数器递增
                    width_count <= width_count + 1'b1;
                end
            end
        end
    end

endmodule