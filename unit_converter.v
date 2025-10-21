//科学计数法显示数据
module unit_converter(
    input[29:0] cycle_fx,     //输入的待测信号周期，在cymometer中定义为0.01us为单位\
    output[3:0] unit,         //10的负指数，单位为s
    output[9:0] cycle_final   //最终用于显示的数字(0-1000)，传递给OLED
);
always@(*)
begin
    if(cycle_fx < 10)begin //0.01 - 0.1 us , 10-100MHz
        unit = 4'd0;
        cycle_final = cycle_final; 
    end
    else if(10 <= cycle_fx < 100)begin //0.1 - 1us , 1-10MHz
        unit = 4'd1;
        cycle_final = cycle_final / 10;
    end
    else if(100 <= cycle_fx < 1000)begin // 1-10 us , 100kHz - 1MHz
        unit = 4'd2;
        cycle_final = cycle_final / 100;
    end
    else if(1000 <= cycle_fx < 10_000)begin // 10-100us , 10kHz - 100kHz
        unit = 4'd3;
        cycle_final = cycle_final / 1_000;
    end
    else if(10_000 <= cycle_fx < 100_000)begin // 100-1000us , 1kHz - 10kHz
        unit = 4'd4;
        cycle_final = cycle_final / 10_000;
    end
    else if(100_000 <= cycle_fx < 1_000_000)begin // 1000-10_000us , 100Hz - 1kHz
        unit = 4'd5;
        cycle_final = cycle_final / 100_000;
    end
    else if(1_000_000 <= cycle_fx <= 10_000_000)begin // 10_000 - 100_000us , 10Hz - 100Hz
        unit = 4'd6;
        cycle_final = cycle_final / 1_000_000;
    end
    else if(10_000_000 <= cycle_fx <= 100_000_000)begin // 100_000 - 1_000_000us , 1 - 10Hz
        unit = 4'd7;
        cycle_final = cycle_final / 10_000_000;
    end
    else begin   //0.1 - 1Hz
        unit = 4'd8;
        cycle_final = cycle_final / 100_000_000;
    end
    end
end

endmodule