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

    // 行计数器回绕条件
    assign Hrolloveri = (HCOORD == 10'd799);  // 640x480 VGA中，HCOORD最大值是799
    // 场计数器回绕条件
    assign Vrolloveri = (VCOORD == 10'd524);  // 480行中，VCOORD最大值是524

    // 处理HCOORD的计数
    always @(posedge CLKOUT or posedge aclri) begin
        if (aclri) begin
            HCOORD <= 10'b0000000000;  
        end else if (Hrolloveri) begin
            HCOORD <= 10'b0000000000;  
        end else begin
            HCOORD <= HCOORD + 1;  // 否则继续计数
        end
    end

    // 处理VCOORD的计数
    always @(posedge CLKOUT or posedge aclri) begin
        if (aclri) begin
            VCOORD <= 10'b0000000000;  // 复位VCOORD
        end else if (Vrolloveri) begin
            VCOORD <= 10'b0000000000;  // VCOORD回绕
        end else begin
            VCOORD <= VCOORD + 1;  
        end
    end

    // 行同步信号生成
    assign HSYNC = (HCOORD >= 10'd656) ? 1'b0 : 1'b1; // VGA行同步信号
    // 场同步信号生成
    assign VSYNC = (VCOORD >= 10'd490) ? 1'b0 : 1'b1; // VGA场同步信号

    always @(posedge CLKOUT or posedge aclri) begin
        if (aclri) begin
            RED   <= 4'h0;
            GREEN <= 4'h0;
            BLUE  <= 4'h0;
        end else if ((HCOORD > 10'd640) || (VCOORD > 10'd480)) begin
            RED   <= 4'h0;
            GREEN <= 4'h0;
            BLUE  <= 4'h0;  // 边界外区域显示黑色
        end else if ((HCOORD < 10'd320) || (VCOORD < 10'd240)) begin
            RED   <= 4'h0;
            GREEN <= 4'hF;  // 上半部分显示绿色
            BLUE  <= 4'h0;
        end else begin
            RED   <= CSEL[11:8];
            GREEN <= CSEL[7:4];
            BLUE  <= CSEL[3:0];
        end
    end

    // 时钟分频
    reg SREG;
    reg CLKOUT;  // 4分频时钟输出

    // 2分频
    always @(posedge CLK or posedge aclri) begin
        if (aclri) begin
            SREG <= 1'b0;
        end else begin
            SREG <= ~SREG;
        end
    end

    // 4分频
    always @(posedge CLK or posedge aclri) begin
        if (aclri) begin
            CLKOUT <= 1'b0;
        end else if (SREG) begin
            CLKOUT <= ~CLKOUT;
        end
    end

endmodule
