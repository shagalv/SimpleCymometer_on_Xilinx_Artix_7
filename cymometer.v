//时间信号说明：在闸门总时间CNT_GATE_MAX的前后，各有一段闸门低电平时间，用于异步信号时钟的传递 和 清零
module cymometer#(
    parameter CLK_FS_FREQ = 30'd100_000_000, //基准时钟频率
    parameter CNT_GATE_LOW = 30'd12_500_000  //闸门低电平时间
)(
    input sys_clk,  //系统时钟 50MHz
    input clk_fs,   //基准时钟
    input sys_rst_n,//系统复位信号

    input[2:0] Pattern,  //测量模式选择，共有三种

    input clk_fx_1,   //被测时钟信号
    input clk_self, //1MHz的自校验时钟

    input[29:0] CNT_GATE_MAX, //闸门总时间，包括高电平，低电平
    input[29:0] CNT_TIME_MAX, //断开待测信号后的清零时间，断开待测信号后，一旦超过该时间，输出清零
    input renew,//保存闸门时间，并刷新显示

    output reg[29:0] data_fx_result,//被测时钟频率结果
    output reg[29:0] cycle_fx,//待测时钟的周期，以多少个0.01us为单位（基准时钟）

    input ready,
    input[58:0] quotient, //商
    input[58:0] remainder,//余数
    input vld_out,  //值有效信号

    output reg[58:0] dividend,  //输出被除数
    output reg[58:0] divisor,   //输出除数
    output reg en,               //输出除法器使能信号

    //Debug
    output[4:1] led
    // output reg[29:0] cnt_gate_fs //Debug用，将引脚引出
);

localparam TIME = 10'd150;      //设置数据的稳定时3ms

reg         gate_sclk; //软件闸门
reg[29:0]   cnt_gate_fs;//软件闸门时间计数
reg         gate_fx;
reg         gate_fx_d0; //用于被测时钟同步的 打四拍寄存器，产生实际闸门时间
reg         gate_fx_d1;
reg         gate_fx_d2;
reg         gate_fx_d3;
reg         gate_fs;    //在实际闸门的下降沿，基准时钟同时下降
reg         gate_fs_d0;
reg         gate_fs_d1;
reg[29:0]   cnt_fx;     //被测信号计数器
reg[29:0]   cnt_fx_reg; //被测信号计数器寄存
reg[29:0]   cnt_fs;     //基准时钟计数器
reg[29:0]   cnt_fs_reg; //基准时钟计数器寄存，延迟1拍
reg[29:0]   cnt_fs_reg_reg;//基准时钟计数器寄存，到此，延迟2拍
reg         calc_flag;
reg[58:0]   numer;      //分子部分，由于需要先进行乘法，此处差1个时钟周期
reg         fx_flag;    //被测时钟为0标志信号
reg[58:0]   numer_reg;  //对numer进行1个时钟周期的延迟，到此，从cnt_fx稳定产生一共延迟2个系统时钟周期，
                        //因此，可以与cnt_fs_reg_reg一并送入除法器

//以下信号与测量无关，主要用于断开被测信号后的归零
reg[29:0]   cnt_dely;   //系统时钟下的闸门时间计数
reg         flag_dely;  //在最大时间以后，将使输出的被测信号频率值显示为0

//以下信号为最终的输出结果信号
reg[29:0]   data_fx;    //输出的被测信号频率
reg[29:0]   data_fx_reg;//被测信号频率寄存器，由于输出结果仅在很小一段时间，需要寄存器存储实现显示
reg[29:0]   cycle_fx_reg;//被测信号周期寄存器，同样用于显示

//以下信号为异步信号消除亚稳态设计
reg[2:0]    pattern_0;  
reg[2:0]    pattern_1;  

reg[29:0] CNT_GATE_MAX_0;
reg[29:0] CNT_GATE_MAX_1;

reg[29:0] CNT_TIME_MAX_0;
reg[29:0] CNT_TIME_MAX_1;

reg renew_0;
reg renew_1;
////////////////////////////////////
reg         vld_out_t;//vld_out比quotient快一拍，用来同步节拍
/////////////////////////////////////

wire        clk_fx;//实际的待测时钟，由pattern是否为自测模式而决定
wire        gate_fx_pose;//上升�?
wire        gate_fx_nege;//下降�?
wire        gate_fs_nege;//下降�?



//Debug专用
reg        cnt_gate_fs_reg;


/*
***************main code**************
*/

//计算公式 CLK_FX_FREQ = cnt_fx * CLK_FS_FREQ / cnt_fs
assign gate_fx_pose = ((gate_fx) && (!gate_fx_d3))? 1'b1 : 1'b0;//打四拍的上升沿检�?
assign gate_fx_nege = ((!gate_fx_d2) && gate_fx_d3)? 1'b1 : 1'b0;//待测信号 下降�?
assign gate_fs_nege = ((!gate_fs_d0) && gate_fs_d1)? 1'b1 : 1'b0;//基准信号 下降�?

assign clk_fx = ((pattern_1 == 3'd3)? clk_self : clk_fx_1);
//注意，这里可能会因为矩阵键盘的扫描存在一定的时间延迟，而导致clk_fx可能混合了两种信号 
 
//以下对四个来自key_pattern模块的输入信号进行打拍
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
    begin
        CNT_GATE_MAX_0 <= 30'd0;
        CNT_GATE_MAX_1 <= 30'd0;
    end
    else
    begin
        CNT_GATE_MAX_0 <= CNT_GATE_MAX;
        CNT_GATE_MAX_1 <= CNT_GATE_MAX_0;
    end
end

always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
    begin
        CNT_TIME_MAX_0 <= 30'd0;
        CNT_TIME_MAX_1 <= 30'd0;
    end
    else
    begin
        CNT_TIME_MAX_0 <= CNT_GATE_MAX;
        CNT_TIME_MAX_1 <= CNT_GATE_MAX_0;
    end
end

//对异步的pattern信号进行打拍处理
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
    begin
        pattern_0 <= 3'd0;
        pattern_1 <= 3'd0;
    end
    else
    begin
        pattern_0 <= Pattern;
        pattern_1 <= pattern_0;
    end
end

//对输入的 刷新信号renew 进行打拍处理
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
    begin
        renew_0 <= 3'd0;
        renew_1 <= 3'd0;
    end
    else
    begin
        renew_0 <= renew;
        renew_1 <= renew_0;
    end
end

//产生软件闸门时间计数
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n) 
        begin
            cnt_gate_fs <= 30'd0;
        end
    else if(cnt_gate_fs == CNT_GATE_MAX_1 - 1'd1)//***
        cnt_gate_fs <= 30'd0;
    else if(renew_1)
        cnt_gate_fs <= 30'd0;
    else 
        cnt_gate_fs <= cnt_gate_fs + 30'd1;
end

//产生软件闸门 gate_sclk
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        gate_sclk <= 1'd0;
    else if(cnt_gate_fs == CNT_GATE_LOW - 1'd1)//低电平时间为CNT_GATE_LOW
        gate_sclk <= 1'd1;
    else if(cnt_gate_fs == CNT_GATE_MAX_1 - CNT_GATE_LOW - 1'd1) //***高电平时间为CNT_GATE_MAX - 2*CNT_GATE_LOW
        gate_sclk <= 1'd0;
    else 
        gate_sclk <= gate_sclk;
end

//将软件闸门同步到被测时钟下，得到实际闸门，并进行打拍处理获取上升沿和下降
always@(posedge clk_fx or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
    begin
        gate_fx <= 1'b0;
        gate_fx_d0 <= 1'b0;
        gate_fx_d1 <= 1'b0;
        gate_fx_d2 <= 1'b0;
        gate_fx_d3 <= 1'b0;
    end
    begin//打拍处理
        gate_fx <= gate_sclk;
        gate_fx_d0 <= gate_fx;
        gate_fx_d1 <= gate_fx_d0;
        gate_fx_d2 <= gate_fx_d1;
        gate_fx_d3 <= gate_fx_d2;
    end
end

//获取实际闸门的下降沿 在基准时钟下获得下降
always@(posedge clk_fs or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
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
    if(~sys_rst_n || renew_1)
        cnt_fx <= 30'd0;
    else if(gate_fx_d2)
        cnt_fx <= cnt_fx + 30'd1; //fx下的闸门时间内，持续计数
    else if(gate_fx_nege)
        cnt_fx <= 30'd0;
    else 
        cnt_fx <= cnt_fx;
end

//在下降沿，将被测时钟�? 时钟周期�? 进行缓存
always@(posedge clk_fx or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        cnt_fx_reg <= 30'd0;
    else if(gate_fx_nege)
        cnt_fx_reg <= cnt_fx;
    else 
        cnt_fx_reg <= cnt_fx_reg;
end

//基准时钟下的周期个数 cnt_fs
always@(posedge clk_fs or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        cnt_fs <= 30'd0;
    else if(gate_fx_d2) //gate_fs_d1
        cnt_fs <= cnt_fs + 30'd1;
    else if(gate_fs_nege)
        cnt_fs <= 30'd0;
    else 
        cnt_fs <= cnt_fs;
end

//在下降沿，将基准时钟的时钟周期进行缓�?
always@(posedge clk_fs or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        cnt_fs_reg <= 30'd0;
    else if(gate_fs_nege)
        cnt_fs_reg <= cnt_fs;  //没问题，同步并行操作，存入�?�非0
    else
        cnt_fs_reg <= cnt_fs_reg;
end

//CLK_FX_FREQ = cnt_fx * CLK_FS_FREQ / cnt_fs
//先计算得到分子，cnt_fx * CLK_FS_FREQ
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        numer <= 59'd0;
    else if(cnt_gate_fs == CNT_GATE_MAX_1 - CNT_GATE_LOW + TIME)//基准时钟计数达到
        numer <= cnt_fx_reg * CLK_FS_FREQ;
    else numer <= numer;
end

//打一�? 对计算得到的�? numer_reg（分子）进行同步并寄�?
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        numer_reg <= 59'd0;
    else if(cnt_gate_fs == (CNT_GATE_MAX_1 - (CNT_GATE_LOW / 2) - TIME ))
        numer_reg <= numer;
    else 
        numer_reg <= numer_reg;
end

//打一拍，对计算得到的�? cnt_fs_reg_reg（分母）进行同步寄存
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        cnt_fs_reg_reg <= 30'd0;
    else if(cnt_gate_fs == ((CNT_GATE_MAX_1) - (CNT_GATE_LOW / 2) - TIME))
        cnt_fs_reg_reg <= cnt_fs_reg;
    else 
        cnt_fs_reg_reg <= cnt_fs_reg_reg; 
end

//产生计算标志信号calc_flag
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        calc_flag <= 1'd0;
    else if(cnt_gate_fs ==(CNT_GATE_MAX_1 - CNT_GATE_LOW / 2 - 2))
        calc_flag <= 1'b1;
    else if(cnt_gate_fs == (CNT_GATE_MAX_1 - CNT_GATE_LOW / 2 - 1))
        calc_flag <= 1'b0;
    else 
        calc_flag <= calc_flag;
end

//被测时钟启动是否为零
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        fx_flag <= 1'b0;
    else if(clk_fx && gate_fx)
        fx_flag <= 1'b1;
    else 
        fx_flag <= fx_flag;
end

//系统时钟下的闸门时间计数，在fx的上升沿，启动闸门
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        cnt_dely <= 30'd0;
    else if(gate_fx_pose)
        cnt_dely <= 30'd0;
    else if(cnt_dely == CNT_TIME_MAX_1)
        cnt_dely <= CNT_TIME_MAX_1;
    else 
        cnt_dely <= cnt_dely + 30'd1;
end

//上升沿到来后，拉高一段时�?//这段时间也就是闸门时间
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        flag_dely <= 1'd0;
    else if(cnt_dely >= CNT_TIME_MAX_1)
        flag_dely <= 1'b1;
    else if(cnt_dely < CNT_TIME_MAX_1)
        flag_dely <= 1'b0;
    else 
        flag_dely <= flag_dely;
end

//获得被测信号的频率�??
always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
    begin
        data_fx <= 30'd0;
        cycle_fx <= 30'd0;
    end
    else if(~fx_flag) //被测时钟未启�?
    begin
        data_fx <= 30'd0;
        cycle_fx <= 30'd0;
    end
    else if(flag_dely) //闸门时间已到 被测时钟被拔�?
    begin
        data_fx <= 30'd0;
        cycle_fx <= 30'd0;
    end
    else if(vld_out_t)
    begin
        if(pattern_1 == 3'd1 || pattern_1 == 3'd3)//测量频率/自校验，输出频率值
        begin
            data_fx <= quotient / 2;
            cycle_fx <= 30'd0;
        end
        else
        begin
            data_fx <= 30'd0;
            cycle_fx <= quotient;
        end
    end
    else 
    begin   
        data_fx <= data_fx;
        cycle_fx <= cycle_fx;
    end
end

always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
    begin    
        en <= 1'b0;
    end
    else if(cnt_gate_fs == (CNT_GATE_MAX_1 - CNT_GATE_LOW / 2))
    begin
        en <= 1'b1;
    end
    else if(vld_out_t)
        en <= 1'b0;//在输出有效时，使能为0
    else 
        en <= 1'b0;//
end

always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
    begin
        dividend <= 59'd0;
        divisor <= 59'd1;
    end
    else if(calc_flag)
    begin
        if(pattern_1 == 3'd1 || pattern_1 == 3'd3)
        begin
            dividend <= numer_reg;
            divisor <= cnt_fs_reg_reg;
        end
        else if(pattern_1 == 3'd2)//周期测量，也就是将分子分母调换，再乘以基准信号的周期
        begin
            dividend <= cnt_fs_reg_reg * 1_000_000_000; //周期以ns为单位
            divisor <= numer_reg;
        end
    end
    else 
    begin
        dividend <= dividend;
        divisor <= divisor;
    end
end

always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1)
        vld_out_t <= 1'd0;
    else if(vld_out)
        vld_out_t <= vld_out;
    else 
        vld_out_t <= 1'd0;
end

always@(data_fx)
begin
    if(data_fx) data_fx_reg <= data_fx;
end

always@(cycle_fx)
begin
    if(cycle_fx) cycle_fx_reg <= cycle_fx;
end

always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n || renew_1) data_fx_result <= 30'd4023;
    else
    begin
        if(pattern_1 == 3'd1 || pattern_1 == 3'd3) data_fx_result <= data_fx_reg;
        else if(pattern_1 == 3'd2 ) data_fx_result <= cycle_fx_reg;
        else data_fx_result <= 30'd114514; //正在调节闸门时间
    end 
end

assign led[1] = (data_fx_reg != 30'd0);
assign led[2] = (data_fx_reg == 30'd0);
assign led[3] = (CNT_GATE_MAX_1 == 30'd500_000_000);
assign led[4] = cnt_gate_fs_reg;
endmodule