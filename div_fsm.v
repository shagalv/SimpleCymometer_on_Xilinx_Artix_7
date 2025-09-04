//除法器模块//Version 2.0
module div_fsm#(
    parameter DATAWIDTH = 8   //设置除数和被除数的位宽都是8位
)(
input clk,
input rst_n,
input en,                           //除法器使能信号
input [DATAWIDTH - 1:0] dividend,   //输入 被除数
input [DATAWIDTH - 1:0] divisor,    //输入 除数
output ready,
output [DATAWIDTH - 1:0] quotient,  //输出的 商
output [DATAWIDTH - 1:0] remainder, //输出的 余数
output vld_out                      //输出 有效信号
);

//定义状态机状态
localparam IDLE =   2'b00;
localparam SUB =    2'b01;
localparam SHIFT =  2'b10;
localparam DONE =   2'b11;

//定义中间数据寄存器/寄存器，最终绑定至输出接口
reg[DATAWIDTH * 2 - 1:0] dividend_e;//中间寄存器，根据除法器原理，定义的位宽是输入数据位宽的两倍
reg[DATAWIDTH * 2 - 1:0] divisor_e; 

reg[DATAWIDTH - 1:0] quotient_e;//商寄存器
reg[DATAWIDTH - 1:0] remainder_e;//余数寄存器

reg[1:0] state;
reg[1:0] next_state;

reg[DATAWIDTH - 1:0] count;//统计移位的位数


//FSM 状态转移
always@(posedge clk or negedge rst_n)
begin
    if(~rst_n) state <= IDLE;
    else state <= next_state;
end

always@(*)//状态转移逻辑
begin
    next_state = 2'bx;
    if(state == IDLE)
    begin
        if(en) next_state = SHIFT;
        else next_state = IDLE;
    end
    else if(state == SUB) next_state = (count == DATAWIDTH) ? DONE : SHIFT;
    else if(state == SHIFT)
    begin
        if(divisor_e > dividend_e)
        begin
            next_state = SHIFT; //仍然不够除，继续移位
        end
        else next_state = SUB;  //divisor_e <= dividend_e 转至减法
    end
    else  next_state =IDLE;//state == DONE，next_state = IDLE
end

//根据当前所处的状态，对被除数和除数进行 位操作/减法操作
always@(posedge clk or negedge rst_n)
begin
    if(~rst_n)
    begin
        dividend_e <= 1'b0;
        divisor_e <= 1'b0;
        quotient_e <= 1'b0;
        remainder_e <= 1'b0;
        count <= 1'b0;
    end
    else if(state == IDLE)//对除数进行低位扩展（变大）。对被除数进行高位扩展（不变）
    begin
        dividend_e <= {{DATAWIDTH{1'b0}},dividend};//被除数高位拓展
        divisor_e <= {divisor,{DATAWIDTH{1'b0}}};//除数低位拓展
        remainder_e <= {(DATAWIDTH*2 - 1){1'd0}};
        quotient_e <= {(DATAWIDTH*2 - 1){1'd0}};
        count <= 0;
    end
    else if(state == SHIFT)
    begin
        if(count < DATAWIDTH)
        begin
            dividend_e <= dividend_e << 1; //被除数 左移1位
            count <= count + 1;
        end
        // else if(count == DATAWIDTH)
        // begin
        //     dividend_e <= dividend_e - divisor_e + 1;
        // end
    end
    else if(state == SUB)
    begin
        dividend_e <= dividend_e - divisor_e + 1;
    end
    else//state == DONE
    begin
        remainder_e <= dividend_e[DATAWIDTH * 2 - 1 : DATAWIDTH];
        quotient_e <= dividend_e[DATAWIDTH - 1 : 0];
    end
end

assign quotient = quotient_e;
assign remainder = remainder_e;
assign ready = (state == IDLE);
assign vld_out = (state == DONE);

endmodule