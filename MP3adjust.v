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
    input clk,                      // ʱ���ź�
    input [3:0] hex1,               // ʮ�����Ƶĸ�4λ
    input [3:0] hex0,               // ʮ�����Ƶĵ�4λ
    input keyup,                    // ����̧���ź�
    output reg [3:0] volclass = 9,  // �����ȼ�����ʼ�������
    output reg [15:0] vol = 16'h0000 // ������ֵ
);

    wire [15:0] adjustedvol;    // �����������
    wire CLK1M;                 // ��Ƶ���1 MHzʱ���ź�
    integer clkcnt = 0;         // ʱ�����ڼ�����������������ʱ

    // 1 MHz ʱ�ӷ�Ƶģ��
    Divider #(.N(100)) CLKDIV1(
        .clk(clk),
        .reset(1'b1),           // ��������ź�����Ҫ�ģ����忴 Divider ģ���ʵ��
        .clk_out(CLK1M)
    );

    assign adjustedvol = vol;   // ʵʱ�洢ԭ������С

    always @(posedge CLK1M) begin
        if (clkcnt == 200000) begin
            clkcnt <= 0;        // ����ʱ�Ӽ�����
            if (!keyup) begin   // �жϰ����Ƿ���
                case({hex1, hex0}) // ����ֵ���
                    8'b01110101: begin // A ����
                        vol <= (vol == 16'h0000) ? 16'h0000 : (vol - 16'h197F);
                    end
                    8'b01110010: begin // B ����
                        vol <= (vol == 16'hFEFE) ? 16'hFEFE : (vol + 16'h197F);
                    end
                    default: begin
                        // ��������������
                    end
                endcase
            end
        end else begin
            clkcnt <= clkcnt + 1; // ����ʱ�Ӽ���
        end
    end

    always @(vol) begin
        case(vol)
            16'hE577: volclass <= 1;
            16'hB279: volclass <= 3;
            16'h7F7B: volclass <= 5;
            16'h4C7D: volclass <= 7;
            16'h197F: volclass <= 9;
            default: volclass <= 0; // Ĭ�������ȼ�Ϊ 0
        endcase
    end

endmodule
