`ifndef DEFMACRO
    `include "def.sv"
    `define DEFMACRO
`endif

`define LOAD_X      32'h10
`define LOAD_T      32'h20
`define CONCAT_BIAS 32'h30
`define FF_0        32'h100
`define FF_1        32'h200
`define FF_2        32'h300
`define FF_3        32'h400
`define BP_0        32'h500
`define WRITE_Y     32'h600
`define BP_1        32'h1000
`define BP_2        32'h2000
`define UPDATE_WO   32'h3000
`define UPDATE_WH   32'h4000
`define UPDATE_WI   32'h5000
`define FINISH      32'h10000

module rnn_top(
    clk,
    reset,
    gpio_in,
    gpio_out,
    internal_enable,
    internal_sram0_addr,
    internal_sram0_data_input,
    internal_sram0_data_output,
    internal_sram0_data_output_en,
    internal_sram0_cs_n,
    internal_sram0_oe_n,
    internal_sram0_we_n,
    internal_sram1_addr,
    internal_sram1_data_input,
    internal_sram1_data_output,
    internal_sram1_data_output_en,
    internal_sram1_cs_n,
    internal_sram1_oe_n,
    internal_sram1_we_n,
    debug_2,
    debug_3,
    debug_4,
    debug_5,
    debug_6,
    debug_7
);
    input             clk;
    input             reset;
    input      [31:0] gpio_in;
    output reg [31:0] gpio_out;
    output reg        internal_enable;
    
    output reg [`R_SRAM_ADDR] internal_sram0_addr           /* synthesis noprune */;
    input      [`R_DATA]      internal_sram0_data_input;
    output reg [`R_DATA]      internal_sram0_data_output    /* synthesis noprune */;
    output reg                internal_sram0_data_output_en /* synthesis noprune */;
    output reg                internal_sram0_cs_n           /* synthesis noprune */;
    output reg                internal_sram0_oe_n           /* synthesis noprune */;
    output reg                internal_sram0_we_n           /* synthesis noprune */;

    output reg [`R_SRAM_ADDR] internal_sram1_addr           /* synthesis noprune */;
    input      [`R_DATA]      internal_sram1_data_input;
    output reg [`R_DATA]      internal_sram1_data_output    /* synthesis noprune */;
    output reg                internal_sram1_data_output_en /* synthesis noprune */;
    output reg                internal_sram1_cs_n           /* synthesis noprune */;
    output reg                internal_sram1_oe_n           /* synthesis noprune */;
    output reg                internal_sram1_we_n           /* synthesis noprune */;

    output wire [31:0] debug_2;
    output wire [31:0] debug_3;
    output wire [31:0] debug_4;
    output wire [31:0] debug_5;
    output wire [31:0] debug_6;
    output wire [31:0] debug_7;

    integer j;

    reg [31:0] debug_2_reg;
    reg [31:0] debug_3_reg;
    reg [31:0] debug_4_reg;
    reg [31:0] debug_5_reg;
    reg [31:0] debug_6_reg;
    reg [31:0] debug_7_reg;

    reg [31:0] gpio_in_reg;

    reg [`R_DATA] input_data_0;
    reg [`R_DATA] input_data_1;
    reg [`R_DATA] output_data_0;
    reg [`R_DATA] output_data_1;

    reg [31:0] time_0 /* synthesis noprune */;
    reg [31:0] time_1;
    reg [31:0] time_2;
    reg [31:0] state;

    reg reset_by_arduino;
    reg reset_by_fpga;
    reg buffer_reset;
    reg run;

    /******************************/
    /*********   RESET  ***********/
    /******************************/
    always @(posedge clk) begin
        reset_by_arduino <= reset || gpio_in[4];
        reset_by_fpga    <= reset || buffer_reset;
    end

    /******************************/
    /*******   BUFFER   ***********/
    /******************************/
    reg              h_we;
    reg  [`R_ADDR]   h_a;
    reg  [`R_NEURON] h_d;
    wire [`R_NEURON] h_q;

    buffer #(
        .WORD_NUM  (`N_H + 1),
        .WORD_WIDTH(`W_NEURON)
    ) inst_h_buffer (
        .clk   (clk),
        .reset (reset_by_arduino),
        .we    (h_we),
        .a     (h_a),
        .d     (h_d),
        .q     (h_q)
    );

    reg              y_we;
    reg  [`R_ADDR]   y_a;
    reg  [`R_NEURON] y_d;
    wire [`R_NEURON] y_q;

    buffer #(
        .WORD_NUM  (`N_OUT),
        .WORD_WIDTH(`W_NEURON)
    ) inst_y_buffer (
        .clk   (clk),
        .reset (reset_by_arduino),
        .we    (y_we),
        .a     (y_a),
        .d     (y_d),
        .q     (y_q)
    );

    reg            x_we [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_ADDR] x_a  [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_DATA] x_d  [`R_TIMESTEP]/* synthesis noprune */;
    wire [`R_DATA] x_q  [`R_TIMESTEP];

    reg            t_we [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_ADDR] t_a  [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_DATA] t_d  [`R_TIMESTEP]/* synthesis noprune */;
    wire [`R_DATA] t_q  [`R_TIMESTEP];

    reg            act_h_we [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_ADDR] act_h_a  [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_DATA] act_h_d  [`R_TIMESTEP]/* synthesis noprune */;
    wire [`R_DATA] act_h_q  [`R_TIMESTEP];

    reg              d_h_we [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_ADDR]   d_h_a  [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_WEIGHT] d_h_d  [`R_TIMESTEP]/* synthesis noprune */;
    wire [`R_WEIGHT] d_h_q  [`R_TIMESTEP];
    
    reg              delta_y_we [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_ADDR]   delta_y_a  [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_NEURON] delta_y_d  [`R_TIMESTEP]/* synthesis noprune */;
    wire [`R_NEURON] delta_y_q  [`R_TIMESTEP];

    reg             delta_h_we [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_ADDR]  delta_h_a  [`R_TIMESTEP]/* synthesis noprune */;
    reg  [`R_DELTA] delta_h_d  [`R_TIMESTEP]/* synthesis noprune */;
    wire [`R_DELTA] delta_h_q  [`R_TIMESTEP];


    generate
        genvar i;
        for(i = 0; i < `TIMESTEP; i = i + 1) begin : loop_gen_inst_buffer
            buffer #(
                .WORD_NUM(`N_IN + 1)
            ) inst_x_buffer (
                .clk   (clk),
                .reset (reset_by_fpga),
                .we    (x_we[i]),
                .a     (x_a[i]),
                .d     (x_d[i]),
                .q     (x_q[i])
            );

            buffer #(
                .WORD_NUM(`N_OUT)
            ) inst_t_buffer (
                .clk   (clk),
                .reset (reset_by_fpga),
                .we    (t_we[i]),
                .a     (t_a[i]),
                .d     (t_d[i]),
                .q     (t_q[i])
            );

            buffer #(
                .WORD_NUM(`N_H + 1)
            ) inst_act_h_buffer (
                .clk   (clk),
                .reset (reset_by_fpga),
                .we    (act_h_we[i]),
                .a     (act_h_a[i]),
                .d     (act_h_d[i]),
                .q     (act_h_q[i])
            );

            buffer #(
                .WORD_NUM  (`N_H),
                .WORD_WIDTH(`W_WEIGHT)
            ) inst_d_h_buffer (
                .clk   (clk),
                .reset (reset_by_fpga),
                .we    (d_h_we[i]),
                .a     (d_h_a[i]),
                .d     (d_h_d[i]),
                .q     (d_h_q[i])
            );

            buffer #(
                .WORD_NUM  (`N_OUT),
                .WORD_WIDTH(`W_NEURON)
            ) inst_delta_y_buffer (
                .clk   (clk),
                .reset (reset_by_fpga),
                .we    (delta_y_we[i]),
                .a     (delta_y_a[i]),
                .d     (delta_y_d[i]),
                .q     (delta_y_q[i])
            );

            buffer #(
                .WORD_NUM  (`N_H),
                .WORD_WIDTH(`W_DELTA)
            ) inst_delta_h_buffer (
                .clk   (clk),
                .reset (reset_by_fpga),
                .we    (delta_h_we[i]),
                .a     (delta_h_a[i]),
                .d     (delta_h_d[i]),
                .q     (delta_h_q[i])
            );

        end
    endgenerate

    /******************************/
    /******* SHIFTER    ***********/
    /******************************/
    reg  [15:0] right_shift_16_data_x;
    wire [15:0] right_shift_16_data_y;
    right_shifter_16 inst_right_shifter_16(
        .IN(right_shift_16_data_x),
        .OUT(right_shift_16_data_y)
    );

    /******************************/
    /******* MULTIPLIER ***********/
    /******************************/
    reg  [7:0] mul_8_8_8_data_a;
    reg  [7:0] mul_8_8_8_data_b;
    wire [7:0] mul_8_8_8_data_y;
    multiplier_8_8_8 inst_multiplier_8_8_8(
        .A(mul_8_8_8_data_a),
        .B(mul_8_8_8_data_b),
        .OUT(mul_8_8_8_data_y)
    );

    reg  [7:0]  mul_8_12_16_data_a;
    reg  [11:0] mul_8_12_16_data_b;
    wire [15:0] mul_8_12_16_data_y;
    multiplier_8_12_16 inst_multiplier_8_12_16(
        .A(mul_8_12_16_data_a),
        .B(mul_8_12_16_data_b),
        .OUT(mul_8_12_16_data_y)
    );

    reg  [7:0]  mul_8_20_16_data_a;
    reg  [19:0] mul_8_20_16_data_b;
    wire [15:0] mul_8_20_16_data_y;
    multiplier_8_20_16 inst_multiplier_8_20_16(
        .A(mul_8_20_16_data_a),
        .B(mul_8_20_16_data_b),
        .OUT(mul_8_20_16_data_y)
    );

    reg  [11:0] mul_12_16_20_data_a;
    reg  [15:0] mul_12_16_20_data_b;
    wire [19:0] mul_12_16_20_data_y;
    multiplier_12_16_20 inst_multiplier_12_16_20(
        .A(mul_12_16_20_data_a),
        .B(mul_12_16_20_data_b),
        .OUT(mul_12_16_20_data_y)
    );

    reg  [15:0] mul_16_20_20_data_a;
    reg  [19:0] mul_16_20_20_data_b;
    wire [19:0] mul_16_20_20_data_y;
    multiplier_16_20_20 inst_multiplier_16_20_20(
        .A(mul_16_20_20_data_a),
        .B(mul_16_20_20_data_b),
        .OUT(mul_16_20_20_data_y)
    );

    /******************************/
    /******* ADDER      ***********/
    /******************************/
    reg  [7:0]  add_8_12_12_data_a;
    reg  [11:0] add_8_12_12_data_b;
    wire [11:0] add_8_12_12_data_y;
    adder_8_12_12 inst_adder_8_12_12(
        .A(add_8_12_12_data_a),
        .B(add_8_12_12_data_b),
        .OUT(add_8_12_12_data_y)
    );

    reg  [19:0] add_20_20_20_data_a;
    reg  [19:0] add_20_20_20_data_b;
    wire [19:0] add_20_20_20_data_y;
    adder_20_20_20 inst_adder_20_20_20(
        .A(add_20_20_20_data_a),
        .B(add_20_20_20_data_b),
        .OUT(add_20_20_20_data_y)
    );

    /******************************/
    /******* SUBTRACTER ***********/
    /******************************/
    reg  [11:0] sub_12_8_12_data_a;
    reg  [7:0]  sub_12_8_12_data_b;
    wire [11:0] sub_12_8_12_data_y;
    subtracter_12_8_12 inst_subtracter_12_8_12(
        .A(sub_12_8_12_data_a),
        .B(sub_12_8_12_data_b),
        .OUT(sub_12_8_12_data_y)
    );

    reg  [15:0] sub_16_16_16_data_a;
    reg  [15:0] sub_16_16_16_data_b;
    wire [15:0] sub_16_16_16_data_y;
    subtracter_16_16_16 inst_subtracter_16_16_16(
        .A(sub_16_16_16_data_a),
        .B(sub_16_16_16_data_b),
        .OUT(sub_16_16_16_data_y)
    );

    /******************************/
    /******* ACTIVATION ***********/
    /******************************/
    reg  [11:0] sgn_12_8_data_x;
    wire [7:0]  sgn_12_8_data_y;
    sigmoid_12_8 inst_sigmoid_12_8(
        .in(sgn_12_8_data_x),
        .y(sgn_12_8_data_y)
    );

    reg  [11:0] derivative_sgn_12_16_data_x;
    wire [15:0] derivative_sgn_12_16_data_y;
    derivative_sigmoid_12_16 inst_derivative_sigmoid_12_16(
        .in(derivative_sgn_12_16_data_x),
        .y(derivative_sgn_12_16_data_y)
    );

    always @(posedge clk) begin
        if(reset) begin
            internal_enable               <= 0;
            gpio_out                      <= 32'h10;
            internal_sram0_addr           <= 0;
            internal_sram0_data_output    <= 0;
            internal_sram0_data_output_en <= 0;
            internal_sram0_cs_n           <= 1;
            internal_sram0_oe_n           <= 0;
            internal_sram0_we_n           <= 1;
            internal_sram1_addr           <= 0;
            internal_sram1_data_output    <= 0;
            internal_sram1_data_output_en <= 0;
            internal_sram1_cs_n           <= 1;
            internal_sram1_oe_n           <= 0;
            internal_sram1_we_n           <= 1;
            
            h_we <= 0; h_a <= 0; h_d <= 0;
            y_we <= 0; y_a <= 0; y_d <= 0;
            for(j = 0; j < `TIMESTEP; j = j + 1) begin
                x_we[j]        <= 0; x_a[j]      <= 0; x_d[j]       <= 0;
                t_we[j]        <= 0; t_a[j]      <= 0; t_d[j]       <= 0;
                act_h_we[j]    <= 0; act_h_a[j]  <= 0; act_h_d[j]   <= 0;
                d_h_we[j]      <= 0; d_h_a[j]    <= 0; d_h_d[j]     <= 0;
                delta_y_we[j] <= 0; delta_y_a[j] <= 0; delta_y_d[j] <= 0;
                delta_h_we[j] <= 0; delta_h_a[j] <= 0; delta_h_d[j] <= 0;
            end 

            buffer_reset <= 0;
            time_1       <= 0;
            time_2       <= 0;
            state        <= 0;
            time_0       <= 0;

            debug_2_reg <= 0;
            debug_3_reg <= 0;
            debug_4_reg <= 0;
            debug_5_reg <= 0;
            debug_6_reg <= 0;
            debug_7_reg <= 0;
        end

        else if(reset_by_arduino) begin
            internal_enable               <= 0;
            gpio_out                      <= 32'h10;
            internal_sram0_addr           <= 0;
            internal_sram0_data_output    <= 0;
            internal_sram0_data_output_en <= 0;
            internal_sram0_cs_n           <= 1;
            internal_sram0_oe_n           <= 0;
            internal_sram0_we_n           <= 1;
            internal_sram1_addr           <= 0;
            internal_sram1_data_output    <= 0;
            internal_sram1_data_output_en <= 0;
            internal_sram1_cs_n           <= 1;
            internal_sram1_oe_n           <= 0;
            internal_sram1_we_n           <= 1;
            
            h_we <= 0; h_a <= 0; h_d <= 0;
            y_we <= 0; y_a <= 0; y_d <= 0;
            for(j = 0; j < `TIMESTEP; j = j + 1) begin
                x_we[j]       <= 0; x_a[j]       <= 0; x_d[j]       <= 0;
                t_we[j]       <= 0; t_a[j]       <= 0; t_d[j]       <= 0;
                act_h_we[j]   <= 0; act_h_a[j]   <= 0; act_h_d[j]   <= 0;
                d_h_we[j]     <= 0; d_h_a[j]     <= 0; d_h_d[j]     <= 0;
                delta_y_we[j] <= 0; delta_y_a[j] <= 0; delta_y_d[j] <= 0;
                delta_h_we[j] <= 0; delta_h_a[j] <= 0; delta_h_d[j] <= 0;
            end 

            time_1 <= 0;
            time_2 <= 0;
            state  <= 0;
        end

        else if(state == 32'h0) begin
            if(
            gpio_in == 32'h4 ||
            gpio_in == 32'h8 ||
            gpio_in == 32'hc  ) begin
                gpio_out        <= 32'h0;
                internal_enable <= 1;
                state           <= state + 1;
            end
        end

        else if(state == 32'h1) begin
            if(time_0 == 0) begin
                time_1       <= `TIMESTEP - 1;
                buffer_reset <= 1;
                state        <= state + 1;
            end
            else begin
                time_1 <= time_0 - 1;
                state  <= state + 1;
            end
        end

        else if(state == 32'h2) begin
            state <= state + 1;
        end

        else if(state == 32'h3) begin
            buffer_reset <= 0;
            state        <= `LOAD_X;
        end


        /*****************************************************/
        /******** 入力データ読み出し                       ***/
        /*****************************************************/
        else if(state == `LOAD_X) begin
            internal_sram0_addr <= `ADDR_INPUT_START;
            internal_sram0_cs_n <= 0;
            x_a[time_0]         <= 0;
            state               <= state + 1;               
        end

        else if(state == `LOAD_X + 32'h1) begin
            internal_sram0_cs_n <= 1;
            input_data_0        <= internal_sram0_data_input;
            state               <= state + 1;
        end

        else if(state == `LOAD_X + 32'h2) begin
            x_we[time_0] <= 1;
            x_d[time_0]  <= input_data_0;
            state        <= state + 1;
        end

        else if(state == `LOAD_X + 32'h3) begin
            if(x_a[time_0] == `N_IN - 1 ) begin
                x_we[time_0] <= 0;
                x_a[time_0]  <= 0;
                state        <= `LOAD_T;
            end
            else begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram0_cs_n <= 0;
                x_we[time_0]        <= 0;
                x_a[time_0]         <= x_a[time_0] + 1;
                state               <= `LOAD_X + 32'h1;
            end
        end


        /*****************************************************/
        /******** ラベル読み出し                           ***/
        /*****************************************************/
        else if(state == `LOAD_T) begin
            internal_sram0_addr <= `ADDR_LABEL_START;
            internal_sram0_cs_n <= 0;
            t_a[time_0]         <= 0;
            state               <= state + 1;
        end

        else if(state == `LOAD_T + 32'h1) begin
            internal_sram0_cs_n <= 1;
            input_data_0        <= internal_sram0_data_input;
            state               <= state + 1;
        end

        else if(state == `LOAD_T + 32'h2) begin
            t_we[time_0] <= 1;
            t_d[time_0]  <= input_data_0;
            state        <= state + 1;
        end

        else if(state == `LOAD_T + 32'h3) begin
            if(
            internal_sram0_addr == `ADDR_LABEL_END &&
            t_a[time_0]         == `N_OUT - 1       ) begin
                t_we[time_0] <= 0;
                t_a[time_0]  <= 0;
                state        <= `CONCAT_BIAS;
            end
            else begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram0_cs_n <= 0;
                t_we[time_0]        <= 0;
                t_a[time_0]         <= t_a[time_0] + 1;
                state               <= `LOAD_T + 32'h1;
            end
        end


        /*****************************************************/
        /******** バイアス項を追加                       ***/
        /*****************************************************/
        else if(state == `CONCAT_BIAS) begin
            x_we[time_0]     <= 1;
            x_a[time_0]      <= `N_IN;
            x_d[time_0]      <= 8'b00100000;
            act_h_we[time_0] <= 1;
            act_h_a[time_0]  <= `N_H;
            act_h_d[time_0]  <= 8'b00100000;
            state            <= state + 1;
        end

        else if(state == `CONCAT_BIAS + 32'h1) begin
            x_we[time_0]     <= 0;
            x_a[time_0]      <= 0;
            act_h_we[time_0] <= 0;
            act_h_a[time_0]  <= 0;
            state            <= `FF_0;
        end


        /*****************************************************/
        /******** Feedforward      input -> hidden         ***/
        /*****************************************************/
        else if(state == `FF_0) begin
            internal_sram0_addr <= `ADDR_WI_START;
            internal_sram0_cs_n <= 0;
            state               <= state + 1;
        end

        else if(state == `FF_0 + 32'h1) begin
            internal_sram0_cs_n <= 1;
            input_data_0        <= internal_sram0_data_input;
            state               <= state + 1;
        end

        else if(state == `FF_0 + 32'h2) begin
            mul_8_8_8_data_a <= x_q[time_0];
            mul_8_8_8_data_b <= input_data_0;
            state            <= state + 1;
        end

        else if(state == `FF_0 + 32'h3) begin
            add_8_12_12_data_a <= mul_8_8_8_data_y;
            add_8_12_12_data_b <= h_q;
            state              <= state + 1;
        end

        else if(state == `FF_0 + 32'h4) begin
            h_we  <= 1;
            h_d   <= add_8_12_12_data_y;
            state <= state + 1;
        end

        else if(state == `FF_0 + 32'h5) begin
            if(
            internal_sram0_addr == `ADDR_WI_END &&
            h_a                 == `N_H - 1     &&
            x_a[time_0]         == `N_IN         ) begin
                h_we        <= 0;
                h_a         <= 0;
                x_a[time_0] <= 0;
                state       <= `FF_1;
            end
            else if(h_a == `N_H - 1) begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram0_cs_n <= 0;
                h_we                <= 0;
                h_a                 <= 0;
                x_a[time_0]         <= x_a[time_0] + 1;
                state               <= `FF_0 + 32'h1;
            end
            else begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram0_cs_n <= 0;
                h_we                <= 0;
                h_a                 <= h_a + 1;
                state               <= `FF_0 + 32'h1;
            end
        end


        /*****************************************************/
        /******** Feedforward     hidden -> hidden         ***/
        /*****************************************************/
        else if(state == `FF_1) begin
            internal_sram0_addr <= `ADDR_WH_START;
            internal_sram0_cs_n <= 0;
            state               <= state + 1;
        end

        else if(state == `FF_1 + 32'h1) begin
            internal_sram0_cs_n <= 1;
            input_data_0        <= internal_sram0_data_input;
            state               <= state + 1;
        end

        else if(state == `FF_1 + 32'h2) begin
            mul_8_8_8_data_a  <= act_h_q[time_1];
            mul_8_8_8_data_b  <= input_data_0;;
            state             <= state + 1;
        end

        else if(state == `FF_1 + 32'h3) begin
            add_8_12_12_data_a <= mul_8_8_8_data_y;
            add_8_12_12_data_b <= h_q;
            state              <= state + 1;
        end

        else if(state == `FF_1 + 32'h4) begin
            h_we  <= 1;
            h_d   <= add_8_12_12_data_y;
            state <= state + 1;
        end

        else if(state == `FF_1 + 32'h5) begin
            if(
            internal_sram0_addr == `ADDR_WH_END &&
            h_a                 == `N_H - 1     &&
            act_h_a[time_1]     == `N_H          ) begin
                act_h_a[time_1] <= 0;
                h_we            <= 0;
                h_a             <= 0;
                state           <= `FF_2;
            end
            else if(h_a == `N_H - 1) begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram0_cs_n <= 0;
                act_h_a[time_1]     <= act_h_a[time_1] + 1;
                h_we                <= 0;
                h_a                 <= 0;
                state               <= `FF_1 + 32'h1;
            end
            else begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram0_cs_n <= 0;
                h_we                <= 0;
                h_a                 <= h_a + 1;
                state               <= `FF_1 + 32'h1;
            end
        end


        /*****************************************************/
        /******** hidden活性化,微分                        ***/
        /*****************************************************/
        else if(state == `FF_2) begin
            h_a[time_0]     <= 0;
            act_h_a[time_0] <= 0;
            d_h_a[time_0]   <= 0;
            state           <= state + 1;
        end

        else if(state == `FF_2 + 32'h1) begin
            sgn_12_8_data_x             <= h_q;
            derivative_sgn_12_16_data_x <= h_q;
            state                       <= state + 1;
        end

        else if(state == `FF_2 + 32'h2) begin
            act_h_we[time_0] <= 1;
            act_h_d[time_0]  <= sgn_12_8_data_y;
            d_h_we[time_0]   <= 1;
            d_h_d[time_0]    <= derivative_sgn_12_16_data_y;
            state            <= state + 1;
        end

        else if(state == `FF_2 + 32'h3) begin
            if(
            act_h_a[time_0] == `N_H - 1 &&
            h_a             == `N_H - 1  ) begin
                act_h_we[time_0] <= 0;
                act_h_a[time_0]  <= 0;
                d_h_we[time_0]   <= 0;
                d_h_a[time_0]    <= 0;
                h_a              <= 0;
                state            <= `FF_3;
            end
            else begin
                act_h_we[time_0] <= 0;
                act_h_a[time_0]  <= act_h_a[time_0] + 1;
                d_h_we[time_0]   <= 0;
                d_h_a[time_0]    <= d_h_a[time_0] + 1;
                h_a              <= h_a + 1;
                state            <= `FF_2 + 32'h1;
            end
        end
            

        /*****************************************************/
        /******** Feedforward     hidden -> output         ***/
        /*****************************************************/
        else if(state == `FF_3) begin
            internal_sram0_addr <= `ADDR_WO_START;
            internal_sram0_cs_n <= 0;
            state               <= state + 1;
        end

        else if(state == `FF_3 + 32'h1) begin
            internal_sram0_cs_n <= 1;
            input_data_0        <= internal_sram0_data_input;
            state               <= state + 1;
        end

        else if(state == `FF_3 + 32'h2) begin
            mul_8_8_8_data_a <= act_h_q[time_0];
            mul_8_8_8_data_b <= input_data_0;
            state            <= state + 1;
        end

        else if(state == `FF_3 + 32'h3) begin
            add_8_12_12_data_a <= mul_8_8_8_data_y;
            add_8_12_12_data_b <= y_q;
            state              <= state + 1;
        end

        else if(state == `FF_3 + 32'h4) begin
            y_we  <= 1;
            y_d   <= add_8_12_12_data_y;
            state <= state + 1;
        end

        else if(state == `FF_3 + 32'h5) begin
            if(
            internal_sram0_addr == `ADDR_WO_END &&
            y_a                 == `N_OUT - 1   &&
            act_h_a[time_0]     == `N_H          ) begin
                act_h_a[time_0] <= 0;
                y_a             <= 0;
                y_we            <= 0;
                state           <= `BP_0;
            end
            else if(y_a == `N_OUT - 1) begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram0_cs_n <= 0;
                act_h_a[time_0]     <= act_h_a[time_0] + 1;
                y_a                 <= 0;
                y_we                <= 0;
                state               <= `FF_3 + 32'h1;
            end
            else begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram0_cs_n <= 0;
                y_a                 <= y_a + 1;
                y_we                <= 0;
                state               <= `FF_3 + 32'h1;
            end
        end

            
        /*****************************************************/
        /******** output活性化 delta(output)計算           ***/
        /*****************************************************/
        else if(state == `BP_0) begin
            y_a               <= 0;
            t_a[time_0]       <= 0;
            delta_y_a[time_0] <= 0;
            state             <= state + 1;
        end

        else if(state == `BP_0 + 32'h1) begin
            sub_12_8_12_data_a <= y_q;
            sub_12_8_12_data_b <= t_q[time_0];
            state              <= state + 1;
        end

        else if(state == `BP_0 + 32'h2) begin

            delta_y_we[time_0] <= 1;
            delta_y_d[time_0]  <= sub_12_8_12_data_y;
            state              <= state + 1;
        end

        else if(state == `BP_0 + 32'h3) begin
            if(
            delta_y_a[time_0] == `N_OUT - 1 &&
            y_a               == `N_OUT - 1 &&
            t_a[time_0]       == `N_OUT - 1  ) begin
                y_a                <= 0;
                t_a[time_0]        <= 0;
                delta_y_we[time_0] <= 0;
                delta_y_a[time_0]  <= 0;
                state              <= `WRITE_Y;
            end
            else begin
                y_a                <= y_a + 1;
                t_a[time_0]        <= t_a[time_0] + 1;
                delta_y_we[time_0] <= 0;
                delta_y_a[time_0]  <= delta_y_a[time_0] + 1;
                state              <= `BP_0 + 32'h1;
            end
        end


        /*****************************************************/
        /******** 推論結果書き込み                         ***/
        /*****************************************************/
        else if(state == `WRITE_Y) begin
            internal_sram0_addr <= `ADDR_OUTPUT_START;
            state               <= state + 1;
        end

        else if(state == `WRITE_Y + 32'h1) begin
            output_data_0 <= {y_q[`W_NEURON-1], y_q[6:0]};
            state         <= state + 1;
        end

        else if(state == `WRITE_Y + 32'h2) begin
            internal_sram0_data_output    <= output_data_0;
            internal_sram0_data_output_en <= 1;
            internal_sram0_cs_n           <= 0;
            internal_sram0_we_n           <= 0;
            state                         <= state + 1;
        end

        else if(state == `WRITE_Y + 32'h3) begin
            internal_sram0_cs_n <= 1;
            internal_sram0_we_n <= 1;
            state               <= state + 1;
        end

        else if(state == `WRITE_Y + 32'h4) begin
            if(
            internal_sram0_addr == `ADDR_OUTPUT_END &&
            y_a                 == `N_OUT - 1        ) begin
                if(gpio_in == 32'h8 && time_0 == `TIMESTEP - 1) begin
                    internal_sram0_data_output_en <= 0;
                    y_a                           <= 0;
                    state                         <= `BP_1;
                end
                else begin
                    internal_sram0_data_output_en <= 0;
                    y_a                           <= 0;
                    state                         <= `FINISH;
                end
            end
            else begin
                internal_sram0_addr           <= internal_sram0_addr + 1;
                internal_sram0_data_output_en <= 0;
                y_a                           <= y_a + 1;
                state                         <= `WRITE_Y + 32'h1;
            end
        end


        /*****************************************************/
        /******** Backprop delta(hidden)  output->hidden   ***/
        /*****************************************************/
        else if(state == `BP_1) begin
            internal_sram0_addr <= `ADDR_WO_START;
            internal_sram0_cs_n <= 0;
            internal_sram1_addr <= `ADDR_WO_START;
            internal_sram1_cs_n <= 0;
            time_2              <= 0;
            state               <= state + 1;
        end

        else if(state == `BP_1 + 32'h1) begin
            internal_sram0_cs_n <= 1;
            internal_sram1_cs_n <= 1;
            input_data_0        <= internal_sram0_data_input;
            input_data_1        <= internal_sram1_data_input;
            state               <= state + 1;
        end

        else if(state == `BP_1 + 32'h2) begin
            mul_12_16_20_data_a <= delta_y_q[time_2];
            mul_12_16_20_data_b <= {input_data_0, input_data_1};
            state               <= state + 1;
        end

        else if(state == `BP_1 + 32'h3) begin
            mul_16_20_20_data_a <= d_h_q[time_2];
            mul_16_20_20_data_b <= mul_12_16_20_data_y;
            state               <= state + 1;
        end

        else if(state == `BP_1 + 32'h4) begin
            add_20_20_20_data_a <= delta_h_q[time_2];
            add_20_20_20_data_b <= mul_16_20_20_data_y;
            state               <= state + 1;
        end

        else if(state == `BP_1 + 32'h5) begin
            delta_h_we[time_2] <= 1;
            delta_h_d[time_2]  <= add_20_20_20_data_y;
            state              <= state + 1;
        end

        else if(state == `BP_1 + 32'h6) begin
            if(
            act_h_a[time_2]   == `N_H - 1   &&
            delta_h_a[time_2] == `N_H - 1   &&
            delta_y_a[time_2] == `N_OUT - 1  ) begin
                if (time_2 == `TIMESTEP - 1 ) begin
                    act_h_a[time_2]    <= 0;
                    delta_h_a[time_2]  <= 0;
                    delta_h_we[time_2] <= 0;
                    delta_y_a[time_2]  <= 0;
                    time_2             <= 0;
                    state              <= `BP_2;
                end
                else begin
                    internal_sram0_addr <= `ADDR_WO_START;
                    internal_sram1_addr <= `ADDR_WO_START;
                    internal_sram0_cs_n <= 0;
                    internal_sram1_cs_n <= 0;
                    act_h_a[time_2]     <= 0;
                    delta_h_a[time_2]   <= 0;
                    delta_h_we[time_2]  <= 0;
                    delta_y_a[time_2]   <= 0;
                    time_2              <= time_2 + 1;
                    state               <= `BP_1 + 32'h1;
                end
            end
            else if(delta_y_a[time_2] == `N_OUT - 1) begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram1_addr <= internal_sram1_addr + 1;
                internal_sram0_cs_n <= 0;
                internal_sram1_cs_n <= 0;
                act_h_a[time_2]     <= act_h_a[time_2] + 1;
                delta_h_a[time_2]   <= delta_h_a[time_2] + 1;
                delta_h_we[time_2]  <= 0;
                delta_y_a[time_2]   <= 0;
                state               <= `BP_1 + 32'h1;
            end
            else begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram1_addr <= internal_sram1_addr + 1;
                internal_sram0_cs_n <= 0;
                internal_sram1_cs_n <= 0;
                delta_y_a[time_2]   <= delta_y_a[time_2] + 1;
                delta_h_we[time_2]  <= 0;
                state               <= `BP_1 + 32'h1;
            end
        end


        /*****************************************************/
        /******** Backprop delta(hidden)  hidden->hidden   ***/
        /*****************************************************/
        else if(state == `BP_2) begin
            internal_sram0_addr <= `ADDR_WH_START;
            internal_sram0_cs_n <= 0;
            internal_sram1_addr <= `ADDR_WH_START;
            internal_sram1_cs_n <= 0;
            time_2              <= `TIMESTEP - 2;
            state               <= state + 1;
        end

        else if(state == `BP_2 + 32'h1) begin
            internal_sram0_cs_n <= 1;
            internal_sram1_cs_n <= 1;
            input_data_0        <= internal_sram0_data_input;
            input_data_1        <= internal_sram1_data_input;
            state               <= state + 1;
        end

        else if(state == `BP_2 + 32'h2) begin
            mul_16_20_20_data_a <= {input_data_0, input_data_1};
            mul_16_20_20_data_b <= delta_h_q[time_2+1];
            state               <= state + 1;
        end

        else if(state == `BP_2 + 32'h3) begin
            mul_16_20_20_data_a <= d_h_q[time_2];
            mul_16_20_20_data_b <= mul_16_20_20_data_y;
            state               <= state + 1;
        end

        else if(state == `BP_2 + 32'h4) begin
            add_20_20_20_data_a <= delta_h_q[time_2];
            add_20_20_20_data_b <= mul_16_20_20_data_y;
            state               <= state + 1;
        end

        else if(state == `BP_2 + 32'h5) begin
            delta_h_we[time_2] <= 1;
            delta_h_d[time_2]  <= add_20_20_20_data_y;
            state              <= state + 1;
        end

        else if(state == `BP_2 + 32'h6) begin
            if(
            delta_h_a[time_2]   == `N_H - 1 &&
            act_h_a[time_2]     == `N_H - 1 &&
            delta_h_a[time_2+1] == `N_H - 1  ) begin
                if(time_2 == 0) begin
                    delta_h_a[time_2]   <= 0;
                    delta_h_we[time_2]  <= 0;
                    act_h_a[time_2]     <= 0;
                    delta_h_a[time_2+1] <= 0;
                    time_2              <= 0;
                    state               <= `UPDATE_WO;
                end
                else begin
                    internal_sram0_addr <= `ADDR_WH_START;
                    internal_sram1_addr <= `ADDR_WH_START;
                    internal_sram0_cs_n <= 0;
                    internal_sram1_cs_n <= 0;
                    delta_h_a[time_2]   <= 0;
                    delta_h_we[time_2  ]<= 0;
                    act_h_a[time_2]     <= 0;
                    delta_h_a[time_2+1] <= 0;
                    time_2              <= time_2 - 1;
                    state               <= `BP_2 + 32'h1;
                end
            end
            else if(delta_h_a[time_2+1] == `N_H - 1) begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram1_addr <= internal_sram1_addr + 1;
                internal_sram0_cs_n <= 0;
                internal_sram1_cs_n <= 0;
                delta_h_a[time_2]   <= delta_h_a[time_2] + 1;
                act_h_a[time_2]     <= act_h_a[time_2] + 1;
                delta_h_a[time_2+1] <= 0;
                delta_h_we[time_2]  <= 0;
                state               <= `BP_2 + 32'h1;
            end
            else begin
                internal_sram0_addr <= internal_sram0_addr + 1;
                internal_sram1_addr <= internal_sram1_addr + 1;
                internal_sram0_cs_n <= 0;
                internal_sram1_cs_n <= 0;
                delta_h_a[time_2+1] <= delta_h_a[time_2+1] + 1;
                delta_h_we[time_2]  <= 0;
                state               <= `BP_2 + 32'h1;
            end
        end


        /*****************************************************/
        /******** 重み更新     (hidden - output)           ***/
        /*****************************************************/
        else if(state == `UPDATE_WO) begin
            internal_sram0_addr <= `ADDR_WO_START;
            internal_sram1_addr <= `ADDR_WO_START;
            time_2              <= 0;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WO + 32'h1) begin
            mul_8_12_16_data_a  <= act_h_q[time_2];
            mul_8_12_16_data_b  <= delta_y_q[time_2];
            state               <= state + 1;
        end

        else if(state == `UPDATE_WO + 32'h2) begin
            internal_sram0_cs_n   <= 0;
            internal_sram1_cs_n   <= 0;
            right_shift_16_data_x <= mul_8_12_16_data_y;
            state                 <= state + 1;
        end

        else if(state == `UPDATE_WO + 32'h3) begin
            internal_sram0_cs_n <= 1;
            internal_sram1_cs_n <= 1;
            input_data_0        <= internal_sram0_data_input;
            input_data_1        <= internal_sram1_data_input;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WO + 32'h4) begin
            sub_16_16_16_data_a <= {input_data_0, input_data_1}; 
            sub_16_16_16_data_b <= right_shift_16_data_y;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WO + 32'h5) begin
            output_data_0 <= sub_16_16_16_data_y[15:8];
            output_data_1 <= sub_16_16_16_data_y[7:0];
            state         <= state + 1;
        end

        else if(state == `UPDATE_WO + 32'h6) begin
            internal_sram0_data_output <= output_data_0;
            internal_sram0_data_output_en <= 1;
            internal_sram0_cs_n           <= 0;
            internal_sram0_we_n           <= 0;
            internal_sram1_data_output    <= output_data_1;
            internal_sram1_data_output_en <= 1;
            internal_sram1_cs_n           <= 0;
            internal_sram1_we_n           <= 0;
            state                         <= state + 1;
        end

        else if(state == `UPDATE_WO + 32'h7) begin
            internal_sram0_cs_n <= 1;
            internal_sram0_we_n <= 1;
            internal_sram1_cs_n <= 1;
            internal_sram1_we_n <= 1;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WO + 32'h8) begin
            if(
            act_h_a[time_2]   == `N_H       &&
            delta_y_a[time_2] == `N_OUT - 1  ) begin
                if(time_2 == `TIMESTEP - 1 ) begin
                    internal_sram0_data_output_en <= 0;
                    internal_sram1_data_output_en <= 0;
                    act_h_a[time_2]               <= 0;
                    delta_y_a[time_2]             <= 0;
                    time_2                        <= 0;
                    state                         <= `UPDATE_WH;
                end
                else begin
                    internal_sram0_addr           <= `ADDR_WO_START;
                    internal_sram1_addr           <= `ADDR_WO_START;
                    internal_sram0_data_output_en <= 0;
                    internal_sram1_data_output_en <= 0;
                    act_h_a[time_2]               <= 0;
                    delta_y_a[time_2]             <= 0;
                    time_2                        <= time_2 + 1;
                    state                         <= `UPDATE_WO + 32'h1;
                end
            end
            else if(delta_y_a[time_2] == `N_OUT - 1 ) begin
                internal_sram0_addr           <= internal_sram0_addr + 1;
                internal_sram1_addr           <= internal_sram0_addr + 1;
                internal_sram0_data_output_en <= 0;
                internal_sram1_data_output_en <= 0;
                act_h_a[time_2]               <= act_h_a[time_2] + 1;
                delta_y_a[time_2]             <= 0;
                state                         <= `UPDATE_WO + 32'h1;
            end
            else begin
                internal_sram0_addr           <= internal_sram0_addr + 1;
                internal_sram1_addr           <= internal_sram1_addr + 1;
                internal_sram0_data_output_en <= 0;
                internal_sram1_data_output_en <= 0;
                delta_y_a[time_2]             <= delta_y_a[time_2] + 1;
                state                         <= `UPDATE_WO + 32'h1;
            end
        end


        /*****************************************************/
        /******** 重み更新     (hidden - hidden)           ***/
        /*****************************************************/
        else if(state == `UPDATE_WH) begin
            internal_sram0_addr <= `ADDR_WH_START;
            internal_sram1_addr <= `ADDR_WH_START;
            time_2              <= `TIMESTEP - 2;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WH + 32'h1) begin
            mul_8_20_16_data_a <= act_h_q[time_2];
            mul_8_20_16_data_b <= delta_h_q[time_2+1];
            state              <= state + 1;
        end

        else if(state == `UPDATE_WH + 32'h2) begin
            internal_sram0_cs_n   <= 0;
            internal_sram1_cs_n   <= 0;
            right_shift_16_data_x <= mul_8_20_16_data_y;
            state                 <= state + 1;
        end

        else if(state == `UPDATE_WH + 32'h3) begin
            internal_sram0_cs_n <= 1;
            internal_sram1_cs_n <= 1;
            input_data_0        <= internal_sram0_data_input;
            input_data_1        <= internal_sram1_data_input;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WH + 32'h4) begin
            sub_16_16_16_data_a <= {input_data_0, input_data_1};
            sub_16_16_16_data_b <= right_shift_16_data_y;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WH + 32'h5) begin
            output_data_0 <= sub_16_16_16_data_y[15:8];
            output_data_1 <= sub_16_16_16_data_y[7:0];
            state         <= state + 1;
        end

        else if(state == `UPDATE_WH + 32'h6) begin
            internal_sram0_data_output    <= output_data_0;
            internal_sram0_data_output_en <= 1;
            internal_sram0_cs_n           <= 0;
            internal_sram0_we_n           <= 0;
            internal_sram1_data_output    <= output_data_1;
            internal_sram1_data_output_en <= 1;
            internal_sram1_cs_n           <= 0;
            internal_sram1_we_n           <= 0;
            state                         <= state + 1;
        end

        else if(state == `UPDATE_WH + 32'h7) begin
            internal_sram0_cs_n <= 1;
            internal_sram0_we_n <= 1;
            internal_sram1_cs_n <= 1;
            internal_sram1_we_n <= 1;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WH + 32'h8) begin
            if(
            act_h_a[time_2]     == `N_H     &&
            delta_h_a[time_2+1] == `N_H - 1  ) begin
                if(time_2 == 0 ) begin
                    internal_sram0_data_output_en <= 0;
                    internal_sram1_data_output_en <= 0;
                    act_h_a[time_2]               <= 0;
                    delta_h_a[time_2+1]           <= 0;
                    time_2                        <= 0;
                    state                         <= `UPDATE_WI;
                end
                else begin
                    internal_sram0_addr           <= `ADDR_WH_START;
                    internal_sram1_addr           <= `ADDR_WH_START;
                    internal_sram0_data_output_en <= 0;
                    internal_sram1_data_output_en <= 0;
                    act_h_a[time_2]               <= 0;
                    delta_h_a[time_2+1]           <= 0;
                    time_2                        <= time_2 - 1;
                    state                         <= `UPDATE_WH + 32'h1;
                end
            end
            else if(delta_h_a[time_2+1] == `N_H - 1 ) begin
                internal_sram0_addr           <= internal_sram0_addr + 1;
                internal_sram1_addr           <= internal_sram0_addr + 1;
                internal_sram0_data_output_en <= 0;
                internal_sram1_data_output_en <= 0;
                act_h_a[time_2]               <= act_h_a[time_2] + 1;
                delta_h_a[time_2+1]           <= 0;
                state                         <= `UPDATE_WH + 32'h1;
            end
            else begin
                internal_sram0_addr           <= internal_sram0_addr + 1;
                internal_sram1_addr           <= internal_sram1_addr + 1;
                internal_sram0_data_output_en <= 0;
                internal_sram1_data_output_en <= 0;
                delta_h_a[time_2+1]           <= delta_h_a[time_2+1] + 1;
                state                         <= `UPDATE_WH + 32'h1;
            end
        end


        /*****************************************************/
        /******** 重み更新     (input - hidden)           ***/
        /*****************************************************/
        else if(state == `UPDATE_WI) begin
            internal_sram0_addr <= `ADDR_WI_START;
            internal_sram1_addr <= `ADDR_WI_START;
            time_2              <= 0;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WI + 32'h1) begin
            mul_8_20_16_data_a <= x_q[time_2];
            mul_8_20_16_data_b <= delta_h_q[time_2];
            state              <= state + 1;
        end

        else if(state == `UPDATE_WI + 32'h2) begin
            internal_sram0_cs_n   <= 0;
            internal_sram1_cs_n   <= 0;
            right_shift_16_data_x <= mul_8_20_16_data_y;
            state                 <= state + 1;
        end

        else if(state == `UPDATE_WI + 32'h3) begin
            internal_sram0_cs_n <= 1;
            internal_sram1_cs_n <= 1;
            input_data_0        <= internal_sram0_data_input;
            input_data_1        <= internal_sram1_data_input;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WI + 32'h4) begin
            sub_16_16_16_data_a <= {input_data_0, input_data_1};
            sub_16_16_16_data_b <= right_shift_16_data_y;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WI + 32'h5) begin
            output_data_0 <= sub_16_16_16_data_y[15:8];
            output_data_1 <= sub_16_16_16_data_y[7:0];
            state         <= state + 1;
        end

        else if(state == `UPDATE_WI + 32'h6) begin
            internal_sram0_data_output    <= output_data_0;
            internal_sram0_data_output_en <= 1;
            internal_sram0_cs_n           <= 0;
            internal_sram0_we_n           <= 0;
            internal_sram1_data_output    <= output_data_1;
            internal_sram1_data_output_en <= 1;
            internal_sram1_cs_n           <= 0;
            internal_sram1_we_n           <= 0;
            state                         <= state + 1;
        end

        else if(state == `UPDATE_WI + 32'h7) begin
            internal_sram0_cs_n <= 1;
            internal_sram0_we_n <= 1;
            internal_sram1_cs_n <= 1;
            internal_sram1_we_n <= 1;
            state               <= state + 1;
        end

        else if(state == `UPDATE_WI + 32'h8) begin
            if(
            x_a[time_2]       == `N_IN    &&
            delta_h_a[time_2] == `N_H - 1  ) begin
                if(time_2 == `TIMESTEP - 1) begin
                    internal_sram0_data_output_en <= 0;
                    internal_sram1_data_output_en <= 0;
                    x_a[time_2]                   <= 0;
                    delta_h_a[time_2]             <= 0;
                    time_2                        <= 0;
                    state                         <= `FINISH;
                end
                else begin
                    internal_sram0_addr           <= `ADDR_WI_START;
                    internal_sram1_addr           <= `ADDR_WI_START;
                    internal_sram0_data_output_en <= 0;
                    internal_sram1_data_output_en <= 0;
                    x_a[time_2]                   <= 0;
                    delta_h_a[time_2]             <= 0;
                    time_2                        <= time_2 + 1;
                    state                         <= `UPDATE_WI + 32'h1;
                end
            end
            else if(delta_h_a[time_2] == `N_H - 1 ) begin
                internal_sram0_addr           <= internal_sram0_addr + 1;
                internal_sram1_addr           <= internal_sram0_addr + 1;
                internal_sram0_data_output_en <= 0;
                internal_sram1_data_output_en <= 0;
                x_a[time_2]                   <= x_a[time_2] + 1;
                delta_h_a[time_2]             <= 0;
                state                         <= `UPDATE_WI + 32'h1;
            end
            else begin
                internal_sram0_addr           <= internal_sram0_addr + 1;
                internal_sram1_addr           <= internal_sram1_addr + 1;
                internal_sram0_data_output_en <= 0;
                internal_sram1_data_output_en <= 0;
                delta_h_a[time_2]             <= delta_h_a[time_2] + 1;
                state                         <= `UPDATE_WI + 32'h1;
            end
        end


        else if(state == `FINISH) begin
            if(time_0 == `TIMESTEP - 1) begin
                time_0 <= 0;
                state  <= state + 1;
            end
            else begin
                time_0 <= time_0 + 1;
                state  <= state + 1;
            end
        end

        else if(state == `FINISH + 32'h1) begin
            internal_sram0_addr <= `ADDR_DEBUG_H_START;
            h_a                 <= 0;
            state               <= state + 1;
        end

        else if(state == `FINISH + 32'h2) begin
            output_data_0 <= {h_q[11], h_q[6:0]};
            state         <= state + 1;
        end

        else if(state == `FINISH + 32'h3) begin
            internal_sram0_data_output    <= output_data_0;
            internal_sram0_data_output_en <= 1;
            internal_sram0_cs_n           <= 0;
            internal_sram0_we_n           <= 0;
            state                         <= state + 1;
        end

        else if(state == `FINISH + 32'h4) begin
            internal_sram0_cs_n <= 1;
            internal_sram0_we_n <= 1;
            state               <= state + 1;
        end

        else if(state == `FINISH + 32'h5) begin
            if(
            internal_sram0_addr == `ADDR_DEBUG_H_END &&
            h_a                 == `N_H - 1           ) begin
                internal_sram0_addr           <= 0;
                internal_sram0_data_output_en <= 0;
                h_a                           <= 0;
                state                         <= `FINISH + 32'h6;
            end
            else begin
                internal_sram0_addr           <= internal_sram0_addr + 1;
                internal_sram0_data_output_en <= 0;
                h_a                           <= h_a + 1;
                state                         <= `FINISH + 32'h2;
            end
        end

        else if(state == `FINISH + 32'h6) begin
            internal_sram0_addr <= `ADDR_DEBUG_Y_START;
            y_a                 <= 0;
            state               <= state + 1;
        end

        else if(state == `FINISH + 32'h7) begin
            output_data_0 <= y_q;
            state         <= state + 1;
        end

        else if(state == `FINISH + 32'h8) begin
            internal_sram0_data_output    <= output_data_0;
            internal_sram0_data_output_en <= 1;
            internal_sram0_cs_n           <= 0;
            internal_sram0_we_n           <= 0;
            state                         <= state + 1;
        end

        else if(state == `FINISH + 32'h9) begin
            internal_sram0_cs_n <= 1;
            internal_sram0_we_n <= 1;
            state               <= state + 1;
        end

        else if(state == `FINISH + 32'ha) begin
            if(
            internal_sram0_addr == `ADDR_DEBUG_Y_END &&
            y_a                 == `N_OUT - 1         ) begin
                internal_sram0_addr           <= 0;
                internal_sram0_data_output_en <= 0;
                y_a                           <= 0;
                state                         <= `FINISH + 32'hb;
            end
            else begin
                internal_sram0_addr           <= internal_sram0_addr + 1;
                internal_sram0_data_output_en <= 0;
                y_a                           <= y_a + 1;
                state                         <= `FINISH + 32'h7;
            end
        end

        else if(state == `FINISH + 32'hb) begin
            gpio_out        <= 32'hf;
            internal_enable <= 0;
        end

        else begin
            internal_enable               <= 0;
            internal_sram0_addr           <= 0;
            internal_sram0_data_output    <= 0;
            internal_sram0_data_output_en <= 0;
            internal_sram0_cs_n           <= 1;
            internal_sram0_oe_n           <= 0;
            internal_sram0_we_n           <= 1;
            internal_sram1_addr           <= 0;
            internal_sram1_data_output    <= 0;
            internal_sram1_data_output_en <= 0;
            internal_sram1_cs_n           <= 1;
            internal_sram1_oe_n           <= 0;
            internal_sram1_we_n           <= 1;
            
            h_we <= 0; h_a <= 0; h_d <= 0;
            y_we <= 0; y_a <= 0; y_d <= 0;
            for(j = 0; j < `TIMESTEP; j = j + 1) begin
                x_we[j]     <= 0; x_a[j]         <= 0; x_d[j]       <= 0;
                t_we[j]     <= 0; t_a[j]         <= 0; t_d[j]       <= 0;
                act_h_we[j] <= 0; act_h_a[j]     <= 0; act_h_d[j]   <= 0;
                d_h_we[j]   <= 0; d_h_a[j]       <= 0; d_h_d[j]     <= 0;
                delta_y_we[j] <= 0; delta_y_a[j] <= 0; delta_y_d[j] <= 0;
                delta_h_we[j] <= 0; delta_h_a[j] <= 0; delta_h_d[j] <= 0;
            end 

            time_1 <= 0;
            time_2 <= 0;
            state  <= 0;
        end
    end // always (posedge clk) begin

    assign debug_2 = time_0;
    // assign debug_3 = h_q;
    // assign debug_4 = h_q[1];
    // assign debug_5 = h_q[2];
    // assign debug_6 = h_q[3];
    // assign debug_7 = h_q[4];

    // assign debug_2 = debug_2_reg;
    assign debug_3 = debug_3_reg;
    assign debug_4 = debug_4_reg;
    assign debug_5 = debug_5_reg;
    assign debug_6 = debug_6_reg;
    assign debug_7 = debug_7_reg;

endmodule


