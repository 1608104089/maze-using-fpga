`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/09 20:19:37
// Design Name: 
// Module Name: kypdkeyboard
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


module kypdkeyboard(
    input CLK,         // 时钟信号，用于扫描键盘
    input [3:0] ROW,   // 4 行输入信号
    output reg [3:0] COL,  // 4 列输出信号
    input ARSTL,       // 控制信号，低电平有效
    output reg [3:0] HEX0, // 16 进制按键码
    output reg [3:0] HEX1, // 16 进制按键码
    output reg KEYUP   // 键盘按键是否有效
);

reg [15:0] keymap [3:0]; // 假设是4x4矩阵，共16个键
// 按键扫描状态机
reg [1:0] state, next_state;
// 防抖动信号
reg [3:0] lastROW, stableROW;
reg [3:0] debounce_count; // 用于防抖动计数
// 状态机定义
localparam IDLE = 2'b00, SCAN = 2'b01, DEBOUNCE = 2'b10;
// 初始化按键映射
initial begin
    keymap[0] = 16'h1;  // ROW0 按键映射
    keymap[1] = 16'h2;  // ROW1 按键映射
    keymap[2] = 16'h4;  // ROW2 按键映射
    keymap[3] = 16'h8;  // ROW3 按键映射
end

// 时钟周期控制按键扫描
always @(posedge CLK or negedge ARSTL) begin
    if (~ARSTL) begin
        state <= IDLE;
        COL <= 4'b1110; // 初始化列为第一个扫描
        KEYUP <= 0;
        lastROW <= 4'b1111; // 初始化为没有按键按下
        debounce_count <= 0;
    end else begin
        state <= next_state;
        case(state)
            IDLE: begin
                // 空闲状态下，不扫描
                KEYUP <= 0;
            end
            SCAN: begin
                // 扫描状态，扫描列
                if (ROW != lastROW) begin
                    lastROW <= ROW; // 保存最新的行信号
                    debounce_count <= 0; // 开始计时防抖
                end
            end
            DEBOUNCE: begin
                // 防抖状态，等待稳定
                if (debounce_count == 4'b1111) begin
                    stableROW <= ROW; // 确认稳定的按键行
                    KEYUP <= 1; // 标记按键有效
                    // 查找按键值
                    HEX0 <= (stableROW == 4'b1110) ? keymap[0][3:0] :
                            (stableROW == 4'b1101) ? keymap[1][3:0] :
                            (stableROW == 4'b1011) ? keymap[2][3:0] : keymap[3][3:0];
                end else begin
                    debounce_count <= debounce_count + 1; // 增加防抖计数
                    KEYUP <= 0; // 按键无效
                end
            end
            default: begin
                KEYUP <= 0;
            end
        endcase
    end
end

// 状态机跳转逻辑
always @(*) begin
    case(state)
        IDLE: next_state = SCAN;
        SCAN: next_state = DEBOUNCE;
        DEBOUNCE: next_state = SCAN;
        default: next_state = IDLE;
    endcase
end

// 控制列扫描
always @(posedge CLK or negedge ARSTL) begin
    if (~ARSTL) begin
        COL <= 4'b1110; // 默认选择第一列
    end else begin
        case(COL)
            4'b1110: COL <= 4'b1101;  // 扫描第二列
            4'b1101: COL <= 4'b1011;  // 扫描第三列
            4'b1011: COL <= 4'b0111;  // 扫描第四列
            4'b0111: COL <= 4'b1110;  // 回到第一列
            default: COL <= 4'b1110;  // 默认选择第一列
        endcase
    end
end

endmodule

