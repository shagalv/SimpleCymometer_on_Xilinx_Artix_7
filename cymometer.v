module cymometer#(
    parameter CNT_GATE_MAX = 28'd75_000_000, //测频周期事件为1.5s
    parameter CNT_TIME_MAX = 28'd100_000_000,//清零事件为2s
    parameter CNT_GATE_LOW = 28'd12_500_000,//闸门为低的时间为0.25s
    parameter CLK_FS_FREQ = 28'd100_000_000
)(
    input sys_clk,  //系统时钟，50MHz
    input clk_fs,   //基准时钟
    input sys_rst_n,//系统复位信号
    input clk_fx,   //被测时钟信号

    output reg[29:0] data_fx,//被测时钟频率值

    input ready,
    input[56:0] quotient, //商
    input[56:0] remainder,//余数
    input vld_out,  //值有效信号 

    output reg[56:0] dividend,  //输出被除数
    output reg[56:0] divisor,   //输出除数
    output reg en               //输出除法器使能信号
);

localparam TIME = 10'd150;      //设置数据的稳定时间

reg         gate_sclk;
reg[27:0]   cnt_gate_fs;
reg         gate_fx;
reg         gate_fx_d0;//打四拍寄存器
reg         gate_fx_d1;
reg         gate_fx_d2;
reg         gate_fx_d3;
reg         gate_fs;
reg         gate_fs_d0;
reg         gate_fs_d1;
reg[29:0]   cnt_fx;
reg[29:0]   cnt_fx_reg;
reg[29:0]   cnt_fs;
reg[29:0]   cnt_fs_reg;
reg[29:0]   cnt_fs_reg_reg;
reg         calc_flag;
reg[56:0]   numer;
reg         fx_flag;
reg[56:0]   numer_reg;
reg[27:0]   cnt_dely;
reg         flag_dely;

wire        gate_fx_pose;//上升沿
wire        gate_fx_nege;//下降沿
wire        gate_fs_nege;//下降沿

/*
***************main code**************
*/

//计算公式 CLK_FX_FREQ = cnt_fx * CLK_FS_FREQ / cnt_fs
assign gate_fx_pose = ((gate_fx) && (!gate_fx_d3))? 1'b1 : 1'b0;//打四拍的上升沿检测
assign gate_fx_nege = ((!gate_fx_d2) && gate_fx_d3)? 1'b1 : 1'b0;//待测信号 下降沿
assign gate_fs_nege = ((!gate_fs_d0) && gate_fs_d1)? 1'b1 : 1'b0;//基准信号 下降沿

//产生软件闸门时间计数器
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n) 
        cnt_gate_fs <= 28'd0;
    else if(cnt_gate_fs == CNT_GATE_MAX  + CNT_GATE_LOW - 1'd1)//***
        cnt_gate_fs <= 28'd0;
    else 
        cnt_gate_fs <= cnt_gate_fs + 1'd1;
end

//产生软件闸门 gate_sclk
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        gate_sclk <= 1'd0;
    else if(cnt_gate_fs == CNT_GATE_LOW - 1'd1)//低电平时间为CNT_GATE_LOW
        gate_sclk <= 1'd1;
    else if(cnt_gate_fs == CNT_GATE_MAX + CNT_GATE_LOW - 1'd1) //***高电平时间为CNT_GATE_MAX
        gate_sclk <= 1'd0;
    else 
        gate_sclk <= gate_sclk;
end

//将软件闸门 同步到 被测时钟下，得到实际闸门，并进行打拍处理获取上升沿和下降沿
always@(posedge clk_fx or negedge sys_rst_n)
begin
    if(sys_rst_n)
    begin
        gate_fx <= 1'b0;
        gate_fx_d0 <= 1'b0;
        gate_fx_d1 <= 1'b0;
        gate_fx_d2 <= 1'b0;
        gate_fx_d3 <= 1'b0;
    end
    else
    begin//打拍处理
        gate_fx <= gate_sclk;
        gate_fx_d0 <= gate_fx;
        gate_fx_d1 <= gate_fx_d0;
        gate_fx_d2 <= gate_fx_d1;
        gate_fx_d3 <= gate_fx_d2;
    end
end

//获取实际闸门的下降沿 在基准时钟下获得下降沿
always@(posedge clk_fs or negedge sys_rst_n)
begin
    if(~sys_rst_n)
    begin
        gate_fs <= 1'b0;
        gate_fs_d0 <= 1'b0;
        gate_fs_d1 <= 1'b0;
    end
    else 
    begin
        
        gate_fs <= gate_fx_d2;
        gate_fs_d0 <= gate_fs;
        gate_fs_d1 <= gate_fs_d0;
    end
end

//在实际闸门下，分别计算时钟周期数cnt_fx（被测时钟）cnt_fs（基准时钟）
//被测时钟下的周期个数
always@(posedge clk_fx or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        cnt_fx <= 30'd0;
    else if(gate_fx_d2)
        cnt_fx <= cnt_fx + 1'd1; //fx下的闸门时间内，持续计数
    else if(gate_fx_nege)
        cnt_fx <= 30'd0;
    else 
        cnt_fx <= cnt_fx;
end

//在下降沿，将被测时钟的 时钟周期数 进行缓存
always@(posedge clk_fx or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        cnt_fs_reg <= 30'd0;
    else if(gate_fx_nege)
        cnt_fx_reg <= cnt_fx;
    else 
        cnt_fx_reg <= cnt_fx_reg;
end

//基准时钟下的周期个数 cnt_fs
always@(posedge clk_fs or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        cnt_fs <= 30'd0;
    else if(gate_fx_d2) //gate_fs_d1
        cnt_fs <= cnt_fs + 30'd1;
    else if(gate_fs_nege)
        cnt_fs <= 30'd0;
    else 
        cnt_fs <= cnt_fs;
end

//在下降沿，将基准时钟的时钟周期进行缓存
always@(posedge clk_fs or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        cnt_fs_reg <= 30'd0;
    else if(gate_fs_nege)
        cnt_fs_reg <= cnt_fs;  //没问题，同步并行操作，存入值非0
    else if(gate_fs_nege)
        cnt_fs_reg <= cnt_fs_reg;
end

//CLK_FX_FREQ = cnt_fx * CLK_FS_FREQ / cnt_fs
//先计算得到分子，cnt_fx * CLK_FS_FREQ
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        numer <= 57'd0;
    else if(cnt_gate_fs == CNT_GATE_MAX)//基准时钟计数达到最大值
        numer <= cnt_fx_reg * CLK_FS_FREQ;
    else numer <= numer;
end

//打一拍 对计算得到的值 numer_reg（分子）进行同步并寄存
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(sys_rst_n)
        numer_reg <= 57'd0;
    else if(cnt_gate_fs == (CNT_GATE_MAX + (CNT_GATE_LOW / 2) - TIME ))
        numer_reg <= numer;
    else 
        numer_reg <= numer_reg;
end

//打一拍 对计算得到的值numer_reg（分子）进行同步并寄存
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        numer_reg <= 57'd0;
    else if(cnt_gate_fs == (CNT_GATE_MAX + (CNT_MAX_LOW / 2) - TIME))
        numer_reg <= numer;
    else 
        numer_reg <= numer_reg;
end

//打一拍，对计算得到的值 cnt_fs_reg_reg（分母）进行同步寄存
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        cnt_fs_reg_reg <= 30'd0;
    else if(cnt_gate_fs == ((CNT_GATE_MAX) + (CNT_GATE_LOW / 2) - TIME))
        cnt_fs_reg_reg <= cnt_fs_reg;
    else 
        cnt_fs_reg_reg <= cnt_fs_reg_reg; 
end

//产生计算标志信号calc_flag
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        calc_flag <= 1'd0;
    else if(cnt_gate_fs ==(CNT_GATE_MAX + CNT_GATE_LOW / 2 - 2))
        calc_flag <= 1'b1;
    else if(cnt_gate_fs == (CNT_GATE_MAX - CNT_GATE_LOW / 2 - 1))
        calc_flag <= 1'b0;
    else 
        calc_flag <= calc_flag;
end

//被测时钟启动是否为零
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        fx_flag <= 1'b0;
    else if(clk_fx && gate_fx)
        fx_flag <= 1'b1;
    else 
        fx_flag <= fx_flag;
end

//闸门时间计数
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        cnt_dely <= 28'd0;
    else if(gate_fx_pose)
        cnt_dely <= 28'd0;
    else if(cnt_dely == CNT_TIME_MAX)
        cnt_dely <= CNT_TIME_MAX;
    else 
        cnt_dely <= cnt_dely + 1'd1;
end

//上升沿到来后，拉高一段时间
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        flag_dely <= 1'd0;
    else if(cnt_dely >= CNT_TIME_MAX)
        flag_dely <= 1'b1;
    else if(cnt_dely < CNT_TIME_MAX)
        flag_dely <= 1'b0;
    else 
        flag_dely <= flag_dely;
end

//获得被测信号的频率值
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        data_fx <= 30'd0;
    else if(~fx_flag) //被测时钟未启动
        data_fx <= 30'd0;
    else if(flag_dely) //闸门时间已到 被测时钟被拔掉
        data_fx <= 30'd0;
    else if(vld_out)
        data_fx <= quotient;
    else 
        data_fx <= data_fx;
end

always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
        en <= 1'b0;
    else if(cnt_gate_fs == (CNT_GATE_MAX + CNT_GATE_LOW / 2))
        en <= 1'b1;
    else if(vld_out)
        en <= 1'b0;//在输出有效时，使能为0
    else 
        en <= en;
end

always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
    begin
        dividend <= 57'd0;
        divisor <= 57'd1;
    end
    else if(calc_flag)
    begin
        dividend <= numer_reg;
        divisor <= cnt_fs_reg_reg;
    end
    else 
    begin
        dividend <= dividend;
        divisor <= devisor;
    end
end
endmodule