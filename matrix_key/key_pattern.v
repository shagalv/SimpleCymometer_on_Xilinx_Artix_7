/*模块信号说明：
输入：系统复位时钟信号，系统时钟
输出：系统闸门时间，测量模式

模块功能说明：
测量开始前，先复位，复位后默认闸门时间1s，测量模式为频率测量
按下按键4，可以选择闸门时间1-10s，按照1s时间递增
按下按键1-3，可以选择测量模式为：频率，周期，脉冲，对应的led灯光也将变化
*/
module key_pattern(
    input sys_clk,  //输入时钟信号,50MHz
    input sys_rst_n,//输入系统复位信号
    input[3:0] row,//键盘扫描行和列
    output[3:0] col,
    output reg[29:0] key_gate_time,//输出闸门总时间选择，1-10s可调
    output reg[29:0] key_time_max,//断开待测信号后的刷新时间
    output[2:0] pattern,
    output[7:0] seg_sel, //输出的数码管信号,总是保持数码管1亮
    output reg[7:0] seg_led, //输出的数码管数字
    output reg renew//保存当前设置的闸门时间，并刷新显示值
);

localparam RESTART = 3'd0;
localparam FREQ = 3'd1;
localparam PERIOD = 3'd2;
localparam SELF = 3'd3;
localparam TIME_VARY = 3'd4;


localparam SKIP = 30'd50_000_000;//步进 间隔为1s
localparam CNT_GATE_MAX = 30'd50_000_000;//总初始时长为1s，高电平时间为0.5s
localparam CNT_GATE_LOW = 30'd12_500_000;
localparam CNT_TIME_MAX = 30'd60_000_000;//断开信号后的刷新时间，初始为1.2s


reg [2:0] key_state;
reg [2:0] previous_key_state ;//前一个key_state状态，用来进行restart，影子寄存器

reg key_valid_0;//用于沿判断的寄存器
reg key_valid_1;
reg key_valid_2;
reg key_valid_3;

wire key_pose;
wire key_valid;//输出键值有效信号
wire [3:0] key_value;//输出键值




key44 u_key44(
    .clk(sys_clk),
    .reset(~sys_rst_n),
    .row(row),
    .col(col),
    .key_valid(key_valid),
    .key_value(key_value)
);


always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n)
    begin
        key_valid_0 <= 1'b0;
        key_valid_1 <= 1'b0;
        key_valid_2 <= 1'b0;
        key_valid_3 <= 1'b0;
    end
    else
    begin
        key_valid_0 <= key_valid;
        key_valid_1 <= key_valid_0;
        key_valid_2 <= key_valid_1;
        key_valid_3 <= key_valid_2;
    end
end

assign key_pose = ({key_valid_0,key_valid_1,key_valid_2,key_valid_3} == {4'b1110});

always@(posedge sys_clk or negedge sys_rst_n)
begin
    if(~sys_rst_n) 
    begin
        key_gate_time <= CNT_GATE_MAX;//复位后闸门
        key_state <= FREQ;//复位后，默认为频率测量模式
        key_time_max <= CNT_TIME_MAX;
        renew <= 1'b0;
    end
    else
    begin
        if(key_pose)//有键按下,上升沿检测
        begin
            case (key_value)
                4'd4://按键4，连续可调闸门时间
                begin
                    key_state <= TIME_VARY;
                    if(key_value != TIME_VARY) previous_key_state <= key_state; //存储上一个状态,注意，这里如果没有条件判断，那么调节完阈值时间之后，再按刷新就会出错
                    renew <= 1'b0;
                    if(key_gate_time < 30'd500_000_000)
                        begin
                            key_gate_time <= key_gate_time + SKIP;
                            key_time_max <= key_time_max + SKIP;
                        end
                    else
                        begin
                            key_gate_time <= 30'd50_000_000;
                            key_time_max <= 30'd60_000_000;
                        end

                end
                4'd1: begin
                    key_state <= FREQ;
                    previous_key_state <= key_state;
                    renew <= 1'b0;
                end
                4'd2: begin
                    key_state <= PERIOD;
                    previous_key_state <= key_state;
                    renew <= 1'b0;
                end
                4'd3: begin
                    key_state <= SELF;
                    previous_key_state <= key_state;
                    renew <= 1'b0;
                end
                4'd0: 
                begin
                    key_state <= previous_key_state;
                    previous_key_state <= FREQ;//默认将previous_state 这个”影子“寄存器的值设置为FREQ
                    renew <= 1'b1;
                end
                default://其他按键不响应
                begin
                    key_gate_time <= key_gate_time;
                    key_state <= key_state;
                    key_time_max <= key_time_max;
                    renew <= 1'b0;
                end
            endcase
        end
        else //没有按键按下，不响应
        begin
            key_gate_time <= key_gate_time;
            key_state <= key_state;
            key_time_max <= key_time_max;
            renew <= 1'b0;
        end
    end
end

always@(*)
begin
    if(key_state == RESTART) seg_led[6:0] = 7'b1000_000;//0:重启（应该立马跳转到其他数字）
    else if(key_state == FREQ) seg_led[6:0] = 7'b1111001;//1 频率
    else if(key_state == PERIOD) seg_led[6:0] = 7'b0100100;//2 周期
    else if(key_state == SELF) seg_led[6:0] = 7'b0110000;//3 自校验
    else if(key_state == TIME_VARY) seg_led[6:0] = 7'b0011001;//4 连续调节闸门时间
    else seg_led[6:0] = 7'b0001110;//其他情况显示F
end

assign pattern = key_state;
assign seg_sel = 8'b0111_1111;//总是第一个数码管亮

endmodule