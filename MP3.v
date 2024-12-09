`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2024/12/09 21:26:59
// Design Name: 
// Module Name: MP3
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

module MP3(
input CLK, //系统时钟
input kbstrobe_i, //去抖信号
input DREQ, //数据请求
output reg XRSET, //硬件复位
output reg XCS, 
//低电平有效片选输出
output reg XDCS,
//数据片字节同步
output reg SI, //串行数据输入
output reg SCLK, //SPI 时钟
input init, //初始化
input [3:0] hex1, 
//16 进制键码高位
input [3:0] hex0, 
//16 进制键码低位
input [15:0] adjusted_vol, 
//实时音量
 input keyup,
output reg [3:0] tune=0 
//当前按下指令对应提示音种类
);
parameter CMD_START=0; 
//开始写指令
parameter WRITE_CMD=1; 
//将一条指令全部写入
parameter DATA_START=2; 
//开始写数据
parameter WRITE_DATA=3; 
//将一条数据全部写入
parameter DELAY=4; 
//延时 
parameter VOL_CMD_START=5; 
//音量相关
parameter SEND_VOL_CMD=6; 
//CMD 发送

reg [31:0] volcmd;
 reg [20:0]addr;
 wire CLK_1M; //分频 1MHz

//时钟分频器
 Divider #(.N(100)) CLKDIV1(CLK,1,clk_1M);
 
 reg [15:0] Data;
 wire [15:0] D_do;
 wire [15:0] D_re;
 wire [15:0] D_mi;
 wire [15:0] D_fa;
 

 reg [3:0] pretune=0; 
 reg [15:0] _Data;
 
 //选择提示音
 blk_mem_gen_0 
your_instance_name0(.clka(CLK),.addra(addr),.douta(D_do));
 blk_mem_gen_1 
your_instance_name1(.clka(CLK),.addra(addr),.douta(D_re));
 blk_mem_gen_2 
your_instance_name2(.clka(CLK),.addra(addr),.douta(D_mi));
 blk_mem_gen_3 
your_instance_name3(.clka(CLK),.addra(addr),.douta(D_fa));
 
 integer tune_delay=0; //延时 50000 单位

//键盘扫描
always @(posedge CLK_1M)

begin
    if (tune_delay == 0) 
    begin
        if (keyup && kbstrobe_i) 
        begin
            tune_delay <= 50000;
            case ({hex1, hex0}) 
                8'h02: // 键码 0x02 对应上移
                    begin
                        tune <= 4'b0100; // 2上移
                    end
                8'h08: // 键码 0x08 对应下移
                    begin
                        tune <= 4'b0010; // 8下移
                    end
                8'h04: // 键码 0x04 对应左移
                    begin
                        tune <= 4'b0001; // 4左移
                    end
                8'h06: // 键码 0x06 对应右移
                    begin
                        tune <= 4'b0011; // 6 右移
                    end
                default:
                    begin
                        tune <= 0;
                    end
            endcase
        end
    end
    else 
    begin
        tune_delay <= tune_delay - 1; // 延时读取指令
    end
end

    always @(posedge CLK_1M) begin
        case (tune)
            4'b0001: Data <= D_do; // 4左移
            4'b0010: Data <= D_re; // 8下移
            4'b0011: Data <= D_mi; // 6右移
            4'b0100: Data <= D_fa; // 2上移
            default: Data <= D_do;
        endcase
    end

//音量控制和命令发送
reg [63:0] cmd={32'h02000804,32'h020B0000};
//00 是控制模式 0B 是音量 08 本地模式 04 软件复位（每首歌之后软件复位）
 //开始写指令
 integer status=CMD_START;
 integer cnt=0; //位计数
 integer cmd_cnt=0; //命令计数


//待机状态管理
 always @(posedge CLK_1M) 
begin
 pretune<=tune; 
//存储 tune，便于同步接收下一个 tune 
if(~init||pretune!=tune||!keyup) 
//以下情况（复位或可能出现错误）回到初始状态
 begin
 XCS<=1;
 XDCS<=1;
 XRSET<=0;
 cmd_cnt<=0;
 status<=DELAY; 
// 刚开机时先 delay,等待 DREQ
 SCLK<=0;
 cnt<=0;
 addr<=0;
 end
 else if((tune<4'b0101&&addr<10000))
 begin
 case(status)
 CMD_START: 
// 等待允许输入
 begin
 SCLK<=0;
//SPI 时钟下降沿输入，上升沿读取，创造下降沿
 if(cmd_cnt>=2) 
// 把前 2 组预设命令（mode 音量 ）输入完毕后 开始输入音调
status<=DATA_START;
 else if(DREQ) 
// DREQ 有效时 允许输入 si 可以接受 32（bit）信号
 begin 
 XCS<=0;//XCS 拉低表示输入指令
 status<=WRITE_CMD; 
// 开始输入指令
 SI<=cmd[63];
 cmd<={cmd[62:0],cmd[63]}; 
//移位传数据
 cnt<=1;
 end
 end
 WRITE_CMD://写入指令
 begin
 if(DREQ) 
 begin
 if(SCLK) 
 begin
 if(cnt>=32) //位计数
 begin
 XCS<=1; // 取消复位
 cnt<=0;
cmd_cnt<=cmd_cnt+1; 
//共发送两条 cmd 指令
 status<=CMD_START; 
// 跳转到命令执行
 end
 else 
 begin
SCLK<=0;
SI<=cmd[63]; 
// 发送三十二位写指令（写指令 0200（择 MODE 寄存器） 0804（MODE 有十六位 这里只关心第 11 和 2 位 进行软复位）
cmd<={cmd[62:0],cmd[63]}; 
//循环传送
cnt<=cnt+1;
 end
 end
 SCLK<=~SCLK;
 end
 end
 DATA_START://写入数据
 begin
if(adjusted_vol[15:0]!=cmd[47:32]) // cmd[47:32] 里存储的是当前音量 初始值为 0000
 begin//音量变了
 cnt<=0;
volcmd<={16'h020B,adjusted_vol}; // 调节音量命令 0B 寄存器负责音量控刿 该寄存器存储内容表示音量大小
status<=VOL_CMD_START; // 转到音量调节
 end
 else if(DREQ) 
// 等待允许输入 之后每次输入 32 使 等 DREQ 下次变高接着输入 vs1003B 会自动接收并播放
 begin 
//不需要调节音量，直接转到音频数据传送
 XDCS<=0;
 SCLK<=0;
 SI<=Data[15];
_Data<={Data[14:0],Data[15]};
 cnt<=1; 
status<=WRITE_DATA; // 歌曲信号
 end
cmd[15:0]<=adjusted_vol; 
// 更新 cmd 中存储的音量
 end
 WRITE_DATA:
 begin 
 if(SCLK)
 begin
 if(cnt>=16)
 begin
 XDCS<=1;
addr<=addr+1; 
// 读完十六位后地址后移 1 位
status<=DATA_START;
 end
 else 
 begin 
// 循环输入 输入十六位
 SCLK<=0;
 cnt<=cnt+1;
_Data<={_Data[14:0],_Data[15]};
SI<=_Data[15];
 end
 end
 SCLK<=~SCLK;
 end
 DELAY:
 begin
 if(cnt<50000) 
// 等待 100 个时钟周朿
 cnt<=cnt+1;
 else 
 begin
 cnt<=0;
status<=CMD_START; 
 XRSET<=1;
 end
 end
 VOL_CMD_START:
 begin
 if(DREQ) 
 begin 
// 等待 DREQ 信号
 XCS<=0; 
status<=SEND_VOL_CMD; 
// 输入音量控制命令
 SI<=volcmd[31];
volcmd<={volcmd[30:0],volcmd[31]}; 
 cnt<=1;
 end
 end
 SEND_VOL_CMD:
 begin
 if(DREQ) 
 begin
 if(SCLK) 
 begin
 if(cnt<32) //循环传值
 begin
SI<=volcmd[31];
volcmd<={volcmd[30:0],volcmd[31]}; 
cnt<=cnt+1; 
 end
 else 
 begin 
 XCS<=1; // 结束输入
 cnt<=0;
status<=DATA_START; 
 end
 end
 SCLK<=~SCLK;
 end
 end
default:;
 endcase
 end
end
endmodule


