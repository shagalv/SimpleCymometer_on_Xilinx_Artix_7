module entire_cycle_measurer (
    input wire sys_clk,        // 系统时钟 (100MHz)
    input wire sys_rst_n,      // 异步复位，低电平有效
    input wire pulse_in,       // 待测脉冲输入
    output reg [29:0] cycle_count, // 测量到的周期时钟数
    output reg valid           // 测量完成标志，高电平有效一个时钟周期
);

    reg pulse_in_dly;          // 用于边沿检测的延迟寄存器
    reg measuring;             // 测量标志位
    reg [29:0] counter;        // 周期计数器
    
    // 边沿检测逻辑：通过延迟一拍来检测上升沿
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n)
            pulse_in_dly <= 1'b0;
        else
            pulse_in_dly <= pulse_in;
    end

    wire pulse_rise = (!pulse_in_dly) & pulse_in; // 上升沿检测

    // 测量状态机与控制逻辑
    always @(posedge sys_clk or negedge sys_rst_n) begin
        if (!sys_rst_n) begin
            measuring <= 1'b0;
            counter <= 30'd0;
            cycle_count <= 30'd0;
            valid <= 1'b0;
        end else begin
            valid <= 1'b0; // 默认valid为0，只在一个周期内有效
            
            if (pulse_rise) begin
                if (measuring) begin
                    // 完成一个周期测量之后，将计数值存入计数器中
                    cycle_count <= counter;
                    valid <= 1'b1;
                end
                // 开始/重新开始计数
                measuring <= 1'b1;
                counter <= 30'd1;
            end else if (measuring) begin
                // 测量中且未遇到上升沿，计数器递增
                counter <= counter + 1'b1;
            end
        end
    end

endmodule