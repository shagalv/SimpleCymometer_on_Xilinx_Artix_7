`timescale 1ns/1ps
module tb_binary2bcd(
);

localparam CLK_PERIOD = 20;
 
reg u_sys_clk;
reg u_sys_rst_n;
reg [29:0] u_data;
wire [35:0] u_bcd_data;

initial 
begin
    u_sys_rst_n <= 1'd0;
    u_sys_clk <= 1'd0;
    #20 u_sys_rst_n <= 1'd1;
    u_data <= 30'd19;
end

always #(CLK_PERIOD / 2) u_sys_clk = ~u_sys_clk;

binary2bcd u_binary2bcd(
    u_sys_clk,
    u_sys_rst_n,
    u_data,
    u_bcd_data
);

endmodule