`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/10 14:43:00
// Design Name: 
// Module Name: maze
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


module maze(
    input CLK,                  // ϵͳʱ��
    input [3:0] ROW,            // �����������ź�
    output [3:0] COL,           // ����������ź�
    input ARSTL,                // �첽��λ�ź�
    input [3:0] hex0,           // 16���Ƽ����λ
    input [3:0] hex1,           // 16���Ƽ����λ
    input keyup,                // ����̧���ź�
    output [15:0] vol,          // ������ֵ
    output [3:0] volclass,      // �����ȼ�
    output [3:0] tune,          // ��ǰ����
    output [3:0] HEX0,          // 16���ư�����
    output [3:0] HEX1,          // 16���ư�����
    output KEYUP,               // ���̰�����Ч��־
    output XRSET,               // MP3Ӳ����λ
    output XCS,                 // MP3Ƭѡ�ź�
    output XDCS,                // MP3����ͬ��
    output SI,                  // MP3������������
    output SCLK,                // MP3 SPIʱ��
    output [6:0] LED_OUT,       // �߶���ʾ�����
    output [11:0] CSEL,         // VGA��ɫ���
    output HSYNC,               // VGA��ͬ��
    output VSYNC,               // VGA��ͬ��
    output [3:0] RED,           // VGA��ɫ����
    output [3:0] GREEN,         // VGA��ɫ����
    output [3:0] BLUE,          // VGA��ɫ����
    output [9:0] HCOORD,        // VGA������
    output [9:0] VCOORD,        // VGA������
    output click,               // ��������ź�
    output [5:0] ballX_now,     // С�������
    output [5:0] ballY_now      // С��������
);

    // �����ź�
    wire kbstrobe_i;            // ȥ�����ź�
    wire [15:0] adjusted_vol;   // �����������
    wire [9:0] HCOORD_VGA, VCOORD_VGA;  // VGA����
    wire [7:0] KBCODE;          // ������
    wire [5:0] ballX, ballY;    // С������
    wire [11:0] CSEL_internal;  // VGA��ɫ�ź�
    wire click_internal;        // ��������ź�
    wire DIV_CLK;               // ��Ƶʱ�����

    // ʵ����ȥ����ģ�� SwitchDB
    SwitchDB switch_debounce (
        .CLK(CLK),
        .SW(keyup),
        .ACLR_L(ARSTL),
        .SWDB(kbstrobe_i)
    );

    // ʵ���� MP3adjust ��������ģ��
    MP3adjust mp3_adjust (
        .clk(CLK),
        .hex1(hex1),
        .hex0(hex0),
        .keyup(keyup),
        .volclass(volclass),
        .vol(adjusted_vol)
    );

    // ʵ���� MP3 ����ģ��
    MP3 mp3_player (
        .CLK(CLK),
        .kbstrobe_i(kbstrobe_i),
        .DREQ(1'b1), // ���������źţ�����Ϊ 1 ��ʾ������������
        .XRSET(XRSET),
        .XCS(XCS),
        .XDCS(XDCS),
        .SI(SI),
        .SCLK(SCLK),
        .init(1'b1), // �����ʼ���ź�Ϊ��
        .hex1(hex1),
        .hex0(hex0),
        .adjusted_vol(adjusted_vol),
        .keyup(keyup),
        .tune(tune)
    );

    // ʵ���� kypdkeyboard ����ɨ��ģ��
    kypdkeyboard keyboard (
        .CLK(CLK),
        .ROW(ROW),
        .COL(COL),
        .ARSTL(ARSTL),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .KEYUP(KEYUP)
    );

    // ʵ���� LED ��ʾģ��
    LED led_display (
        .iData(volclass),   // ʹ�������ȼ���Ϊ����
        .init(ARSTL),        // ʹ�ø�λ�ź���Ϊ��ʼ���ź�
        .oData(LED_OUT)      // ������߶���ʾ��
    );

    // ʵ���� VGAxianshi ģ��
    VGAxianshi vga_display (
        .CLK(DIV_CLK),        // ʹ�÷�Ƶ���ʱ��
        .CSEL(CSEL_internal),
        .ARSTL(ARSTL),
        .HSYNC(HSYNC),
        .VSYNC(VSYNC),
        .RED(RED),
        .GREEN(GREEN),
        .BLUE(BLUE),
        .HCOORD(HCOORD_VGA),
        .VCOORD(VCOORD_VGA)
    );

    // ʵ���� VGAcontrol ģ��
    VGAcontrol vga_control (
        .CLK(DIV_CLK),        // ʹ�÷�Ƶ���ʱ��
        .kbstrobe_i(kbstrobe_i),
        .KBCODE(KBCODE),
        .HCOORD(HCOORD_VGA),
        .VCOORD(VCOORD_VGA),
        .ARST_L(ARSTL),
        .ballX(ballX),
        .ballY(ballY),
        .ballX_now(ballX_now),
        .ballY_now(ballY_now),
        .CSEL(CSEL_internal),
        .click(click_internal)
    );

    // ʵ���� Divider ��Ƶģ��
    Divider divider_inst (
        .I_CLK(CLK),        // ϵͳʱ�����ӵ� Divider ����
        .rst(ARSTL),         // ��λ�ź�
        .O_CLK(DIV_CLK)      // �����Ƶʱ��
    );

    // �� VGAxianshi ��������ӵ��������
    assign CSEL = CSEL_internal;  // VGA��ɫ���
    assign click = click_internal;  // ��������ź�
    assign HCOORD = HCOORD_VGA;    // VGA ������
    assign VCOORD = VCOORD_VGA;    // VGA ������

    // ��������ӳ��
    assign KBCODE = {hex1, hex0};  // ��ƴ��Ϊһ�� 8 λ��ֵ

endmodule
