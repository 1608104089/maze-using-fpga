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
    input CLK,         // ʱ���źţ�����ɨ�����
    input [3:0] ROW,   // 4 �������ź�
    output reg [3:0] COL,  // 4 ������ź�
    input ARSTL,       // �����źţ��͵�ƽ��Ч
    output reg [3:0] HEX0, // 16 ���ư�����
    output reg [3:0] HEX1, // 16 ���ư�����
    output reg KEYUP   // ���̰����Ƿ���Ч
);

reg [15:0] keymap [3:0]; // ������4x4���󣬹�16����
// ����ɨ��״̬��
reg [1:0] state, next_state;
// �������ź�
reg [3:0] lastROW, stableROW;
reg [3:0] debounce_count; // ���ڷ���������
// ״̬������
localparam IDLE = 2'b00, SCAN = 2'b01, DEBOUNCE = 2'b10;
// ��ʼ������ӳ��
initial begin
    keymap[0] = 16'h1;  // ROW0 ����ӳ��
    keymap[1] = 16'h2;  // ROW1 ����ӳ��
    keymap[2] = 16'h4;  // ROW2 ����ӳ��
    keymap[3] = 16'h8;  // ROW3 ����ӳ��
end

// ʱ�����ڿ��ư���ɨ��
always @(posedge CLK or negedge ARSTL) begin
    if (~ARSTL) begin
        state <= IDLE;
        COL <= 4'b1110; // ��ʼ����Ϊ��һ��ɨ��
        KEYUP <= 0;
        lastROW <= 4'b1111; // ��ʼ��Ϊû�а�������
        debounce_count <= 0;
    end else begin
        state <= next_state;
        case(state)
            IDLE: begin
                // ����״̬�£���ɨ��
                KEYUP <= 0;
            end
            SCAN: begin
                // ɨ��״̬��ɨ����
                if (ROW != lastROW) begin
                    lastROW <= ROW; // �������µ����ź�
                    debounce_count <= 0; // ��ʼ��ʱ����
                end
            end
            DEBOUNCE: begin
                // ����״̬���ȴ��ȶ�
                if (debounce_count == 4'b1111) begin
                    stableROW <= ROW; // ȷ���ȶ��İ�����
                    KEYUP <= 1; // ��ǰ�����Ч
                    // ���Ұ���ֵ
                    HEX0 <= (stableROW == 4'b1110) ? keymap[0][3:0] :
                            (stableROW == 4'b1101) ? keymap[1][3:0] :
                            (stableROW == 4'b1011) ? keymap[2][3:0] : keymap[3][3:0];
                end else begin
                    debounce_count <= debounce_count + 1; // ���ӷ�������
                    KEYUP <= 0; // ������Ч
                end
            end
            default: begin
                KEYUP <= 0;
            end
        endcase
    end
end

// ״̬����ת�߼�
always @(*) begin
    case(state)
        IDLE: next_state = SCAN;
        SCAN: next_state = DEBOUNCE;
        DEBOUNCE: next_state = SCAN;
        default: next_state = IDLE;
    endcase
end

// ������ɨ��
always @(posedge CLK or negedge ARSTL) begin
    if (~ARSTL) begin
        COL <= 4'b1110; // Ĭ��ѡ���һ��
    end else begin
        case(COL)
            4'b1110: COL <= 4'b1101;  // ɨ��ڶ���
            4'b1101: COL <= 4'b1011;  // ɨ�������
            4'b1011: COL <= 4'b0111;  // ɨ�������
            4'b0111: COL <= 4'b1110;  // �ص���һ��
            default: COL <= 4'b1110;  // Ĭ��ѡ���һ��
        endcase
    end
end

endmodule

