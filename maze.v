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
    input CLK,                  // 系统时钟
    input [3:0] ROW,            // 键盘行输入信号
    output [3:0] COL,           // 键盘列输出信号
    input ARSTL,                // 异步复位信号
    input [3:0] hex0,           // 16进制键码低位
    input [3:0] hex1,           // 16进制键码高位
    input keyup,                // 按键抬起信号
    output [15:0] vol,          // 音量数值
    output [3:0] volclass,      // 音量等级
    output [3:0] tune,          // 当前音调
    output [3:0] HEX0,          // 16进制按键码
    output [3:0] HEX1,          // 16进制按键码
    output KEYUP,               // 键盘按键有效标志
    output XRSET,               // MP3硬件复位
    output XCS,                 // MP3片选信号
    output XDCS,                // MP3数据同步
    output SI,                  // MP3串行数据输入
    output SCLK,                // MP3 SPI时钟
    output [6:0] LED_OUT,       // 七段显示器输出
    output [11:0] CSEL,         // VGA颜色输出
    output HSYNC,               // VGA行同步
    output VSYNC,               // VGA场同步
    output [3:0] RED,           // VGA红色分量
    output [3:0] GREEN,         // VGA绿色分量
    output [3:0] BLUE,          // VGA蓝色分量
    output [9:0] HCOORD,        // VGA横坐标
    output [9:0] VCOORD,        // VGA纵坐标
    output click,               // 按键点击信号
    output [5:0] ballX_now,     // 小球横坐标
    output [5:0] ballY_now      // 小球纵坐标
);

    // 声明信号
    wire kbstrobe_i;            // 去抖动信号
    wire [15:0] adjusted_vol;   // 调整后的音量
    wire [9:0] HCOORD_VGA, VCOORD_VGA;  // VGA坐标
    wire [7:0] KBCODE;          // 按键码
    wire [5:0] ballX, ballY;    // 小球坐标
    wire [11:0] CSEL_internal;  // VGA颜色信号
    wire click_internal;        // 按键点击信号
    wire DIV_CLK;               // 分频时钟输出

    // 实例化去抖动模块 SwitchDB
    SwitchDB switch_debounce (
        .CLK(CLK),
        .SW(keyup),
        .ACLR_L(ARSTL),
        .SWDB(kbstrobe_i)
    );

    // 实例化 MP3adjust 音量调整模块
    MP3adjust mp3_adjust (
        .clk(CLK),
        .hex1(hex1),
        .hex0(hex0),
        .keyup(keyup),
        .volclass(volclass),
        .vol(adjusted_vol)
    );

    // 实例化 MP3 播放模块
    MP3 mp3_player (
        .CLK(CLK),
        .kbstrobe_i(kbstrobe_i),
        .DREQ(1'b1), // 数据请求信号，常设为 1 表示持续请求数据
        .XRSET(XRSET),
        .XCS(XCS),
        .XDCS(XDCS),
        .SI(SI),
        .SCLK(SCLK),
        .init(1'b1), // 假设初始化信号为高
        .hex1(hex1),
        .hex0(hex0),
        .adjusted_vol(adjusted_vol),
        .keyup(keyup),
        .tune(tune)
    );

    // 实例化 kypdkeyboard 键盘扫描模块
    kypdkeyboard keyboard (
        .CLK(CLK),
        .ROW(ROW),
        .COL(COL),
        .ARSTL(ARSTL),
        .HEX0(HEX0),
        .HEX1(HEX1),
        .KEYUP(KEYUP)
    );

    // 实例化 LED 显示模块
    LED led_display (
        .iData(volclass),   // 使用音量等级作为输入
        .init(ARSTL),        // 使用复位信号作为初始化信号
        .oData(LED_OUT)      // 输出到七段显示器
    );

    // 实例化 VGAxianshi 模块
    VGAxianshi vga_display (
        .CLK(DIV_CLK),        // 使用分频后的时钟
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

    // 实例化 VGAcontrol 模块
    VGAcontrol vga_control (
        .CLK(DIV_CLK),        // 使用分频后的时钟
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

    // 实例化 Divider 分频模块
    Divider divider_inst (
        .I_CLK(CLK),        // 系统时钟连接到 Divider 输入
        .rst(ARSTL),         // 复位信号
        .O_CLK(DIV_CLK)      // 输出分频时钟
    );

    // 将 VGAxianshi 的输出连接到顶层输出
    assign CSEL = CSEL_internal;  // VGA颜色输出
    assign click = click_internal;  // 按键点击信号
    assign HCOORD = HCOORD_VGA;    // VGA 横坐标
    assign VCOORD = VCOORD_VGA;    // VGA 纵坐标

    // 键盘输入映射
    assign KBCODE = {hex1, hex0};  // 简单拼接为一个 8 位键值

endmodule
