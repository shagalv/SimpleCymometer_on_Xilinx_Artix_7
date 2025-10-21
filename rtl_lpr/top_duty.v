module top_duty(
    input sys_clk,
    input sys_rst_n,
    input clk_fx,//y*****应该只需要一个待测信号的输入，完成脉冲以及占空比的测量

    // ----- 外设的信号 -----
    input[3:0] row,

    //OLED显示驱动
    output oled_dat,
    output oled_rst,
    output oled_dcn,
    output oled_clk,

    output[3:0] col,
    output[7:0] seg_sel,
    output[7:0] seg_led,
    output reg[4:1] led
);

localparam CLK_FREQ_MHZ = 50;
localparam DATAWIDTH = 8'd30;

wire[31:0]  duty_cycle;
wire        valid;//输出占空比测量完成标志
// wire        clk_fx;//感觉顶层需要一个clk_fx的信号,这个应该在接口处
wire[2:0]   pattern;
reg[2:0]   unit;//只能是6或者7；6显示us，7显示%；根据pattern来赋值

wire        measurement_valid_cycle_duty;
wire        measurement_valid_pulse_width;
wire[29:0]  pulse_width_us;
wire[29:0]  cycle_duty;
reg[29:0]  data_fx;//最终输出的待测信号数据

//数据选通data_fx; pattern转unit是实现oled的单位显示
always@(*)
begin
    if(pattern == 3'd1)
    begin
        unit = 3'd7;//显示%
        data_fx = cycle_duty;//按键1，显示占空比
        led = 4'b1111;//全亮表示占空比模式
    end
    else if(pattern == 3'd2)
    begin
        unit = 3'd6;//us
        data_fx = pulse_width_us;//按键2，显示脉冲宽度
        led = 4'b1110;//最后一个灯灭表示 脉冲宽度
    end
    else 
    begin
        unit = 3'd7;//输入按键不合法，默认显示%
        data_fx = 30'd114514;//其他按键，显示114514，表示按键无效
        led = 4'b0000;//全灭表示 按键无效
    end
end



cycle_duty_measurement u2_cycle_duty_measurement(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .clk_fx(clk_fx),
    .cycle_duty(cycle_duty),  //输出 32位数据
    .measurement_valid(measurement_valid_cycle_duty)        //输出 占空比测量完成标志
);

pulse_width_measurement#(
  .DATAWIDTH(DATAWIDTH)  
) u2_pulse_width_measurement(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .clk_fx(clk_fx),
    // .en(en),
    .pulse_width_us(pulse_width_us),
    .measurement_valid(measurement_valid_pulse_width) //输出 测量有效信号
);


key_pattern u2_key_pattern(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .col(col),
    // .key_gate_time(CNT_GATE_MAX),
    // .key_time_max(CNT_TIME_MAX),
    .pattern(pattern),//输出pattern
    .row(row),
    .seg_sel(seg_sel),
    .seg_led(seg_led)
    // .renew(renew)
);

top_oled u2_top_oled(
    .sys_clk(sys_clk),
    .sys_rst_n(sys_rst_n),
    .data_fx(data_fx),
    .oled_rst(oled_rst),
    .oled_dcn(oled_dcn),
    .oled_clk(oled_clk),
    .oled_dat(oled_dat),
    .pattern(unit)      //unit == 6显示us，pattern == 7显示%
);

endmodule