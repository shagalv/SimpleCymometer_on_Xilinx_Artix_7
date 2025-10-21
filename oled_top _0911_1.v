module oled_top(
    input clkin_50m,
    input sys_rst_n,       //系统复位时钟         
    input [29:0] data,    //外部输入待显示的二进制数据

    output miso,
    output reg reset_oled,
    output dc,
    output cs,
    output sck              //SPI的时钟输出
    );

	wire sck_reg;           //内部生成的SPI时钟域
    reg [31:0]reset_count;
    initial reset_count=0;
    reg reset_n;
    initial reset_n=0;//这是模块内部生成的控制信号
    
    always@(posedge clkin_50m)
        if(reset_count>=30000)
            reset_count<=30000;
        else reset_count<=reset_count+1;
    
    always@(posedge clkin_50m)
        if(reset_count==10)
        begin
            reset_oled<=1;
            reset_n<=1;
        end
        else if(reset_count==10000)
        begin
            reset_oled<=0;
            reset_n<=0;
        end
        else if(reset_count==20000)
            reset_oled<=1;
        else if(reset_count==30000)
            reset_n<=1;
    
    reg spi_send;
    reg [7:0]spi_data_out;
    wire spi_send_done;
    reg dc_in;
    wire reset=!reset_n;
    
    spi_master spi_master
    (
        //SPI总线信号
        .sck    (sck),         //1MHz clk
        .miso   (miso),
        .cs     (cs),
        .rst    (1),      
        .spi_send   (spi_send),
        .spi_data_out   (spi_data_out),
        .spi_send_done  (spi_send_done),
        .clk    (clkin_50m),
        .dc_in  (dc_in),
        .dc_out (dc),
        .sck_reg    (sck_reg)
    
    );
    
    wire spi_send_init;
    wire [7:0]spi_data_init;
    wire init_done;
    wire dc_init;
    
    oled_init oled_init
    (
        .send_done  (spi_send_done),
        .spi_send   (spi_send_init),
        .spi_data   (spi_data_init),
        .clk        (sck_reg),
        .init_done  (init_done),
        .dc         (dc_init),
        .reset      (reset)
    );

    // 二进制转BCD码模块实例化
// 功能：将输入的30位二进制数据转换为BCD码格式

wire [35:0] bcd_data ;      // 定义36位数据接收BCD编码后的数据（36位）
//将输入该LCD模块的二进制数据data转化为36位BCD码
binary2bcd u_binary2bcd(
    .sys_clk (clkin_50m),
    .sys_rst_n (sys_rst_n),
    .data (data ),
    .bcd_data (bcd_data)
);
    
    wire spi_send_write;
    wire [7:0]spi_data_write;
    wire dc_write;
    wire write_done;
    reg [47:0]write_data;
    reg [7:0]set_pos_x,set_pos_y;
    reg write_start;
    wire spi_send_clear;
    wire [7:0]spi_data_clear;
    wire dc_clear;
    reg clear_start;
    wire clear_done;
    
    oled_write_data oled_write_data(
        .send_done  (spi_send_done),
        .spi_send   (spi_send_write),
        .spi_data   (spi_data_write),
        .clk        (sck_reg),
        .dc         (dc_write),
        .write_start(write_start),
        .write_done (write_done),
        .write_data (write_data),
        .set_pos_x  (set_pos_x),
        .set_pos_y  (set_pos_y),
        .reset  (reset)
    );    
    
    oled_clear oled_clear
    (
            .send_done  (spi_send_done),
            .spi_send   (spi_send_clear),
            .spi_data   (spi_data_clear),
            .clk        (sck_reg),
            .dc         (dc_clear),
            .clear_start(clear_start),
            .clear_done (clear_done),
            .reset  (reset)
    
    
    );
    
     localparam 
	    CHAR_0 = 48'h38_44_44_44_38_00,   // 0
        CHAR_1 = 48'h00_48_7C_40_00_00,   // 1
        CHAR_2 = 48'h48_64_64_54_4C_00,   // 2
        CHAR_3 = 48'h28_44_4C_4C_34_00,   // 3
        CHAR_4 = 48'h10_28_24_7C_20_00,   // 4
        CHAR_5 = 48'h3C_54_54_54_34_00,   // 5
        CHAR_6 = 48'h38_54_54_54_30_00,   // 6
        CHAR_7 = 48'h0C_04_74_0C_04_00,   // 7
        CHAR_8 = 48'h2C_54_54_54_6C_00,   // 8
        CHAR_9 = 48'h18_54_54_54_38_00;   // 9
    
    // 字模查找函数
function [47:0] get_char_mapping;//函数返回值的位宽
    input [3:0] digit;//输入参数
    begin
        case(digit)
            4'd0: get_char_mapping = CHAR_0;
            4'd1: get_char_mapping = CHAR_1;
            4'd2: get_char_mapping = CHAR_2;
            4'd3: get_char_mapping = CHAR_3;
            4'd4: get_char_mapping = CHAR_4;
            4'd5: get_char_mapping = CHAR_5;
            4'd6: get_char_mapping = CHAR_6;
            4'd7: get_char_mapping = CHAR_7;
            4'd8: get_char_mapping = CHAR_8;
            4'd9: get_char_mapping = CHAR_9;
            default: get_char_mapping = CHAR_0;
        endcase
    end
endfunction

parameter S_IDLE        = 4'd0;
parameter S_CLEAR       = 4'd1;
parameter S_DISPLAY_0   = 4'd2;
parameter S_DISPLAY_1   = 4'd3;
parameter S_DISPLAY_2   = 4'd4;
parameter S_DISPLAY_3   = 4'd5;
parameter S_DISPLAY_4   = 4'd6;
parameter S_DISPLAY_5   = 4'd7;
parameter S_DISPLAY_6   = 4'd8;
parameter S_DISPLAY_7   = 4'd9;
parameter S_DISPLAY_8   = 4'd10;
parameter S_DONE        = 4'd11;

    reg [5:0]current_state,next_state;
    reg [3:0] digit_index;         // 当前显示的数字索引，36位BCD码，显示9位
    reg [7:0] base_x;              // 基准X坐标
    reg [7:0] base_y;              // 基准Y坐标

    initial begin current_state=0;next_state=0;end
    always@(posedge sck_reg)begin
        if(reset)  begin
        current_state <= S_IDLE;
        digit_index <= 3'd0;
        base_x <= 8'd10;      // 默认起始X坐标
        base_y <= 8'd2;       // 默认起始Y坐标
        end
        else begin
        current_state<=next_state;
        if (current_state >= S_DISPLAY_0 && current_state <= S_DISPLAY_7) begin
            digit_index <= digit_index + 1;
        end 
        else if (current_state == S_IDLE) begin
            digit_index <= 3'd0;//将显示的索引清零
        end
    end
end

  /*  always@(*)
    begin
        nxt_st=cur_st;
        case(cur_st)
            0:if(init_done)     nxt_st=1;           //进入oled的清屏环节
            1:if(clear_done)    nxt_st=nxt_st+1;    //清屏结束，开始写状态
            2:if(write_done)    nxt_st=nxt_st+1;
            3:if(write_done)    nxt_st=nxt_st+1;
            4:if(write_done)    nxt_st=nxt_st+1;
            5:if(write_done)    nxt_st=nxt_st+1;
            6:if(write_done)    nxt_st=nxt_st+1;
            7:if(write_done)    nxt_st=nxt_st+1;
            8:nxt_st=8;
        default:nxt_st=0;
        endcase
    end*/
// ==================== 状态转移逻辑 ====================
always @(*) begin
    next_state = current_state;
    case (current_state)
        S_IDLE:begin 
            if (init_done)//这两个信号是输入信号，均为1才会继续向下执行代码
                next_state = S_CLEAR;
            else
                next_state = S_IDLE;
        end
        S_CLEAR:begin 
            if (clear_done)  // 清屏启动确认
                next_state = S_DISPLAY_0;  //是否会进入下一个状态取决于clear_start这里会一直循环，
                                            //而该值是由本文件中的代码赋予
            else
                next_state = S_CLEAR;
        end
        
        S_DISPLAY_0: begin
            if (write_done)  // 写入启动确认
                next_state = S_DISPLAY_1;
            else
                next_state = S_DISPLAY_0;
         end    

        S_DISPLAY_1: begin
            if (write_done)  // 写入启动确认
                next_state = S_DISPLAY_2;
            else
                next_state = S_DISPLAY_1;
         end    
            
        S_DISPLAY_2: begin
            if (write_done)  // 写入启动确认
                next_state = S_DISPLAY_3;
            else
                next_state = S_DISPLAY_2;
         end    
        S_DISPLAY_3: begin
            if (write_done)  // 写入启动确认
                next_state = S_DISPLAY_4;
            else
                next_state = S_DISPLAY_3;
         end    
        S_DISPLAY_4: begin
            if (write_done)  // 写入启动确认
                next_state = S_DISPLAY_5;
            else
                next_state = S_DISPLAY_4;
         end    
        S_DISPLAY_5: begin
            if (write_done)  // 写入启动确认
                next_state = S_DISPLAY_6;
            else
                next_state = S_DISPLAY_5;
         end    
        S_DISPLAY_6: begin
            if (write_done)  // 写入启动确认
                next_state = S_DISPLAY_7;
            else
                next_state = S_DISPLAY_6;
         end   
        S_DISPLAY_7: begin
            if (write_done)  // 写入启动确认
                next_state = S_DISPLAY_8;
            else
                next_state = S_DISPLAY_7;
         end     
        S_DISPLAY_8: begin
            if (write_done)  // 写入启动确认
                next_state = S_DONE;
            else
                next_state = S_DISPLAY_8;
         end    
        
        S_DONE: 
            next_state = S_DONE;
            
        default: 
            next_state = S_IDLE;
    endcase
end

//输出控制逻辑
    always@(*)
        if(reset)
        begin
            set_pos_x=0;
            set_pos_y=0;
            write_data=0;
            write_start=0;
        end
        else case(current_state)
            S_DISPLAY_0, S_DISPLAY_1, S_DISPLAY_2, S_DISPLAY_3,
            S_DISPLAY_4, S_DISPLAY_5, S_DISPLAY_6, S_DISPLAY_7,S_DISPLAY_6, S_DISPLAY_8: begin
                // 计算当前位置
                set_pos_x <= base_x + (digit_index * 8); // 每个字符间隔8像素
                set_pos_y <= base_y;
                
                // 获取对应的BCD数字并查找字模
                case (digit_index)
                    3'd0: write_data <= get_char_mapping(bcd_data[31:28]);
                    3'd1: write_data <= get_char_mapping(bcd_data[27:24]);
                    3'd2: write_data <= get_char_mapping(bcd_data[23:20]);
                    3'd3: write_data <= get_char_mapping(bcd_data[19:16]);
                    3'd4: write_data <= get_char_mapping(bcd_data[15:12]);
                    3'd5: write_data <= get_char_mapping(bcd_data[11:8]);
                    3'd6: write_data <= get_char_mapping(bcd_data[7:4]);
                    3'd7: write_data <= get_char_mapping(bcd_data[3:0]);
                endcase
                    write_start <= 1'b1;  // 发出写入脉冲
            end
        endcase
        
        always@(*)
            if(reset) clear_start=0;
            else if(current_state==S_CLEAR) clear_start=1;
            else clear_start=0;
        
        always@(*)
            if(reset)   dc_in=0;
            else if(current_state==S_IDLE)  dc_in=dc_init;
            else if(current_state==S_CLEAR)  dc_in=dc_clear;
            else if(current_state==S_DISPLAY_0 | current_state==S_DISPLAY_1 | current_state==S_DISPLAY_2 | 
            current_state==S_DISPLAY_3 | current_state==S_DISPLAY_4 | current_state==S_DISPLAY_5| 
            current_state==S_DISPLAY_6|current_state==S_DISPLAY_7|current_state==S_DISPLAY_8)  dc_in=dc_write;
            else if(current_state==S_DONE)  dc_in=0;
            else dc_in=0;
        
        always@(*)
            if(reset)   spi_data_out=0;
            else if(current_state==S_IDLE)  spi_data_out=spi_data_init;
            else if(current_state==S_CLEAR)  spi_data_out=spi_data_clear;
            else if(current_state==S_DISPLAY_0 | current_state==S_DISPLAY_1 | current_state==S_DISPLAY_2 | 
            current_state==S_DISPLAY_3 | current_state==S_DISPLAY_4 | current_state==S_DISPLAY_5| 
            current_state==S_DISPLAY_6|current_state==S_DISPLAY_7|current_state==S_DISPLAY_8)   spi_data_out=spi_data_write;
            else if(current_state==S_DONE)  spi_data_out=0;
           // else spi_data_out=write_data;
		   else spi_data_out=0;
        
        always@(*)
            if(reset) spi_send=0;
            else if(current_state==S_IDLE) spi_send=spi_send_init;
            else if(current_state==S_CLEAR) spi_send=spi_send_clear;
            else if(current_state==S_DISPLAY_0 | current_state==S_DISPLAY_1 | current_state==S_DISPLAY_2 | 
            current_state==S_DISPLAY_3 | current_state==S_DISPLAY_4 | current_state==S_DISPLAY_5| 
            current_state==S_DISPLAY_6|current_state==S_DISPLAY_7|current_state==S_DISPLAY_8)  spi_send=spi_send_write;
            else if(current_state==S_DONE) spi_send=0;
        
endmodule
    