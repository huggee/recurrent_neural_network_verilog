`ifndef DEFMACRO
    `include "def.sv"
    `define DEFMACRO
`endif
// 2-port memory

// 2-port memory
module buffer#(
    parameter ADDR_WIDTH =10,     // アドレス幅
    parameter WORD_NUM   = 2**10, // ワード数
    parameter WORD_WIDTH = 8      // ワード幅(bit)
    )(
    input clk,
    input reset,
    input we,
    input [ADDR_WIDTH-1:0] a,  // アドレス
    input [WORD_WIDTH-1:0] d,  // 書き込みデータ
    output [WORD_WIDTH-1:0] q  // 読み出しデータ
    );

    integer i;
    
    reg [WORD_WIDTH-1:0] ram[0:WORD_NUM-1] /* synthesis noprune */; // Quartus最適化抑制

    reg we_reg/* synthesis noprune */;
    reg [ADDR_WIDTH-1:0] a_reg/* synthesis noprune */;
    reg [WORD_WIDTH-1:0] d_reg/* synthesis noprune */;

    assign q = ram[a];

    always @(posedge clk) begin
        we_reg <= we;
        a_reg  <= a;
        d_reg  <= d;
    end

    // RAM
    always @(posedge clk)
        if(reset) begin
            for(i = 0; i < WORD_NUM; i = i + 1) begin
                ram[i] <= 0;
            end
        end
        else if(we_reg) begin
            ram[a_reg] <= d_reg;
        end

    initial $display("%m");
    
endmodule
