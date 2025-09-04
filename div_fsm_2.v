//除法器模块
//?????
module div_fsm#(
    parameter DATAWIDTH = 8   //?????????????8?
)(
    input clk,
    input rst_n,
    input en,                           //???????
    input [DATAWIDTH - 1:0] dividend,   //?? ???
    input [DATAWIDTH - 1:0] divisor,    //?? ??
    output ready,
    output [DATAWIDTH - 1:0] quotient,  //??? ?
    output [DATAWIDTH - 1:0] remainder, //??? ??
    output vld_out                      //?? ????
);

//???????
localparam IDLE = 2'b00;
localparam SUB  = 2'b01;
localparam SHIFT = 2'b10;
localparam DONE = 2'b11;

//?????????
reg [DATAWIDTH*2-1:0] dividend_e; //???????
reg [DATAWIDTH*2-1:0] divisor_e;  //??????
reg [DATAWIDTH-1:0] quotient_e;   //????
reg [DATAWIDTH-1:0] remainder_e;  //?????
reg [1:0] state;
reg [1:0] next_state;
reg [DATAWIDTH-1:0] count;        //???????

//FSM ????
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) 
        state <= IDLE;
    else 
        state <= next_state;
end

always @(*) begin //??????
    case (state)
        IDLE: next_state = en ? SHIFT : IDLE;
        SHIFT: begin
            if (count == DATAWIDTH) 
                next_state = DONE;
            else if (divisor_e > dividend_e)
                next_state = SHIFT; //??????????
            else 
                next_state = SUB;   //divisor_e <= dividend_e ????
        end
        SUB: next_state = (count == DATAWIDTH) ? DONE : SHIFT;
        DONE: next_state = IDLE;
        default: next_state = IDLE;
    endcase
end

//?????????????????????
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        dividend_e <= 0;
        divisor_e <= 0;
        quotient_e <= 0;
        remainder_e <= 0;
        count <= 0;
    end else begin
        case (state)
            IDLE: begin
                if (en) begin
                    dividend_e <= {{DATAWIDTH{1'b0}}, dividend}; //???????
                    divisor_e <= {divisor, {DATAWIDTH{1'b0}}};   //??????
                    count <= 0;
                end
            end
            SHIFT: begin
                if (count < DATAWIDTH) begin
                    dividend_e <= dividend_e << 1; //?????1?
                    count <= count + 1;
                end
            end
            SUB: begin
                // ?????????????1
                dividend_e <= dividend_e - divisor_e;
                quotient_e <= {quotient_e[DATAWIDTH-2:0], 1'b1}; //???????1
            end
            DONE: begin
                remainder_e <= dividend_e[DATAWIDTH*2-1:DATAWIDTH];
                quotient_e <= quotient_e; //?????
            end
        endcase
    end
end

assign quotient = quotient_e;
assign remainder = remainder_e;
assign ready = (state == IDLE);
assign vld_out = (state == DONE);

endmodule