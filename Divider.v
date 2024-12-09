`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/09 21:49:46
// Design Name: 
// Module Name: Divider
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
module Divider(
    input I_CLK,
    input rst,
    output reg O_CLK
);
    // ����ͨ������ N �����÷�Ƶϵ��
    parameter N = 100000000; 
    integer count = 0;

    always @(negedge rst or posedge I_CLK) begin
        if (!rst)
            O_CLK = 0;
        else begin
            if (count == N) begin
                O_CLK = ~O_CLK;
                count = 0;
            end else begin
                count = count + 1;
            end
        end
    end
endmodule

