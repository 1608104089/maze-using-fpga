`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/09 21:01:13
// Design Name: 
// Module Name: MP3adjust
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module MP3adjust(
    input clk,                      // 时钟信号
    input [3:0] hex1,               // 十六进制的高4位
    input [3:0] hex0,               // 十六进制的低4位
    input keyup,                    // 按键抬起信号
    output reg [3:0] volclass = 9,  // 音量等级，初始最大音量
    output reg [15:0] vol = 16'h0000 // 音量数值
);

    wire [15:0] adjustedvol;    // 调整后的音量
    wire CLK1M;                 // 分频后的1 MHz时钟信号
    integer clkcnt = 0;         // 时钟周期计数器，用于设置延时

    // 1 MHz 时钟分频模块
    Divider #(.N(100)) CLKDIV1(
        .clk(clk),
        .reset(1'b1),           // 假设这个信号是需要的，具体看 Divider 模块的实现
        .clk_out(CLK1M)
    );

    assign adjustedvol = vol;   // 实时存储原音量大小

    always @(posedge CLK1M) begin
        if (clkcnt == 200000) begin
            clkcnt <= 0;        // 重置时钟计数器
            if (!keyup) begin   // 判断按键是否按下
                case({hex1, hex0}) // 按键值组合
                    8'b01110101: begin // A 按键
                        vol <= (vol == 16'h0000) ? 16'h0000 : (vol - 16'h197F);
                    end
                    8'b01110010: begin // B 按键
                        vol <= (vol == 16'hFEFE) ? 16'hFEFE : (vol + 16'h197F);
                    end
                    default: begin
                        // 不处理其他按键
                    end
                endcase
            end
        end else begin
            clkcnt <= clkcnt + 1; // 增加时钟计数
        end
    end

    always @(vol) begin
        case(vol)
            16'hE577: volclass <= 1;
            16'hB279: volclass <= 3;
            16'h7F7B: volclass <= 5;
            16'h4C7D: volclass <= 7;
            16'h197F: volclass <= 9;
            default: volclass <= 0; // 默认音量等级为 0
        endcase
    end

endmodule
