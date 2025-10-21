// --------------------------------------------------------------------
// Module: OLED12864 
// Description: OLED12864_Driver
// --------------------------------------------------------------------
module OLED12864
(
	input				sys_clk,		//系统时钟
	input				sys_rst_n,		//系统复位，低有效
 
	input		[3:0]	sw,				//开关输入
	input		[1:0]	wave,			//输入波形的选择
	input [26:0]    WaveFreq,			//波形频率数据
 
	// OLED显示接口信号
    output  reg         oled_csn,   // OLED片选信号
    output  reg         oled_rst,   // OLED复位信号
    output  reg         oled_dcn,   // 数据/命令控制�??1=数据�??0=命令�??
    output  reg         oled_clk,   // SPI时钟信号
    output  reg         oled_dat    // SPI数据信号
);
	localparam INIT_DEPTH = 16'd23; // LCD初始化命令的数量
	localparam IDLE = 7'h1,             // 空闲状�??
               MAIN = 7'h2,             // 主控制状�??
               INIT = 7'h4,             // 初始化状�??
               SCAN = 7'h8,             // 屏幕扫描状�??
               WRITE = 7'h10,           // 数据写入状�??
               DELAY = 7'h20,           // 延时状�??
               CHINESE = 7'h40;         // 汉字显示状�??
    
    localparam HIGH	= 1'b1, LOW = 1'b0;// 高电平和低电平定�??
	localparam DATA	= 1'b1, CMD = 1'b0;// 数据和命令定�??
 
	reg     [7:0]           cmd [24:0];     // 初始化命令存储数组
	reg     [39:0]          mem [122:0];     // 5 * 8点阵ASCII字符库（40位=5字节×8位）
	reg     [63:0]          mem_hanzi[79:0]; // 8 * 8点阵汉字库（64位=8字节×8位）
	reg     [4:0]           length_hanzi;    // 汉字显示长度计数器
	reg [7:0]               y_p, x_ph, x_pl; // 页面地址(Y)，列地址高字节(X)，列地址低字节(X)
	reg [(8 * 21-1):0]        char;           // 字符缓存：21个字符×8位
	reg [7:0]               num, char_reg;   // 数量计数器和字符寄存器      
	reg [4:0]               cnt_main, cnt_init, cnt_scan, cnt_write, cnt_chinese; // 各状态计数器
	reg [15:0]              num_delay, cnt_delay, cnt; // 延时相关计数器
	reg [6:0]               state, state_back; // 当前状态和返回状态
	reg [4:0]               hanzi_fuzhujishu; // 汉字辅助计数器
 
 // 实例化字符生成模块
		wire [(8*16-1):0]   char3;
	getChar3 getChar3 (
        .sys_clk(sys_clk),
        .sys_rst_n(sys_rst_n),
        .WaveFreq(WaveFreq),
        .char(char3)
    );
 
 
	always @ (posedge sys_clk or negedge sys_rst_n) begin
		if(!sys_rst_n) begin
			cnt_main <= 1'b0; cnt_init <= 1'b0; cnt_scan <= 1'b0; cnt_write <= 1'b0;cnt_chinese <= 1'b0;
			y_p <= 1'b0; x_ph <= 1'b0; x_pl <= 1'b0;length_hanzi<=5'd0;hanzi_fuzhujishu<=5'd0;
			num <= 1'b0; char <= 1'b0; char_reg <= 1'b0;
			num_delay <= 16'd5; cnt_delay <= 1'b0; cnt <= 1'b0;
			oled_csn <= HIGH; oled_rst <= HIGH; oled_dcn <= CMD; oled_clk <= HIGH; oled_dat <= LOW;
			state <= IDLE; state_back <= IDLE;
		end else begin
			case(state)
				IDLE:begin
						cnt_main <= 1'b0; cnt_init <= 1'b0; cnt_scan <= 1'b0; cnt_write <= 1'b0;
						y_p <= 1'b0; x_ph <= 1'b0; x_pl <= 1'b0;
						num <= 1'b0; char <= 1'b0; char_reg <= 1'b0;
						num_delay <= 16'd5; cnt_delay <= 1'b0; cnt <= 1'b0;
						oled_csn <= HIGH; oled_rst <= HIGH; oled_dcn <= CMD; oled_clk <= HIGH; oled_dat <= LOW;
						state <= MAIN; state_back <= MAIN;
					end
				MAIN:begin
						if(cnt_main >= 5'd14) cnt_main <= 5'd12;
						else cnt_main <= cnt_main + 1'b1;
						case(cnt_main)	//MAIN鐘舵�??						
							5'd0 :	begin state <= INIT; end
							5'd1 :	begin y_p <= 8'hb0; x_ph <= 8'h10; x_pl <= 8'h00; num <= 5'd8; char <= "        ";state <= SCAN; end
							//5'd1 : begin cnt_main <= cnt_main + 1'b1; end  // 直接跳过
                            5'd2 :	begin y_p <= 8'hb1; x_ph <= 8'h10; x_pl <= 8'h00; num <= 5'd8; char <= "        ";state <= SCAN; end																								
							5'd3 :	begin y_p <= 8'hb0; x_ph <= 8'h14; x_pl <= 8'h00; num <= 5'd8; char <= "         ";state <= SCAN; end
							5'd4 :	begin y_p <= 8'hb1; x_ph <= 8'h14; x_pl <= 8'h00; num <= 5'd8; char <= "         ";state <= SCAN; end												
							5'd5 :	begin y_p <= 8'hb2; x_ph <= 8'h14; x_pl <= 8'h00; num <= 5'd8; char <= "         ";state <= SCAN; end
							5'd6 :	begin y_p <= 8'hb3; x_ph <= 8'h14; x_pl <= 8'h00; num <= 5'd8; char <= "         ";state <= SCAN; end
							5'd7 :	begin y_p <= 8'hb4; x_ph <= 8'h10; x_pl <= 8'h00; num <= 5'd16; char <= "                ";state <= SCAN; end
							5'd8 :	begin y_p <= 8'hb5; x_ph <= 8'h10; x_pl <= 8'h00; num <= 5'd16; char <= "                ";state <= SCAN; end
							5'd9 :	begin y_p <= 8'hb6; x_ph <= 8'h10; x_pl <= 8'h00; num <= 5'd16; char <= "                ";state <= SCAN; end
							5'd10:	begin y_p <= 8'hb7; x_ph <= 8'h10; x_pl <= 8'h00; num <= 5'd16; char <= "                ";state <= SCAN; end							
							5'd11:	;//begin y_p <= 8'hb1; x_ph <= 8'h15; x_pl <= 8'h00; num <= 5'd 1; char <= sw; state <= SCAN; end
							5'd12:	begin y_p <= 8'hb2; x_ph <= 8'h10; x_pl <= 8'h00; length_hanzi <= 5'd9; 
										if	   (wave==2'b00)begin hanzi_fuzhujishu<=5'd8;state <= CHINESE; end 
										else if(wave==2'b01)begin hanzi_fuzhujishu<=5'd2;state <= CHINESE; end 
										else if(wave==2'b10)begin hanzi_fuzhujishu<=5'd4;state <= CHINESE; end 
										else begin hanzi_fuzhujishu<=5'd6;state <= CHINESE; end //if(wave==2'b11)
									end
							5'd13 :	begin y_p <= 8'hb3; x_ph <= 8'h10; x_pl <= 8'h00; length_hanzi <= 5'd9; 
										if	   (wave==2'b00)begin hanzi_fuzhujishu<=5'd9;state <= CHINESE; end 
										else if(wave==2'b01)begin hanzi_fuzhujishu<=5'd3;state <= CHINESE; end 
										else if(wave==2'b10)begin hanzi_fuzhujishu<=5'd5;state <= CHINESE; end 
										else begin hanzi_fuzhujishu<=5'd7;state <= CHINESE; end //if(wave==2'b11)
									end
							5'd14 :	begin y_p <= 8'hb5; x_ph <= 8'h10; x_pl <= 8'h00; num <= 5'd16; char <= char3;state <= SCAN; end
							default: state <= IDLE;
						endcase
                end 
				INIT:begin	//鍒濆鍖栫姸�??
						case(cnt_init)
							5'd0:	begin oled_rst <= LOW; cnt_init <= cnt_init + 1'b1; end	//澶嶄綅鏈夋晥
							5'd1:	begin num_delay <= 16'd25000; state <= DELAY; state_back <= INIT; cnt_init <= cnt_init + 1'b1; end	//寤舵椂澶т�??3us
							5'd2:	begin oled_rst <= HIGH; cnt_init <= cnt_init + 1'b1; end	//澶嶄綅鎭㈠
							5'd3:	begin num_delay <= 16'd25000; state <= DELAY; state_back <= INIT; cnt_init <= cnt_init + 1'b1; end	//寤舵椂澶т�??220us
							5'd4:	begin 
										if(cnt>=INIT_DEPTH) begin	//�??5鏉℃寚浠ゅ強鏁版嵁鍙戝嚭鍚庯紝閰嶇疆瀹屾�??
											cnt <= 1'b0;
											cnt_init <= cnt_init + 1'b1;
										end else begin	
											cnt <= cnt + 1'b1; num_delay <= 16'd5;
											oled_dcn <= CMD; char_reg <= cmd[cnt]; state <= WRITE; state_back <= INIT;
										end
									end
							5'd5:	begin cnt_init <= 1'b0; state <= MAIN; end	//鍒濆鍖栧畬鎴愶紝杩斿洖MAIN鐘舵�??
							default: state <= IDLE;
						endcase
					end
				SCAN:begin	//鍒峰睆鐘舵€侊紝浠嶳AM涓鍙栨暟鎹埛灞
						if(cnt_scan == 5'd11) begin
							if(num) cnt_scan <= 5'd3;
							else cnt_scan <= cnt_scan + 1'b1;
						end 
						else if(cnt_scan == 5'd12) cnt_scan <= 1'b0;
						else cnt_scan <= cnt_scan + 1'b1;
						case(cnt_scan)
							5'd 0:	begin oled_dcn <= CMD; char_reg <= y_p; state <= WRITE; state_back <= SCAN; end		//瀹氫綅鍒楅�?�鍦板潃
							5'd 1:	begin oled_dcn <= CMD; char_reg <= x_pl; state <= WRITE; state_back <= SCAN; end	//瀹氫綅琛屽湴鍧€浣庝�??
							5'd 2:	begin oled_dcn <= CMD; char_reg <= x_ph; state <= WRITE; state_back <= SCAN; end	//瀹氫綅琛屽湴鍧€楂樹�??
 
							5'd 3:	begin num <= num - 1'b1;end
							5'd 4:	begin oled_dcn <= DATA; char_reg <= 8'h00; state <= WRITE; state_back <= SCAN; end	//�??*8鐐归�??缂栫�??8*8
							5'd 5:	begin oled_dcn <= DATA; char_reg <= 8'h00; state <= WRITE; state_back <= SCAN; end	//�??*8鐐归�??缂栫�??8*8
							5'd 6:	begin oled_dcn <= DATA; char_reg <= 8'h00; state <= WRITE; state_back <= SCAN; end	//�??*8鐐归�??缂栫�??8*8
							5'd 7:	begin oled_dcn <= DATA; char_reg <= mem[char[(num*8)+:8]][39:32]; state <= WRITE; state_back <= SCAN; end
							5'd 8:	begin oled_dcn <= DATA; char_reg <= mem[char[(num*8)+:8]][31:24]; state <= WRITE; state_back <= SCAN; end
							5'd 9:	begin oled_dcn <= DATA; char_reg <= mem[char[(num*8)+:8]][23:16]; state <= WRITE; state_back <= SCAN; end
							5'd10:	begin oled_dcn <= DATA; char_reg <= mem[char[(num*8)+:8]][15: 8]; state <= WRITE; state_back <= SCAN; end
							5'd11:	begin oled_dcn <= DATA; char_reg <= mem[char[(num*8)+:8]][ 7: 0]; state <= WRITE; state_back <= SCAN; end
							5'd12:	begin state <= MAIN; end
							default: state <= IDLE;
						endcase
					end
 
 
 
				//length_hanzi<=5'd8-----涓€琛屽啓鍏
				CHINESE:begin	//鏄剧ず姹夊瓧
						if(cnt_chinese == 5'd11) begin
							if(length_hanzi>=5'd2) cnt_chinese <= 5'd3;
							else cnt_chinese <= cnt_chinese + 1'b1;
						end 
						else if(cnt_chinese == 5'd12) cnt_chinese <= 1'b0;
						else cnt_chinese <= cnt_chinese+1'b1;
						case(cnt_chinese)    
							5'd 0:	begin oled_dcn <= CMD; char_reg <= y_p; state <= WRITE; state_back <= CHINESE; end		//瀹氫綅鍒楅�?�鍦板潃
							5'd 1:	begin oled_dcn <= CMD; char_reg <= 8'h00; state <= WRITE; state_back <= CHINESE; end	//瀹氫綅琛屽湴鍧€浣庝�??
							5'd 2:	begin oled_dcn <= CMD; char_reg <= 8'h10; state <= WRITE; state_back <= CHINESE; end	//瀹氫綅琛屽湴鍧€楂樹�??
 
							5'd 3:	begin length_hanzi <= length_hanzi - 1'b1;end//length_hanzi鍒濆�??=9锛氭瘡琛岄暱搴︿�??8
							5'd 4:	begin oled_dcn <= DATA; char_reg <= mem_hanzi[hanzi_fuzhujishu*8+8-length_hanzi][63:56]; state <= WRITE; state_back <= CHINESE; end
							5'd 5:	begin oled_dcn <= DATA; char_reg <= mem_hanzi[hanzi_fuzhujishu*8+8-length_hanzi][55:48]; state <= WRITE; state_back <= CHINESE; end
							5'd 6:	begin oled_dcn <= DATA; char_reg <= mem_hanzi[hanzi_fuzhujishu*8+8-length_hanzi][47:40]; state <= WRITE; state_back <= CHINESE; end
							5'd 7:	begin oled_dcn <= DATA; char_reg <= mem_hanzi[hanzi_fuzhujishu*8+8-length_hanzi][39:32]; state <= WRITE; state_back <= CHINESE; end
							5'd 8:	begin oled_dcn <= DATA; char_reg <= mem_hanzi[hanzi_fuzhujishu*8+8-length_hanzi][31:24]; state <= WRITE; state_back <= CHINESE; end
							5'd 9:	begin oled_dcn <= DATA; char_reg <= mem_hanzi[hanzi_fuzhujishu*8+8-length_hanzi][23:16]; state <= WRITE; state_back <= CHINESE; end
							5'd10:	begin oled_dcn <= DATA; char_reg <= mem_hanzi[hanzi_fuzhujishu*8+8-length_hanzi][15: 8]; state <= WRITE; state_back <= CHINESE; end
							5'd11:	begin oled_dcn <= DATA; char_reg <= mem_hanzi[hanzi_fuzhujishu*8+8-length_hanzi][ 7: 0]; state <= WRITE; state_back <= CHINESE; end 
							5'd12:	begin state <= MAIN; end
							default: state <= IDLE;
						endcase
					end
 
 
 
				WRITE:begin	//WRITE鐘舵€侊紝灏嗘暟鎹寜鐓PI鏃跺簭鍙戦€佺粰灞忓�??
						if(cnt_write >= 5'd17) cnt_write <= 1'b0;
						else cnt_write <= cnt_write + 1'b1;
						case(cnt_write)
							5'd 0:	begin oled_csn <= LOW; end	//9浣嶆暟鎹渶楂樹綅涓哄懡浠ゆ暟鎹帶鍒朵�??
							5'd 1:	begin oled_clk <= LOW; oled_dat <= char_reg[7]; end	//鍏堝彂楂樹綅鏁版�??
							5'd 2:	begin oled_clk <= HIGH; end
							5'd 3:	begin oled_clk <= LOW; oled_dat <= char_reg[6]; end
							5'd 4:	begin oled_clk <= HIGH; end
							5'd 5:	begin oled_clk <= LOW; oled_dat <= char_reg[5]; end
							5'd 6:	begin oled_clk <= HIGH; end
							5'd 7:	begin oled_clk <= LOW; oled_dat <= char_reg[4]; end
							5'd 8:	begin oled_clk <= HIGH; end
							5'd 9:	begin oled_clk <= LOW; oled_dat <= char_reg[3]; end
							5'd10:	begin oled_clk <= HIGH; end
							5'd11:	begin oled_clk <= LOW; oled_dat <= char_reg[2]; end
							5'd12:	begin oled_clk <= HIGH; end
							5'd13:	begin oled_clk <= LOW; oled_dat <= char_reg[1]; end
							5'd14:	begin oled_clk <= HIGH; end
							5'd15:	begin oled_clk <= LOW; oled_dat <= char_reg[0]; end	//鍚庡彂浣庝綅鏁版�??
							5'd16:	begin oled_clk <= HIGH; end
							5'd17:	begin oled_csn <= HIGH; state <= DELAY; end	//
							default: state <= IDLE;
						endcase
					end
				DELAY:begin	//寤舵椂鐘舵€
						if(cnt_delay >= num_delay) begin
							cnt_delay <= 16'd0; state <= state_back; 
						end else cnt_delay <= cnt_delay + 1'b1;
					end
				default:state <= IDLE;
			endcase
		end
	end
 
	//OLED閰嶇疆鎸囦护鏁版�??
	always@(posedge sys_rst_n)
		begin
			cmd[0 ] = {8'hae}; 
			cmd[1 ] = {8'hd5}; 
			cmd[2 ] = {8'h80}; 
			cmd[3 ] = {8'ha8}; 
			cmd[4 ] = {8'h3f}; 
			cmd[5 ] = {8'hd3}; 
			cmd[6 ] = {8'h00}; 
			cmd[7 ] = {8'h40}; 
			cmd[8 ] = {8'h8d}; 
			cmd[9 ] = {8'h14}; 
			cmd[10] = {8'h20}; 
			cmd[11] = {8'h02};
			cmd[12] = {8'hc8};
			cmd[13] = {8'ha1};
			cmd[14] = {8'hda};
			cmd[15] = {8'h12};
			cmd[16] = {8'h81};
			cmd[17] = {8'hcf};
			cmd[18] = {8'hd9};
			cmd[19] = {8'hf1};
			cmd[20] = {8'hdb};
			cmd[21] = {8'h40};
			cmd[22] = {8'haf};
 
		end 

	//5*8鐐归�??瀛楀簱鏁版嵁
	always@(posedge sys_rst_n)
		begin
			mem[  0] = {8'h3E, 8'h51, 8'h49, 8'h45, 8'h3E};   // 48  0
			mem[  1] = {8'h00, 8'h42, 8'h7F, 8'h40, 8'h00};   // 49  1
			mem[  2] = {8'h42, 8'h61, 8'h51, 8'h49, 8'h46};   // 50  2
			mem[  3] = {8'h21, 8'h41, 8'h45, 8'h4B, 8'h31};   // 51  3
			mem[  4] = {8'h18, 8'h14, 8'h12, 8'h7F, 8'h10};   // 52  4
			mem[  5] = {8'h27, 8'h45, 8'h45, 8'h45, 8'h39};   // 53  5
			mem[  6] = {8'h3C, 8'h4A, 8'h49, 8'h49, 8'h30};   // 54  6
			mem[  7] = {8'h01, 8'h71, 8'h09, 8'h05, 8'h03};   // 55  7
			mem[  8] = {8'h36, 8'h49, 8'h49, 8'h49, 8'h36};   // 56  8
			mem[  9] = {8'h06, 8'h49, 8'h49, 8'h29, 8'h1E};   // 57  9
			mem[ 10] = {8'h7C, 8'h12, 8'h11, 8'h12, 8'h7C};   // 65  A
			mem[ 11] = {8'h7F, 8'h49, 8'h49, 8'h49, 8'h36};   // 66  B
			mem[ 12] = {8'h3E, 8'h41, 8'h41, 8'h41, 8'h22};   // 67  C
			mem[ 13] = {8'h7F, 8'h41, 8'h41, 8'h22, 8'h1C};   // 68  D
			mem[ 14] = {8'h7F, 8'h49, 8'h49, 8'h49, 8'h41};   // 69  E
			mem[ 15] = {8'h7F, 8'h09, 8'h09, 8'h09, 8'h01};   // 70  F
 
			mem[ 32] = {8'h00, 8'h00, 8'h00, 8'h00, 8'h00};   // 32  sp 
			mem[ 33] = {8'h00, 8'h00, 8'h2f, 8'h00, 8'h00};   // 33  !  
			mem[ 34] = {8'h00, 8'h07, 8'h00, 8'h07, 8'h00};   // 34  
			mem[ 35] = {8'h14, 8'h7f, 8'h14, 8'h7f, 8'h14};   // 35  #
			mem[ 36] = {8'h24, 8'h2a, 8'h7f, 8'h2a, 8'h12};   // 36  $
			mem[ 37] = {8'h62, 8'h64, 8'h08, 8'h13, 8'h23};   // 37  %
			mem[ 38] = {8'h36, 8'h49, 8'h55, 8'h22, 8'h50};   // 38  &
			mem[ 39] = {8'h00, 8'h05, 8'h03, 8'h00, 8'h00};   // 39  '
			mem[ 40] = {8'h00, 8'h1c, 8'h22, 8'h41, 8'h00};   // 40  (
			mem[ 41] = {8'h00, 8'h41, 8'h22, 8'h1c, 8'h00};   // 41  )
			mem[ 42] = {8'h14, 8'h08, 8'h3E, 8'h08, 8'h14};   // 42  *
			mem[ 43] = {8'h08, 8'h08, 8'h3E, 8'h08, 8'h08};   // 43  +
			mem[ 44] = {8'h00, 8'h00, 8'hA0, 8'h60, 8'h00};   // 44  ,
			mem[ 45] = {8'h08, 8'h08, 8'h08, 8'h08, 8'h08};   // 45  -
			mem[ 46] = {8'h00, 8'h60, 8'h60, 8'h00, 8'h00};   // 46  .
			mem[ 47] = {8'h20, 8'h10, 8'h08, 8'h04, 8'h02};   // 47  /
			mem[ 48] = {8'h3E, 8'h51, 8'h49, 8'h45, 8'h3E};   // 48  0
			mem[ 49] = {8'h00, 8'h42, 8'h7F, 8'h40, 8'h00};   // 49  1
			mem[ 50] = {8'h42, 8'h61, 8'h51, 8'h49, 8'h46};   // 50  2
			mem[ 51] = {8'h21, 8'h41, 8'h45, 8'h4B, 8'h31};   // 51  3
			mem[ 52] = {8'h18, 8'h14, 8'h12, 8'h7F, 8'h10};   // 52  4
			mem[ 53] = {8'h27, 8'h45, 8'h45, 8'h45, 8'h39};   // 53  5
			mem[ 54] = {8'h3C, 8'h4A, 8'h49, 8'h49, 8'h30};   // 54  6
			mem[ 55] = {8'h01, 8'h71, 8'h09, 8'h05, 8'h03};   // 55  7
			mem[ 56] = {8'h36, 8'h49, 8'h49, 8'h49, 8'h36};   // 56  8
			mem[ 57] = {8'h06, 8'h49, 8'h49, 8'h29, 8'h1E};   // 57  9
			mem[ 58] = {8'h00, 8'h36, 8'h36, 8'h00, 8'h00};   // 58  :
			mem[ 59] = {8'h00, 8'h56, 8'h36, 8'h00, 8'h00};   // 59  ;
			mem[ 60] = {8'h08, 8'h14, 8'h22, 8'h41, 8'h00};   // 60  <
			mem[ 61] = {8'h14, 8'h14, 8'h14, 8'h14, 8'h14};   // 61  =
			mem[ 62] = {8'h00, 8'h41, 8'h22, 8'h14, 8'h08};   // 62  >
			mem[ 63] = {8'h02, 8'h01, 8'h51, 8'h09, 8'h06};   // 63  ?
			mem[ 64] = {8'h32, 8'h49, 8'h59, 8'h51, 8'h3E};   // 64  @
			mem[ 65] = {8'h7C, 8'h12, 8'h11, 8'h12, 8'h7C};   // 65  A
			mem[ 66] = {8'h7F, 8'h49, 8'h49, 8'h49, 8'h36};   // 66  B
			mem[ 67] = {8'h3E, 8'h41, 8'h41, 8'h41, 8'h22};   // 67  C
			mem[ 68] = {8'h7F, 8'h41, 8'h41, 8'h22, 8'h1C};   // 68  D
			mem[ 69] = {8'h7F, 8'h49, 8'h49, 8'h49, 8'h41};   // 69  E
			mem[ 70] = {8'h7F, 8'h09, 8'h09, 8'h09, 8'h01};   // 70  F
			mem[ 71] = {8'h3E, 8'h41, 8'h49, 8'h49, 8'h7A};   // 71  G
			mem[ 72] = {8'h7F, 8'h08, 8'h08, 8'h08, 8'h7F};   // 72  H
			mem[ 73] = {8'h00, 8'h41, 8'h7F, 8'h41, 8'h00};   // 73  I
			mem[ 74] = {8'h20, 8'h40, 8'h41, 8'h3F, 8'h01};   // 74  J
			mem[ 75] = {8'h7F, 8'h08, 8'h14, 8'h22, 8'h41};   // 75  K
			mem[ 76] = {8'h7F, 8'h40, 8'h40, 8'h40, 8'h40};   // 76  L
			mem[ 77] = {8'h7F, 8'h02, 8'h0C, 8'h02, 8'h7F};   // 77  M
			mem[ 78] = {8'h7F, 8'h04, 8'h08, 8'h10, 8'h7F};   // 78  N
			mem[ 79] = {8'h3E, 8'h41, 8'h41, 8'h41, 8'h3E};   // 79  O
			mem[ 80] = {8'h7F, 8'h09, 8'h09, 8'h09, 8'h06};   // 80  P
			mem[ 81] = {8'h3E, 8'h41, 8'h51, 8'h21, 8'h5E};   // 81  Q
			mem[ 82] = {8'h7F, 8'h09, 8'h19, 8'h29, 8'h46};   // 82  R
			mem[ 83] = {8'h46, 8'h49, 8'h49, 8'h49, 8'h31};   // 83  S
			mem[ 84] = {8'h01, 8'h01, 8'h7F, 8'h01, 8'h01};   // 84  T
			mem[ 85] = {8'h3F, 8'h40, 8'h40, 8'h40, 8'h3F};   // 85  U
			mem[ 86] = {8'h1F, 8'h20, 8'h40, 8'h20, 8'h1F};   // 86  V
			mem[ 87] = {8'h3F, 8'h40, 8'h38, 8'h40, 8'h3F};   // 87  W
			mem[ 88] = {8'h63, 8'h14, 8'h08, 8'h14, 8'h63};   // 88  X
			mem[ 89] = {8'h07, 8'h08, 8'h70, 8'h08, 8'h07};   // 89  Y
			mem[ 90] = {8'h61, 8'h51, 8'h49, 8'h45, 8'h43};   // 90  Z
			mem[ 91] = {8'h00, 8'h7F, 8'h41, 8'h41, 8'h00};   // 91  [
			mem[ 92] = {8'h55, 8'h2A, 8'h55, 8'h2A, 8'h55};   // 92  .
			mem[ 93] = {8'h00, 8'h41, 8'h41, 8'h7F, 8'h00};   // 93  ]
			mem[ 94] = {8'h04, 8'h02, 8'h01, 8'h02, 8'h04};   // 94  ^
			mem[ 95] = {8'h40, 8'h40, 8'h40, 8'h40, 8'h40};   // 95  _
			mem[ 96] = {8'h00, 8'h01, 8'h02, 8'h04, 8'h00};   // 96  '
			mem[ 97] = {8'h20, 8'h54, 8'h54, 8'h54, 8'h78};   // 97  a
			mem[ 98] = {8'h7F, 8'h48, 8'h44, 8'h44, 8'h38};   // 98  b
			mem[ 99] = {8'h38, 8'h44, 8'h44, 8'h44, 8'h20};   // 99  c
			mem[100] = {8'h38, 8'h44, 8'h44, 8'h48, 8'h7F};   // 100 d
			mem[101] = {8'h38, 8'h54, 8'h54, 8'h54, 8'h18};   // 101 e
			mem[102] = {8'h08, 8'h7E, 8'h09, 8'h01, 8'h02};   // 102 f
			mem[103] = {8'h18, 8'hA4, 8'hA4, 8'hA4, 8'h7C};   // 103 g
			mem[104] = {8'h7F, 8'h08, 8'h04, 8'h04, 8'h78};   // 104 h
			mem[105] = {8'h00, 8'h44, 8'h7D, 8'h40, 8'h00};   // 105 i
			mem[106] = {8'h40, 8'h80, 8'h84, 8'h7D, 8'h00};   // 106 j
			mem[107] = {8'h7F, 8'h10, 8'h28, 8'h44, 8'h00};   // 107 k
			mem[108] = {8'h00, 8'h41, 8'h7F, 8'h40, 8'h00};   // 108 l
			mem[109] = {8'h7C, 8'h04, 8'h18, 8'h04, 8'h78};   // 109 m
			mem[110] = {8'h7C, 8'h08, 8'h04, 8'h04, 8'h78};   // 110 n
			mem[111] = {8'h38, 8'h44, 8'h44, 8'h44, 8'h38};   // 111 o
			mem[112] = {8'hFC, 8'h24, 8'h24, 8'h24, 8'h18};   // 112 p
			mem[113] = {8'h18, 8'h24, 8'h24, 8'h18, 8'hFC};   // 113 q
			mem[114] = {8'h7C, 8'h08, 8'h04, 8'h04, 8'h08};   // 114 r
			mem[115] = {8'h48, 8'h54, 8'h54, 8'h54, 8'h20};   // 115 s
			mem[116] = {8'h04, 8'h3F, 8'h44, 8'h40, 8'h20};   // 116 t
			mem[117] = {8'h3C, 8'h40, 8'h40, 8'h20, 8'h7C};   // 117 u
			mem[118] = {8'h1C, 8'h20, 8'h40, 8'h20, 8'h1C};   // 118 v
			mem[119] = {8'h3C, 8'h40, 8'h30, 8'h40, 8'h3C};   // 119 w
			mem[120] = {8'h44, 8'h28, 8'h10, 8'h28, 8'h44};   // 120 x
			mem[121] = {8'h1C, 8'hA0, 8'hA0, 8'hA0, 8'h7C};   // 121 y
			mem[122] = {8'h44, 8'h64, 8'h54, 8'h4C, 8'h44};   // 122 z
		end
 
		//姹夊瓧锛氱�?�绂惧�??
	always@(posedge sys_rst_n)
		begin
			mem_hanzi[  0] = {8'h04,8'h84,8'hE4,8'h5C,8'h44,8'hC4,8'h00,8'hF2};   // 48  0
			mem_hanzi[  1] = {8'h92,8'h92,8'hFE,8'h92,8'h92,8'hF2,8'h02,8'h00};   // 49  1
			mem_hanzi[  8] = {8'h02,8'h01,8'h7F,8'h10,8'h10,8'h3F,8'h80,8'h8F};   // 50  2
			mem_hanzi[  9] = {8'h54,8'h24,8'h5F,8'h44,8'h84,8'h87,8'h80,8'h00};   // 51  3
			mem_hanzi[  2] = {8'h00,8'h40,8'h44,8'h44,8'h44,8'h44,8'hC4,8'hFC};   // 52  4
			mem_hanzi[  3] = {8'hC2,8'h42,8'h42,8'h43,8'h42,8'h40,8'h00,8'h00};   // 53  5
			mem_hanzi[  10] = {8'h20,8'h20,8'h10,8'h08,8'h04,8'h03,8'h00,8'hFF};   // 54  6
			mem_hanzi[  11] = {8'h00,8'h03,8'h04,8'h08,8'h10,8'h20,8'h20,8'h00};   // 55  7
			mem_hanzi[  4] = {8'h40,8'h30,8'h11,8'h96,8'h90,8'h90,8'h91,8'h96};   // 56  8
			mem_hanzi[  5 ] = {8'h90,8'h90,8'h98,8'h14,8'h13,8'h50,8'h30,8'h00};   // 48  0
			mem_hanzi[  12] = {8'h04,8'h04,8'h04,8'h04,8'h04,8'h44,8'h84,8'h7E};   // 49  1
			mem_hanzi[  13] = {8'h06,8'h05,8'h04,8'h04,8'h04,8'h04,8'h04,8'h00};   // 50  2
			mem_hanzi[  6] = {8'h20,8'h18,8'h08,8'hEA,8'h2C,8'h28,8'h28,8'h2F};   // 51  3
			mem_hanzi[  7] = {8'h28,8'h28,8'h2C,8'hEA,8'h08,8'h28,8'h18,8'h00};   // 52  4
			mem_hanzi[  14] = {8'h40,8'h40,8'h48,8'h49,8'h49,8'h49,8'h49,8'h7F};   // 53  5
			mem_hanzi[  15] = {8'h49,8'h49,8'h49,8'h49,8'h48,8'h40,8'h40,8'h00};   // 54  6
 
			mem_hanzi[  16] ={8'h40,8'h30,8'hEF,8'h24,8'h24,8'h00,8'hFE,8'h92};//閿娇娉2 3
			mem_hanzi[  17] ={8'h92,8'h92,8'hF2,8'h92,8'h92,8'h9E,8'h80,8'h00};
			mem_hanzi[  18] ={8'h40,8'h40,8'h40,8'h7C,8'h40,8'h40,8'h40,8'h7F};
			mem_hanzi[  19] ={8'h44,8'h44,8'h44,8'h44,8'h44,8'h40,8'h40,8'h00};
			mem_hanzi[  20] ={8'h10,8'h60,8'h02,8'h0C,8'hC0,8'h00,8'hF8,8'h88};
			mem_hanzi[  21] ={8'h88,8'h88,8'hFF,8'h88,8'h88,8'hA8,8'h18,8'h00};
			mem_hanzi[  22] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
			mem_hanzi[  23] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};			
			mem_hanzi[  24] ={8'h01,8'h01,8'h7F,8'h21,8'h91,8'h60,8'h1F,8'h00};
			mem_hanzi[  25] ={8'hFC,8'h44,8'h47,8'h44,8'h44,8'hFC,8'h00,8'h00};
			mem_hanzi[  26] ={8'h00,8'h00,8'h7F,8'h40,8'h50,8'h48,8'h44,8'h43};
			mem_hanzi[  27] ={8'h44,8'h48,8'h50,8'h40,8'hFF,8'h00,8'h00,8'h00};
			mem_hanzi[  28] ={8'h04,8'h04,8'h7C,8'h03,8'h80,8'h60,8'h1F,8'h80}; 
			mem_hanzi[  29] ={8'h43,8'h2C,8'h10,8'h28,8'h46,8'h81,8'h80,8'h00};/*"�??,2*/
			mem_hanzi[  30] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
			mem_hanzi[  31] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
 
			mem_hanzi[  32] ={8'h00,8'h04,8'h84,8'h84,8'h84,8'h84,8'h84,8'h84};  //涓夎娉5
			mem_hanzi[  33] = {8'h84,8'h84,8'h84,8'h84,8'h84,8'h04,8'h00,8'h00};
			mem_hanzi[  34] ={8'h20,8'h10,8'hE8,8'h24,8'h27,8'h24,8'h24,8'hE4};
			mem_hanzi[  35] ={8'h24,8'h34,8'h2C,8'h20,8'hE0,8'h00,8'h00,8'h00};
			mem_hanzi[  36] ={8'h10,8'h60,8'h02,8'h0C,8'hC0,8'h00,8'hF8,8'h88};
			mem_hanzi[  37] ={8'h88,8'h88,8'hFF,8'h88,8'h88,8'hA8,8'h18,8'h00};
			mem_hanzi[  38] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
			mem_hanzi[  39] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};			
			mem_hanzi[  40] ={8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20};
			mem_hanzi[  41] ={8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h20,8'h00};
			mem_hanzi[  42] ={8'h80,8'h60,8'h1F,8'h09,8'h09,8'h09,8'h09,8'h7F};
			mem_hanzi[  43] ={8'h09,8'h09,8'h49,8'h89,8'h7F,8'h00,8'h00,8'h00};/*"�??,4*/
			mem_hanzi[  44] ={8'h04,8'h04,8'h7C,8'h03,8'h80,8'h60,8'h1F,8'h80};
			mem_hanzi[  45] ={8'h43,8'h2C,8'h10,8'h28,8'h46,8'h81,8'h80,8'h00};/*"�??,5*/
			mem_hanzi[  46] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
			mem_hanzi[  47] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};			
 
			mem_hanzi[  48] ={8'h08,8'h08,8'h08,8'h08,8'h08,8'hF8,8'h89,8'h8E};
			mem_hanzi[  49] ={8'h88,8'h88,8'h88,8'h88,8'h08,8'h08,8'h08,8'h00};
			mem_hanzi[  50] ={8'h10,8'h60,8'h02,8'h0C,8'hC0,8'h00,8'hF8,8'h88}; 
			mem_hanzi[  51] ={8'h88,8'h88,8'hFF,8'h88,8'h88,8'hA8,8'h18,8'h00};
			mem_hanzi[  52] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
			mem_hanzi[  53] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};	
			mem_hanzi[  54] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
			mem_hanzi[  55] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};						
			mem_hanzi[  56] ={8'h00,8'h80,8'h40,8'h20,8'h18,8'h07,8'h00,8'h00};
			mem_hanzi[  57] ={8'h40,8'h80,8'h40,8'h3F,8'h00,8'h00,8'h00,8'h00};/*"�??,6*/
			mem_hanzi[  58] ={8'h04,8'h04,8'h7C,8'h03,8'h80,8'h60,8'h1F,8'h80};
			mem_hanzi[  59] = {8'h43,8'h2C,8'h10,8'h28,8'h46,8'h81,8'h80,8'h00};/*"�??,7*/
			mem_hanzi[  60] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
			mem_hanzi[  61] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};	
			mem_hanzi[  62] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
			mem_hanzi[  63] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
 
 
			mem_hanzi[  64] ={8'h00,8'h02,8'h02,8'hC2,8'h02,8'h02,8'h02,8'hFE};//姝ｅ鸡娉89
			mem_hanzi[  65] ={8'h82,8'h82,8'h82,8'h82,8'h82,8'h02,8'h00,8'h00};
			mem_hanzi[  66] ={8'h02,8'hE2,8'h22,8'h22,8'h3E,8'h00,8'h08,8'h88};
			mem_hanzi[  67] = {8'h48,8'h39,8'h0E,8'h08,8'hC8,8'h08,8'h08,8'h00};
			mem_hanzi[  68] ={8'h10,8'h60,8'h02,8'h0C,8'hC0,8'h00,8'hF8,8'h88}; 
			mem_hanzi[  69] ={8'h88,8'h88,8'hFF,8'h88,8'h88,8'hA8,8'h18,8'h00};
			mem_hanzi[  70] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
			mem_hanzi[  71] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};			
			mem_hanzi[  72] ={8'h40,8'h40,8'h40,8'h7F,8'h40,8'h40,8'h40,8'h7F};
			mem_hanzi[  73] ={8'h40,8'h40,8'h40,8'h40,8'h40,8'h40,8'h40,8'h00};/*"�??,8*/
			mem_hanzi[  74] ={8'h00,8'h43,8'h82,8'h42,8'h3E,8'h00,8'h21,8'h71};
			mem_hanzi[  75] ={8'h29,8'h25,8'h23,8'h21,8'h28,8'h70,8'h00,8'h00};/*"�??,9*/
			mem_hanzi[  76] ={8'h04,8'h04,8'h7C,8'h03,8'h80,8'h60,8'h1F,8'h80};
			mem_hanzi[  77] ={8'h43,8'h2C,8'h10,8'h28,8'h46,8'h81,8'h80,8'h00};/*"�??,10*/
			mem_hanzi[  78] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};
			mem_hanzi[  79] ={8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00,8'h00};			
 
		end
endmodule