`timescale 1ns / 1ps

module scan_hex_7seg(
    input  clk,rst,
    input [3:0] hex7,hex6,hex5,hex4,hex3,hex2,hex1,hex0,
    input [7:0] dp_in,
    output reg [7:0] seg_sel,
    output reg [7:0] seg_led
  
    );
	
	localparam N = 16; //对输入50MHz时钟进行分频(50 MHz/2^16)
    reg [N-1:0]  regN;
    reg [3:0] hex_in;
    always @(posedge clk,posedge rst) 
        if (rst)
           regN <= 0;
        else
           regN <= regN + 1; 
	
    reg dp;	
	always @*//数码管扫描
    case (regN[N-1:N-3]) //13位，实际扫描频率 为1kHz
	  3'b000:
		begin
			seg_sel = 8'b1111_1110;//打开第一个数码管
			hex_in = hex0;
			dp = dp_in[0];
		end
	 3'b001:
		begin
			seg_sel = 8'b1111_1101;//打开第二个数码管
			hex_in = hex1;
			dp = dp_in[1];
		end
	 3'b010:
		begin
			seg_sel = 8'b1111_1011;
			hex_in = hex2;
			dp = dp_in[2];
		end
	  3'b011:
		begin
			seg_sel = 8'b1111_0111;
			hex_in = hex3;
			dp = dp_in[3];
		end
	 3'b100:
		begin
			seg_sel = 8'b1110_1111;
			hex_in = hex4;
			dp = dp_in[4];
		end
	 3'b101:
		begin
			seg_sel = 8'b1101_1111;
			hex_in = hex5;
			dp = dp_in[5];
		end	
	  3'b110:
		begin
			seg_sel = 8'b1011_1111;
			hex_in = hex6;
			dp = dp_in[6];
		end
	 
      default:
		begin
			seg_sel = 8'b0111_1111;
			hex_in = hex7;
			dp = dp_in[7];
		end
    endcase

    always @*//段码的译码
    begin
  	  case (hex_in)
        4'h0: seg_led[6:0] = 7'b1000000;
	    4'h1: seg_led[6:0] = 7'b1111001;
	    4'h2: seg_led[6:0] = 7'b0100100;
	    4'h3: seg_led[6:0] = 7'b0110000;
        4'h4: seg_led[6:0] = 7'b0011001;
	    4'h5: seg_led[6:0] = 7'b0010010;
	    4'h6: seg_led[6:0] = 7'b0000010;
	    4'h7: seg_led[6:0] = 7'b1111000;
	    4'h8: seg_led[6:0] = 7'b0000000;
	    4'h9: seg_led[6:0] = 7'b0010000;
	    4'ha: seg_led[6:0] = 7'b0001000;
	    4'hb: seg_led[6:0] = 7'b0000011;
	    4'hc: seg_led[6:0] = 7'b0100111;
	    4'hd: seg_led[6:0] = 7'b0100001;
	    4'he: seg_led[6:0] = 7'b0000110;
	    default: seg_led[6:0] = 7'b0001110;  //4’hf
	  endcase
	  
	  seg_led[7] = dp;
    end
endmodule


//扫描原理：在很短的时间内，只有一个七段管导通