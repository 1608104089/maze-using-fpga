`timescale 1ns / 1ps
///////////////////
//////////////////////////////////////////////////////////////////////////////////


module LED(iData, init, oData);
    input [3:0] iData;
    input init;
    output [6:0] oData;
    reg [6:0] oData;

    always @(*) begin
        if (init)
            oData = 7'b1111111;  // 如果 init 激活，则输出初始化值
        else
            case (iData)
                4'b0000: oData = 7'b1000000;
                4'b0001: oData = 7'b1111001;
                4'b0010: oData = 7'b0100100;
                4'b0011: oData = 7'b0110000;
                4'b0100: oData = 7'b0011001;
                4'b0101: oData = 7'b0010010;
                4'b0110: oData = 7'b0000010;
                4'b0111: oData = 7'b1111000;
                4'b1000: oData = 7'b0000000;
                4'b1001: oData = 7'b0010000;
                default: oData = 7'b0000000;
            endcase
    end
endmodule
