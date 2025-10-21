`timescale 1ns/1ps

module u_scan_seg_new(
);

reg U_sys_clk;
reg[4:1] U_key;
reg[4:1] U_sw;
reg U_sys_rst_n;
reg[29:0] U_data_in;
wire[7:0] U_seg_sel;
wire[7:0] U_seg_led;

localparam CLK_PERIOD = 20;

initial
begin
    U_sys_rst_n <= 1'd0;
    U_sys_clk <= 1'd0;
    U_key <= 4'd0;
    U_sw <= 4'd0;
    U_data_in <= 30'd33_000; //测量得到的信号频率为33kHz
    #20 U_sys_rst_n <= 1'd1;
end
always#(CLK_PERIOD / 2) U_sys_clk = ~U_sys_clk;


scan_hex_7seg_top U(
    .sys_clk(U_sys_clk),
    .key(U_key),
    .sw(U_sw),
    .sys_rst_n(U_sys_rst_n),
    .data_in(U_data_in),
    .seg_sel(U_seg_sel),
    .seg_led(U_seg_led)
);


endmodule