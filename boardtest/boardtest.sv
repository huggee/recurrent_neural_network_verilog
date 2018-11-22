`ifndef DEFMACRO
    `include "../common/def.sv"
    `define DEFMACRO
`endif

module boardtest(OSC, RESET_N, M1_A, M1_D, M1_CSn, M1_WEn, M1_OEn, M2_A, M2_D, M2_CSn, M2_WEn, M2_OEn, F_IO, F_PB, F_PC, AnalogIn, Switch, LED);
    /***** IO *****/
    input OSC, RESET_N;

    output [16:0]M1_A;
    inout  [7:0]M1_D;
    output M1_CSn, M1_WEn, M1_OEn;

    output [16:0]M2_A;
    inout  [7:0]M2_D;
    output M2_CSn, M2_WEn, M2_OEn;

    inout [7:0]F_IO;
    inout [5:0]F_PB;
    inout [5:0]F_PC;

    input  [4:1] AnalogIn;
    input  [3:1] Switch;
    output [3:1] LED;

    // wire [31:0] debug_2;
    // wire [31:0] debug_3;
    // wire [31:0] debug_4;
    // wire [31:0] debug_5;
    // wire [31:0] debug_6;
    // wire [31:0] debug_7;

    wire [16:0]internal_sram0_addr;
    wire [7:0]internal_sram0_data_input;
    wire [7:0]internal_sram0_data_output;
    wire internal_sram0_data_output_en;
    wire internal_sram0_cs_n;
    wire internal_sram0_oe_n;
    wire internal_sram0_we_n;

    wire [16:0]internal_sram1_addr;
    wire [7:0]internal_sram1_data_input;
    wire [7:0]internal_sram1_data_output;
    wire internal_sram1_data_output_en;
    wire internal_sram1_cs_n;
    wire internal_sram1_oe_n;
    wire internal_sram1_we_n;

    wire internal_enable;

    wire [31:0] gpio_output0;
    wire [31:0] gpio_output1;
    wire [31:0] gpio_output2;
    wire [31:0] gpio_output3;
    wire [31:0] gpio_output4;
    wire [31:0] gpio_output5;
    wire [31:0] gpio_output6;
    wire [31:0] gpio_output7;

    wire [31:0] gpio_input0;
    wire [31:0] gpio_input1;
    wire [31:0] gpio_input2;
    wire [31:0] gpio_input3;
    wire [31:0] gpio_input4;
    wire [31:0] gpio_input5;
    wire [31:0] gpio_input6;
    wire [31:0] gpio_input7;

    wire clk;
    wire gene_reset_n;
    wire reset;
    wire [3:1]Switch_n;

    reg [22:0]counter;
    reg [2:0]led_reg;
    reg [31:0] test_state;

    assign reset = ~gene_reset_n;
    reg [31:0] gpio_in;
    wire [31:0] gpio_out;

    // Assignment
    assign clk = OSC;

    assign Switch_n = ~Switch;
    assign LED[3:1] = led_reg[2:0];

    assign gpio_input0 = gpio_output0;
    assign gpio_input1 = gpio_out;
    assign gpio_input2 = gpio_output2;
    assign gpio_input3 = gpio_output3;
    assign gpio_input4 = gpio_output4;
    assign gpio_input5 = gpio_output5;
    assign gpio_input6 = gpio_output6;
    assign gpio_input7 = gpio_output7;

    // assign gpio_input2 = debug_2;
    // assign gpio_input3 = debug_3;
    // assign gpio_input4 = debug_4;
    // assign gpio_input5 = debug_5;
    // assign gpio_input6 = debug_6;
    // assign gpio_input7 = debug_7;

    always @(posedge clk)
        if(reset)
            gpio_in <= 0;
        else
            gpio_in <= gpio_output0;

    /***** LED Controlo *****/
    always @(posedge clk)
        if(reset)
        begin
            led_reg <= 3'b000;
        end
        else
        begin
            led_reg <= 3'b111;
        end


    gene_reset_bycounter #(
        .value(32'h0000ffff)
    )gene_reset(
        .pReset_n(RESET_N),
        .pLocked(1'b1),
        .pClk(clk),
        .pResetOut_n(gene_reset_n)
    );

    rnn_top inst_rnn_top
    (
        .clk                           (clk),
        .reset                         (reset),
        .gpio_in                       (gpio_in),
        .gpio_out                      (gpio_out),
        .internal_enable               (internal_enable),
        .internal_sram0_addr           (internal_sram0_addr),
        .internal_sram0_data_input     (internal_sram0_data_input),
        .internal_sram0_data_output    (internal_sram0_data_output),
        .internal_sram0_data_output_en (internal_sram0_data_output_en),
        .internal_sram0_cs_n           (internal_sram0_cs_n),
        .internal_sram0_oe_n           (internal_sram0_oe_n),
        .internal_sram0_we_n           (internal_sram0_we_n),
        .internal_sram1_addr           (internal_sram1_addr),
        .internal_sram1_data_input     (internal_sram1_data_input),
        .internal_sram1_data_output    (internal_sram1_data_output),
        .internal_sram1_data_output_en (internal_sram1_data_output_en),
        .internal_sram1_cs_n           (internal_sram1_cs_n),
        .internal_sram1_oe_n           (internal_sram1_oe_n),
        .internal_sram1_we_n           (internal_sram1_we_n)
        // .debug_2                       (debug_2),
        // .debug_3                       (debug_3),
        // .debug_4                       (debug_4),
        // .debug_5                       (debug_5),
        // .debug_6                       (debug_6),
        // .debug_7                       (debug_7)
    );

    spi_external_sram u_target (
        .sysclk(clk),
        .reset(reset),

        .spi_cs_n(F_PB[1]),
        .spi_clk(F_PB[5]),
        .spi_din(F_PB[3]),
        .spi_dout(F_PB[4]),

        .sram0_addr(M1_A),
        .sram0_data(M1_D),
        .sram0_cs_n(M1_CSn),
        .sram0_oe_n(M1_OEn),
        .sram0_we_n(M1_WEn),

        .sram1_addr(M2_A),
        .sram1_data(M2_D),
        .sram1_cs_n(M2_CSn),
        .sram1_oe_n(M2_OEn),
        .sram1_we_n(M2_WEn),

        .internal_enable(internal_enable),

        .internal_sram0_addr(internal_sram0_addr),
        .internal_sram0_data_input(internal_sram0_data_input),
        .internal_sram0_data_output(internal_sram0_data_output),
        .internal_sram0_data_output_en(internal_sram0_data_output_en),
        .internal_sram0_cs_n(internal_sram0_cs_n),
        .internal_sram0_oe_n(internal_sram0_oe_n),
        .internal_sram0_we_n(internal_sram0_we_n),

        .internal_sram1_addr(internal_sram1_addr),
        .internal_sram1_data_input(internal_sram1_data_input),
        .internal_sram1_data_output(internal_sram1_data_output),
        .internal_sram1_data_output_en(internal_sram1_data_output_en),
        .internal_sram1_cs_n(internal_sram1_cs_n),
        .internal_sram1_oe_n(internal_sram1_oe_n),
        .internal_sram1_we_n(internal_sram1_we_n),

        .gpio_output0(gpio_output0),
        .gpio_output1(gpio_output1),
        .gpio_output2(gpio_output2),
        .gpio_output3(gpio_output3),
        .gpio_output4(gpio_output4),
        .gpio_output5(gpio_output5),
        .gpio_output6(gpio_output6),
        .gpio_output7(gpio_output7),

        .gpio_input0(gpio_input0),
        .gpio_input1(gpio_input1),
        .gpio_input2(gpio_input2),
        .gpio_input3(gpio_input3),
        .gpio_input4(gpio_input4),
        .gpio_input5(gpio_input5),
        .gpio_input6(gpio_input6),
        .gpio_input7(gpio_input7)
    );

endmodule
