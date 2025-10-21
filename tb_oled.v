`timescale 1ns/1ps
module tb_oled_top(
);

localparam CLK_PERIOD = 20;

reg u_sys_clk;
reg u_sys_rst_n;
reg [29:0] u_data;
wire u_miso;
reg u_reset_oled;
wire u_dc;
wire u_cs;
wire u_sck;

initial begin

    u_sys_clk<=1;
    u_sys_rst_n <= 1'd0;
    #20 u_sys_rst_n <= 1'd1;
    u_data<=30'd19;
    #20 u_data<=30'd20;
    #20 u_data<=30'd21;
end

//生成时钟
always #(CLK_PERIOD / 2) u_sys_clk = ~u_sys_clk;

oled_top u_oled_top(
    u_sys_clk,
    u_sys_rst_n,
    u_data,
    u_miso,
    //u_reset_oled,
    u_dc,
    u_cs,
    u_sck
);

endmodule