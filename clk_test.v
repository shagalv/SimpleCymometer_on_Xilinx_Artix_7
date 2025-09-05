//待测时钟模块clk_test

module clk_test(
input clk_in , // 输入时钟
input rst_n , // 复位信号

output reg clk_out // 输出时钟
);
//paramater define
parameter DIV_N = 26'd10 ; //分频
//reg define
reg [25:0] cnt; // 时钟分频计数

//*****************************************************
//** main code
//*****************************************************

//时钟分频，生成 500KHz 的测试时钟
always @(posedge clk_in or negedge rst_n)
begin
    if(rst_n == 1'b0) 
    begin
        cnt <= 0;
        clk_out <= 0;
    end
    else 
    begin
        if(cnt == DIV_N / 2'd2 - 1'b1) 
        begin
            cnt <= 26'd0;
            clk_out <= ~clk_out;
        end
        else
            cnt <= cnt + 1'b1;
    end
end

endmodule