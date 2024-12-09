`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/09 20:34:03
// Design Name: 
// Module Name: VGAxianshi
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


module VGAxianshi(
    input CLK,             
    input [11:0] CSEL,     
    input ARSTL,          
    output HSYNC,          
    output VSYNC,          
    output reg [3:0] RED,  
    output reg [3:0] GREEN, 
    output reg [3:0] BLUE,  
    output reg [9:0] HCOORD, 
    output reg [9:0] VCOORD  
);
    wire aclri;
    wire Hrolloveri, Vrolloveri;  

    // Reset signal
    assign aclri = ~ARSTL;         

    // �м�������������
    assign Hrolloveri = (HCOORD == 10'd799);  // 640x480 VGA�У�HCOORD���ֵ��799
    // ����������������
    assign Vrolloveri = (VCOORD == 10'd524);  // 480���У�VCOORD���ֵ��524

    // ����HCOORD�ļ���
    always @(posedge CLKOUT or posedge aclri) begin
        if (aclri) begin
            HCOORD <= 10'b0000000000;  
        end else if (Hrolloveri) begin
            HCOORD <= 10'b0000000000;  
        end else begin
            HCOORD <= HCOORD + 1;  // �����������
        end
    end

    // ����VCOORD�ļ���
    always @(posedge CLKOUT or posedge aclri) begin
        if (aclri) begin
            VCOORD <= 10'b0000000000;  // ��λVCOORD
        end else if (Vrolloveri) begin
            VCOORD <= 10'b0000000000;  // VCOORD����
        end else begin
            VCOORD <= VCOORD + 1;  
        end
    end

    // ��ͬ���ź�����
    assign HSYNC = (HCOORD >= 10'd656) ? 1'b0 : 1'b1; // VGA��ͬ���ź�
    // ��ͬ���ź�����
    assign VSYNC = (VCOORD >= 10'd490) ? 1'b0 : 1'b1; // VGA��ͬ���ź�

    always @(posedge CLKOUT or posedge aclri) begin
        if (aclri) begin
            RED   <= 4'h0;
            GREEN <= 4'h0;
            BLUE  <= 4'h0;
        end else if ((HCOORD > 10'd640) || (VCOORD > 10'd480)) begin
            RED   <= 4'h0;
            GREEN <= 4'h0;
            BLUE  <= 4'h0;  // �߽���������ʾ��ɫ
        end else if ((HCOORD < 10'd320) || (VCOORD < 10'd240)) begin
            RED   <= 4'h0;
            GREEN <= 4'hF;  // �ϰ벿����ʾ��ɫ
            BLUE  <= 4'h0;
        end else begin
            RED   <= CSEL[11:8];
            GREEN <= CSEL[7:4];
            BLUE  <= CSEL[3:0];
        end
    end

    // ʱ�ӷ�Ƶ
    reg SREG;
    reg CLKOUT;  // 4��Ƶʱ�����

    // 2��Ƶ
    always @(posedge CLK or posedge aclri) begin
        if (aclri) begin
            SREG <= 1'b0;
        end else begin
            SREG <= ~SREG;
        end
    end

    // 4��Ƶ
    always @(posedge CLK or posedge aclri) begin
        if (aclri) begin
            CLKOUT <= 1'b0;
        end else if (SREG) begin
            CLKOUT <= ~CLKOUT;
        end
    end

endmodule
