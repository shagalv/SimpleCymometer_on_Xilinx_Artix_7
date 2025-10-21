//用于产生多波形信号
module dds(
input 			clk_in;                 // 小脚丫FPGA的外部时钟频率为12MHz
input			rst_n;
input	wire 	O_pulse,L_pulse,R_pulse;
 
output reg	[9:0] 	dac_data;        // 10位数据输出送给外部的DAC
output reg 	[1:0] 	wave;
output reg	[26:0]  WaveFreq;
);//
 
localparam  SIN = 2'b00, SAW = 2'b01, TRI = 2'b10, SQU = 2'b11;

 
reg 	[23:0] 	phase_acc;            //增加相位累加器位数使得分辨率提高
wire	[23:0]	phase;
reg 	[23:0]	f_inc;
 
assign phase=phase_acc;
 
 //相位累加器
always @(posedge clk_in) 	phase_acc <= phase_acc + f_inc;		//f_inc=24'd27962;主时钟为12MHz，则产生20KHz的正弦波信号  
 
wire [9:0] sin_dat; //正弦波
wire [9:0] saw_dat = phase[23:14];  //锯齿波
wire [9:0] tri_dat = phase[23]? (~phase[22:13]) : phase[22:13]; //三角波
wire [9:0] squ_dat = phase[23]? 10'h3ff : 10'h000;  //方波 
 
always @(*) begin
    case(wave)
        2'b00: dac_data = sin_dat;   //正弦波       
		2'b01: dac_data = saw_dat;   //锯齿波       
		2'b10: dac_data = tri_dat;   //三角波       
		2'b11: dac_data = squ_dat;   //方波
        default: dac_data = sin_dat; //正弦波   
	endcase
end
 
lookup_tables u_lookup_tables(.phase(phase_acc[23:16]), .sin_out(sin_dat)); 
 
//波形输出选择
always @(posedge clk_in or negedge rst_n) begin
    if(!rst_n) wave <= SIN;
    else if(O_pulse)begin
        case(wave)
            SIN: wave <= SAW;
            SAW: wave <= TRI;
            TRI: wave <= SQU;
            SQU: wave <= SIN;
            default: wave <= SIN;
        endcase
    end else wave <= wave;
end
//频率控制
always@(posedge clk_in or negedge rst_n) begin
    if(!rst_n) begin
		f_inc <= 24'h22222;
		WaveFreq<=1_000_000;
	end 
    else if(L_pulse==1'b1) begin
        if(f_inc <= 24'h369d) f_inc <= f_inc;
        else begin
			f_inc <= f_inc - 24'h369d;
			WaveFreq<=WaveFreq-100000;
		end 
    end 
	else if(R_pulse==1'b1) begin
        if(f_inc >= 24'h155554) f_inc <= f_inc;
        else begin
			f_inc <= f_inc + 24'h369d;
			WaveFreq<=WaveFreq+100000;
		end 
    end 
	else f_inc <= f_inc;
end
endmodule
//dds时钟频率给定后，输出信号的频率取决于频率控制字，
//	频率分辨率取决于累加器位数，
//	相位分辨率取决于ROM的地址线位数，
//	幅度量化噪声取决于ROM的数据位字长和D/A转换器位数