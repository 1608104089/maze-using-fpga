`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/09 21:59:59
// Design Name: 
// Module Name: SwitchDB
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
module SwitchDB(
input CLK,//ϵͳʱ��
input SW,//�Ƿ��ȡ��������Ϣ��1 Ϊ��ȡ��
input ACLR_L,//�����ź�
output reg SWDB//ȥ���ź�
);
wire aclr_i;
reg CLKOUT;
reg [1:0] Q_CURR;//״̬����״̬
parameter [1:0] SW_OFF = 2'b00; //״̬������
parameter [1:0] SW_EDGE = 2'b01;
parameter [1:0] SW_VERF = 2'b10;
parameter [1:0] SW_HOLD = 2'b11;
assign aclr_i = ~ACLR_L;
//״̬ת��
always @(posedge CLKOUT or posedge aclr_i) begin
 SWDB <= 1'b0; //Ĭ��Ϊ 0
 if(aclr_i) begin
 Q_CURR <= SW_OFF;
 end
 else begin
 case(Q_CURR) 
 SW_OFF: if(SW) begin
 Q_CURR <= SW_EDGE;
 end
 else begin
 Q_CURR <= SW_OFF;
 end
 
 SW_EDGE: if(SW) begin
 Q_CURR <= SW_VERF;
 SWDB <= 1'b1; 
//ȥ���źŽ��ڵ�ǰ״̬Ϊ SW_VERF ʱΪ��
 end
 else begin
 Q_CURR <= SW_OFF;
 end
 
 SW_VERF: Q_CURR <= SW_HOLD;
 
 SW_HOLD: if(SW) begin
 Q_CURR <= SW_HOLD;
 end
 else begin
 Q_CURR <= SW_OFF;
 end
 endcase 
 end
end
reg SREG;
//ʱ�ӷ�Ƶ
//2 ��Ƶ
always @(posedge CLK or posedge aclr_i) begin
 if(aclr_i) begin
 SREG <= 1'b0;
 end
 else begin
 SREG <= ~SREG;
 end
end
//4 ��Ƶ
always @(posedge CLK or posedge aclr_i) begin
 if(aclr_i) begin
 CLKOUT <= 1'b0;
 end
 else if(SREG) begin
 CLKOUT <= ~CLKOUT;
 end
end
endmodule

