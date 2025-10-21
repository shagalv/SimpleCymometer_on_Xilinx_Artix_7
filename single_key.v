module single_key(
    input sw4,// N15 主板的四个key，用来切换 频率计（周期）/ 脉冲/占空比测量
    input sys_clk,
    input sys_rst_n,
    output reg[1:0] choose //输出1，频率计，输出2，脉冲计
);

always@(*)
begin
    if(sw4 == 1'b1) 
        choose <= 2'd1;//向上拨 频率计
    else
        choose <= 2'd2;//向下 脉冲
end


endmodule