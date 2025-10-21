module getChar3 (
    input                   sys_clk,
    input                   sys_rst_n,
    input   [31:0]          WaveFreq,//输入的频率
    input[2:0]              pattern,//选择“Hz”或者“ns”
    output  reg[(8*16-1):0]    char
);
 
reg	[31:0]  t_bin;
reg	[3:0]   bcd8,bcd7,bcd6,bcd5,bcd4,bcd3,bcd2,bcd1;
 
reg [3:0] state;
 
always@(posedge sys_clk or negedge sys_rst_n)
begin
	if(!sys_rst_n) begin
		t_bin<=WaveFreq;
        char<= 0;
		bcd8<= 0;
		bcd7<= 0;
		bcd6<= 0;
		bcd5<= 0;
		bcd4<= 0;
		bcd3<= 0;
		bcd2<= 0;
		bcd1<= 0;
        state<=0;
	end
	else if(pattern == 3'd1 || pattern  == 3'd3)
    begin
        case (state)
            0: begin
                t_bin<=WaveFreq;
                state<=state+1;
            end
            1: begin
                if($signed(t_bin)-$signed(10000000)>=0)begin
                    bcd8<=bcd8+1;
                    t_bin<=t_bin-10000000;
                end
                else begin
                    state<=state+1;
                end
            end
            2: begin
                if($signed(t_bin)-$signed(1000000)>=0)begin
                    bcd7<=bcd7+1;
                    t_bin<=t_bin-1000000;
                end
                else begin
                    state<=state+1;
                end
            end
            3: begin
                if($signed(t_bin)-$signed(100000)>=0)begin
                    bcd6<=bcd6+1;
                    t_bin<=t_bin-100000;
                end
                else begin
                    state<=state+1;
                end
            end
            4: begin
                if($signed(t_bin)-$signed(10000)>=0)begin
                    bcd5<=bcd5+1;
                    t_bin<=t_bin-10000;
                end
                else begin
                    state<=state+1;
                end
            end
            5: begin
                if($signed(t_bin)-$signed(1000)>=0)begin
                    bcd4<=bcd4+1;
                    t_bin<=t_bin-1000;
                end
                else begin
                    state<=state+1;
                end
            end
            6: begin
                if($signed(t_bin)-$signed(100)>=0)begin
                    bcd3<=bcd3+1;
                    t_bin<=t_bin-100;
                end
                else begin
                    state<=state+1;
                end
            end
            7: begin
                if($signed(t_bin)-$signed(10)>=0)begin
                    bcd2<=bcd2+1;
                    t_bin<=t_bin-10;
                end
                else begin
                    state<=state+1;
                end
            end
            8: begin
                if($signed(t_bin)-$signed(1)>=0)begin
                    bcd1<=bcd1+1;
                    t_bin<=t_bin-1;
                end
                else begin
                    state<=state+1;
                end
            end
            9:begin
                t_bin<=WaveFreq;
                char<={"  ",4'h0,bcd8,4'h0,bcd7,"_",
                4'h0,bcd6,4'h0,bcd5,4'h0,bcd4,"_",
                4'h0,bcd3,4'h0,bcd2,4'h0,bcd1,"Hz  "};
                bcd8<= 0;
                bcd7<= 0;
                bcd6<= 0;
                bcd5<= 0;
                bcd4<= 0;
                bcd3<= 0;
                bcd2<= 0;
                bcd1<= 0;
                state<=0;
            end
            default: begin
                t_bin<=WaveFreq;
                bcd7<= 0;
                bcd6<= 0;
                bcd5<= 0;
                bcd4<= 0;
                bcd3<= 0;
                bcd2<= 0;
                bcd1<= 0;
                state<=0;
            end
        endcase	
	end
    else if(pattern == 3'd2)
    begin
        case (state)
            0: begin
                t_bin<=WaveFreq;
                state<=state+1;
            end
            1: begin
                if($signed(t_bin)-$signed(10000000)>=0)begin
                    bcd8<=bcd8+1;
                    t_bin<=t_bin-10000000;
                end
                else begin
                    state<=state+1;
                end
            end
            2: begin
                if($signed(t_bin)-$signed(1000000)>=0)begin
                    bcd7<=bcd7+1;
                    t_bin<=t_bin-1000000;
                end
                else begin
                    state<=state+1;
                end
            end
            3: begin
                if($signed(t_bin)-$signed(100000)>=0)begin
                    bcd6<=bcd6+1;
                    t_bin<=t_bin-100000;
                end
                else begin
                    state<=state+1;
                end
            end
            4: begin
                if($signed(t_bin)-$signed(10000)>=0)begin
                    bcd5<=bcd5+1;
                    t_bin<=t_bin-10000;
                end
                else begin
                    state<=state+1;
                end
            end
            5: begin
                if($signed(t_bin)-$signed(1000)>=0)begin
                    bcd4<=bcd4+1;
                    t_bin<=t_bin-1000;
                end
                else begin
                    state<=state+1;
                end
            end
            6: begin
                if($signed(t_bin)-$signed(100)>=0)begin
                    bcd3<=bcd3+1;
                    t_bin<=t_bin-100;
                end
                else begin
                    state<=state+1;
                end
            end
            7: begin
                if($signed(t_bin)-$signed(10)>=0)begin
                    bcd2<=bcd2+1;
                    t_bin<=t_bin-10;
                end
                else begin
                    state<=state+1;
                end
            end
            8: begin
                if($signed(t_bin)-$signed(1)>=0)begin
                    bcd1<=bcd1+1;
                    t_bin<=t_bin-1;
                end
                else begin
                    state<=state+1;
                end
            end
            9:begin
                t_bin<=WaveFreq;
                char<={"  ",4'h0,bcd8,4'h0,bcd7,"_",
                4'h0,bcd6,4'h0,bcd5,4'h0,bcd4,"_",
                4'h0,bcd3,4'h0,bcd2,4'h0,bcd1,"ns  "};
                bcd8<= 0;
                bcd7<= 0;
                bcd6<= 0;
                bcd5<= 0;
                bcd4<= 0;
                bcd3<= 0;
                bcd2<= 0;
                bcd1<= 0;
                state<=0;
            end
            default: begin
                t_bin<=WaveFreq;
                bcd7<= 0;
                bcd6<= 0;
                bcd5<= 0;
                bcd4<= 0;
                bcd3<= 0;
                bcd2<= 0;
                bcd1<= 0;
                state<=0;
            end
        endcase	
	end
    else if(pattern == 3'd6)
    begin
        case (state)
            0: begin
                t_bin<=WaveFreq;
                state<=state+1;
            end
            1: begin
                if($signed(t_bin)-$signed(10000000)>=0)begin
                    bcd8<=bcd8+1;
                    t_bin<=t_bin-10000000;
                end
                else begin
                    state<=state+1;
                end
            end
            2: begin
                if($signed(t_bin)-$signed(1000000)>=0)begin
                    bcd7<=bcd7+1;
                    t_bin<=t_bin-1000000;
                end
                else begin
                    state<=state+1;
                end
            end
            3: begin
                if($signed(t_bin)-$signed(100000)>=0)begin
                    bcd6<=bcd6+1;
                    t_bin<=t_bin-100000;
                end
                else begin
                    state<=state+1;
                end
            end
            4: begin
                if($signed(t_bin)-$signed(10000)>=0)begin
                    bcd5<=bcd5+1;
                    t_bin<=t_bin-10000;
                end
                else begin
                    state<=state+1;
                end
            end
            5: begin
                if($signed(t_bin)-$signed(1000)>=0)begin
                    bcd4<=bcd4+1;
                    t_bin<=t_bin-1000;
                end
                else begin
                    state<=state+1;
                end
            end
            6: begin
                if($signed(t_bin)-$signed(100)>=0)begin
                    bcd3<=bcd3+1;
                    t_bin<=t_bin-100;
                end
                else begin
                    state<=state+1;
                end
            end
            7: begin
                if($signed(t_bin)-$signed(10)>=0)begin
                    bcd2<=bcd2+1;
                    t_bin<=t_bin-10;
                end
                else begin
                    state<=state+1;
                end
            end
            8: begin
                if($signed(t_bin)-$signed(1)>=0)begin
                    bcd1<=bcd1+1;
                    t_bin<=t_bin-1;
                end
                else begin
                    state<=state+1;
                end
            end
            9:begin
                t_bin<=WaveFreq;
                char<={"  ",4'h0,bcd8,4'h0,bcd7,"_",
                4'h0,bcd6,4'h0,bcd5,4'h0,bcd4,"_",
                4'h0,bcd3,4'h0,bcd2,4'h0,bcd1,"us  "};
                bcd8<= 0;
                bcd7<= 0;
                bcd6<= 0;
                bcd5<= 0;
                bcd4<= 0;
                bcd3<= 0;
                bcd2<= 0;
                bcd1<= 0;
                state<=0;
            end
            default: begin
                t_bin<=WaveFreq;
                bcd7<= 0;
                bcd6<= 0;
                bcd5<= 0;
                bcd4<= 0;
                bcd3<= 0;
                bcd2<= 0;
                bcd1<= 0;
                state<=0;
            end
        endcase	
	end
    else if(pattern == 3'd7)
    begin
        case (state)
            0: begin
                t_bin<=WaveFreq;
                state<=state+1;
            end
            1: begin
                if($signed(t_bin)-$signed(10000000)>=0)begin
                    bcd8<=bcd8+1;
                    t_bin<=t_bin-10000000;
                end
                else begin
                    state<=state+1;
                end
            end
            2: begin
                if($signed(t_bin)-$signed(1000000)>=0)begin
                    bcd7<=bcd7+1;
                    t_bin<=t_bin-1000000;
                end
                else begin
                    state<=state+1;
                end
            end
            3: begin
                if($signed(t_bin)-$signed(100000)>=0)begin
                    bcd6<=bcd6+1;
                    t_bin<=t_bin-100000;
                end
                else begin
                    state<=state+1;
                end
            end
            4: begin
                if($signed(t_bin)-$signed(10000)>=0)begin
                    bcd5<=bcd5+1;
                    t_bin<=t_bin-10000;
                end
                else begin
                    state<=state+1;
                end
            end
            5: begin
                if($signed(t_bin)-$signed(1000)>=0)begin
                    bcd4<=bcd4+1;
                    t_bin<=t_bin-1000;
                end
                else begin
                    state<=state+1;
                end
            end
            6: begin
                if($signed(t_bin)-$signed(100)>=0)begin
                    bcd3<=bcd3+1;
                    t_bin<=t_bin-100;
                end
                else begin
                    state<=state+1;
                end
            end
            7: begin
                if($signed(t_bin)-$signed(10)>=0)begin
                    bcd2<=bcd2+1;
                    t_bin<=t_bin-10;
                end
                else begin
                    state<=state+1;
                end
            end
            8: begin
                if($signed(t_bin)-$signed(1)>=0)begin
                    bcd1<=bcd1+1;
                    t_bin<=t_bin-1;
                end
                else begin
                    state<=state+1;
                end
            end
            9:begin
                t_bin<=WaveFreq;
                char<={"  ",4'h0,bcd8,4'h0,bcd7,"_",
                4'h0,bcd6,4'h0,bcd5,4'h0,bcd4,"_",
                4'h0,bcd3,4'h0,bcd2,4'h0,bcd1,"%  "};
                bcd8<= 0;
                bcd7<= 0;
                bcd6<= 0;
                bcd5<= 0;
                bcd4<= 0;
                bcd3<= 0;
                bcd2<= 0;
                bcd1<= 0;
                state<=0;
            end
            default: begin
                t_bin<=WaveFreq;
                bcd7<= 0;
                bcd6<= 0;
                bcd5<= 0;
                bcd4<= 0;
                bcd3<= 0;
                bcd2<= 0;
                bcd1<= 0;
                state<=0;
            end
        endcase	
	end
end
 
endmodule