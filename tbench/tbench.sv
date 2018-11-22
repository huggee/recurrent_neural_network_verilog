`ifndef DEFMACRO
    `include "../common/def.sv"
    `define DEFMACRO
`endif
`timescale 1ns/1ps
module tbench;

    reg clk;
    reg reset;
    reg [`R_DATA] sram0 [0:16383];
    reg [`R_DATA] sram1 [0:16383];
    reg [`R_DATA] input_data [0:9999];
    reg [`R_DATA] label_data [0:9999];

    reg [`R_DATA] x_in;
    reg [`R_DATA] t_in;

    wire [31:0] debug_2;
    wire [31:0] debug_3;
    wire [31:0] debug_4;
    wire [31:0] debug_5;
    wire [31:0] debug_6;
    wire [31:0] debug_7;

    reg [31:0] gpio_in;
    wire [31:0] gpio_out;
    wire internal_enable;

    wire [`R_SRAM_ADDR]internal_sram0_addr;
    wire [`R_DATA]internal_sram0_data_input;
    wire [`R_DATA]internal_sram0_data_output;
    wire internal_sram0_data_output_en;
    wire internal_sram0_cs_n;
    wire internal_sram0_oe_n;
    wire internal_sram0_we_n;

    wire [`R_SRAM_ADDR]internal_sram1_addr;
    wire [`R_DATA]internal_sram1_data_input;
    wire [`R_DATA]internal_sram1_data_output;
    wire internal_sram1_data_output_en;
    wire internal_sram1_cs_n;
    wire internal_sram1_oe_n;
    wire internal_sram1_we_n;

    reg [`R_SRAM_ADDR]tbench_sram0_addr;
    reg [`R_DATA]tbench_sram0_data_input;
    reg [`R_DATA]tbench_sram0_data_output;
    reg tbench_sram0_data_output_en;
    reg tbench_sram0_cs_n;
    reg tbench_sram0_oe_n;
    reg tbench_sram0_we_n;

    reg [`R_SRAM_ADDR]tbench_sram1_addr;
    reg [`R_DATA]tbench_sram1_data_input;
    reg [`R_DATA]tbench_sram1_data_output;
    reg tbench_sram1_data_output_en;
    reg tbench_sram1_cs_n;
    reg tbench_sram1_oe_n;
    reg tbench_sram1_we_n;

    reg  push_reset;

    reg [31:0] n_loop;
    reg [31:0] counter;

    integer i, j , F_HANDLE, F_LOSS;

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
        .internal_sram1_we_n           (internal_sram1_we_n),
        .debug_2                       (debug_2),
        .debug_3                       (debug_3),
        .debug_4                       (debug_4),
        .debug_5                       (debug_5),
        .debug_6                       (debug_6),
        .debug_7                       (debug_7)
    );

    /***** SRAM 0 *****/
    /*** Read ***/
    assign internal_sram0_data_input = (internal_enable     &&
                                       !internal_sram0_cs_n &&
                                       !internal_sram0_data_output_en)?
                                        sram0[internal_sram0_addr] : 8'hXX;
    // /*** Write ***/
    always @(posedge clk) begin
        if(internal_enable) begin
            if(!internal_sram0_cs_n && !internal_sram0_we_n && internal_sram0_data_output_en ) begin
                sram0[internal_sram0_addr] <= internal_sram0_data_output;
            end
        end
        else begin
            if(!tbench_sram0_cs_n && !tbench_sram0_we_n && tbench_sram0_data_output_en) begin
                sram0[tbench_sram0_addr] <= tbench_sram0_data_output;
            end
        end
    end

    /***** SRAM 1 *****/
    /*** Read ***/
    assign internal_sram1_data_input = (internal_enable     &&
                                       !internal_sram1_cs_n &&
                                       !internal_sram1_data_output_en)?
                                        sram1[internal_sram1_addr] : 8'hXX;

    /*** Write ***/
    always @(posedge clk) begin
        if(internal_enable) begin
            if(!internal_sram1_cs_n && !internal_sram1_we_n && internal_sram1_data_output_en ) begin
                sram1[internal_sram1_addr] <= internal_sram1_data_output;
            end
        end
        else begin
            if(!tbench_sram1_cs_n && !tbench_sram1_we_n && tbench_sram1_data_output_en) begin
                sram1[tbench_sram1_addr] <= tbench_sram1_data_output;
            end
        end
    end

    // クロック
    always #(`CLOCK_PERIOD/2) begin
        clk <= ~clk;
    end

    always @(posedge clk) begin
        if(reset) begin
            counter <= 0;
        end
        else begin
            counter <= counter + 1;
        end
    end


    // リセット
    task global_reset;
    begin
        @(posedge clk)
        #10
        reset <= 1;
        @(posedge clk)
        #10
        reset <= 0;
    end
    endtask

    // SRAM初期化
    task sram_initialization;
    begin
        for(i = 0; i <= 16383; i = i + 1)
        begin
            sram0[i] <= 8'b0_00_00000;
            sram1[i] <= 8'b0_00_00000;
        end

        #10
        // $readmemb("../src/tbench/weight_learned_sram0.mem", sram0, `ADDR_WI_START, `ADDR_WO_END);
        // $readmemb("../src/tbench/weight_learned_sram1.mem", sram1, `ADDR_WI_START, `ADDR_WO_END);
        // $readmemb("../src/tbench/weight_rtl_learned_sram0.mem", sram0, `ADDR_WI_START, `ADDR_WO_END);
        // $readmemb("../src/tbench/weight_rtl_learned_sram1.mem", sram1, `ADDR_WI_START, `ADDR_WO_END);
        $readmemb("../src/tbench/weight_init_sram0.mem", sram0, `ADDR_WI_START, `ADDR_WO_END);
        // $readmemb("../src/tbench/weight_init_sram1.mem", sram1, `ADDR_WI_START, `ADDR_WO_END);

        #10
        $readmemb("../src/tbench/input.mem", input_data);
        $readmemb("../src/tbench/label.mem", label_data);
    end
    endtask

    // task update_input_label(input [31:0] n_loop);
    // begin
    //     for(i = n_loop; i <= n_loop + `N_IN; i = i + 1)
    //         sram0[]
    // end
    // endtask

    // テストシナリオ
    initial begin
        F_HANDLE = $fopen("./weight.log");
        F_LOSS  = $fopen("./loss.log");

        clk        <= 0;
        reset      <= 0;
        push_reset <= 0;
        n_loop     <= 0;

        x_in <= 0;
        t_in <= 0;

        tbench_sram0_addr           <= 0;
        tbench_sram0_data_input     <= 0;
        tbench_sram0_data_output    <= 0;
        tbench_sram0_data_output_en <= 0;
        tbench_sram0_cs_n           <= 1;
        tbench_sram0_we_n           <= 1;
        tbench_sram0_oe_n           <= 0;

        tbench_sram1_addr           <= 0;
        tbench_sram1_data_input     <= 0;
        tbench_sram1_data_output    <= 0;
        tbench_sram1_data_output_en <= 0;
        tbench_sram1_cs_n           <= 1;
        tbench_sram1_we_n           <= 1;
        tbench_sram1_oe_n           <= 0;

        $monitoron;

        /*****************************************************/
        /******** Feedforward      input -> hidden         ***/
        /*****************************************************/
        // $monitor("n_loop %d, internal_enable %b, sram0_cs_n %b, sram0_we_n %b, sram0_data_output_en %b, state %5h, time_0 %1h, x_a %d, h_a %d, sram_addr %d, x_q %h, sram0_data_input %h, mul_8_8_8_a %h, mul_8_8_8_b %h, mul_8_8_8_y %h",
        // n_loop,
        // internal_enable,
        // internal_sram0_cs_n,
        // internal_sram0_we_n,
        // internal_sram0_data_output_en,
        // inst_rnn_top.state,
        // inst_rnn_top.time_0,
        // inst_rnn_top.x_a[0],
        // inst_rnn_top.h_a[0],
        // internal_sram0_addr,
        // inst_rnn_top.x_q[0],
        // internal_sram0_data_input,
        // inst_rnn_top.mul_8_8_8_data_a,
        // inst_rnn_top.mul_8_8_8_data_b,
        // inst_rnn_top.mul_8_8_8_data_y
        // );

        // /*****************************************************/
        // /******** Feedforward      hidden -> hidden         ***/
        // /*****************************************************/
        // $monitor("state %5h, time_0 %1h, time_1 %1h, h_a %d, act_h_a %d, sram_addr %d",
        // inst_rnn_top.state,
        // inst_rnn_top.time_0,
        // inst_rnn_top.time_1,
        // inst_rnn_top.h_a[0],
        // inst_rnn_top.act_h_a[9],
        // internal_sram0_addr
        // );
        
        // /*****************************************************/
        // /******** Feedforward      hidden -> output         ***/
        // /*****************************************************/
        // $monitor("state %5h, time_0 %1h, act_h_a %d, y_a %d, sram_addr %d",
        // inst_rnn_top.state,
        // inst_rnn_top.time_0,
        // inst_rnn_top.act_h_a[0],
        // inst_rnn_top.y_a[0],
        // internal_sram0_addr
        // );

        // /*****************************************************/
        // /******** Backprop delta(output)  ****/
        // /*****************************************************/

        // $monitor("state %5h, time_0 %1h, time_2 %1h, act_y_a %d, d_y_a %d",
        // inst_rnn_top.state,
        // inst_rnn_top.time_0,
        // inst_rnn_top.time_2,
        // inst_rnn_top.act_y_a[0],
        // inst_rnn_top.d_y_a[0]
        // );

        // /*****************************************************/
        // /******** Backprop delta(hidden)  output->hidden   ***/
        // /*****************************************************/

        // $monitor("state %5h, time_0 %1h, time_2 %1h, act_h_a %d, delta_h_a %d, delta_y_a %d, sram_addr %d",
        // inst_rnn_top.state,
        // inst_rnn_top.time_0,
        // inst_rnn_top.time_2,
        // inst_rnn_top.act_h_a[0],
        // inst_rnn_top.delta_h_a[0],
        // inst_rnn_top.delta_y_a[0],
        // internal_sram0_addr
        // );

        // /*****************************************************/
        // /******** Backprop delta(hidden)  hidden->hidden   ***/
        // /*****************************************************/

        // $monitor("state %5h, time_0 %1h, time_2 %1h, time_2+1 %1h, delta_h_a %d, act_h_a %d, delta_h_a(t+1) %d, sram_addr %d, acc_16 %h",
        // inst_rnn_top.state,
        // inst_rnn_top.time_0,
        // inst_rnn_top.time_2,
        // inst_rnn_top.time_2,
        // inst_rnn_top.delta_h_a[8],
        // inst_rnn_top.act_h_a[8],
        // inst_rnn_top.delta_h_a[9],
        // internal_sram0_addr,
        // inst_rnn_top.acc_16
        // );

        /*****************************************************/
        /******** 重み更新     (hidden - output)           ***/
        /*****************************************************/
        // $monitor("state %5h, time_0 %1h, time_2 %1h, act_h_a %d, delta_y_a %d, sram_addr %d, mul_8_20_16_a %h, mul_8_20_16_b %h, mul_8_20_16_y %h, add_16_16_16_data_a %h, add_16_16_16_data_b %h, add_16_16_16_data_y %h",
        // inst_rnn_top.state,
        // inst_rnn_top.time_0,
        // inst_rnn_top.time_2,
        // inst_rnn_top.act_h_a[0],
        // inst_rnn_top.delta_y_a[0],
        // internal_sram0_addr,
        // inst_rnn_top.mul_8_20_16_data_a,
        // inst_rnn_top.mul_8_20_16_data_b,
        // inst_rnn_top.mul_8_20_16_data_y,
        // inst_rnn_top.add_16_16_16_data_a,
        // inst_rnn_top.add_16_16_16_data_b,
        // inst_rnn_top.add_16_16_16_data_y
        // );

        // /*****************************************************/
        // /******** 重み更新     (hidden - hidden)           ***/
        // /*****************************************************/
        // $monitor("state %5h, time_0 %1h, time_2 %1h, act_h_a %d, delta_h_a %d, sram_addr %d",
        // inst_rnn_top.state,
        // inst_rnn_top.time_0,
        // inst_rnn_top.time_2,
        // inst_rnn_top.act_h_a[0],
        // inst_rnn_top.delta_h_a[1],
        // internal_sram0_addr
        // );

        // /*****************************************************/
        // /******** 重み更新     (input - hidden)           ***/
        // /*****************************************************/
        // $monitor("state %5h, time_0 %1h, time_2 %1h, x_a %d, delta_h_a %d, sram_addr %d",
        // inst_rnn_top.state,
        // inst_rnn_top.time_0,
        // inst_rnn_top.time_2,
        // inst_rnn_top.x_a[0],
        // inst_rnn_top.delta_h_a[0],
        // internal_sram0_addr,
        // );

        sram_initialization();

        global_reset();

        $fdisplay(F_HANDLE, "**************");
        $fdisplay(F_HANDLE, "*** BEFOR ****");
        $fdisplay(F_HANDLE, "**************");
        $fdisplay(F_HANDLE, "***** WI *****");
        for(i = `ADDR_WI_START; i <= `ADDR_WI_END; i = i + 1) begin
            $fdisplay(F_HANDLE, "sram[%d] %b, sram[%h] %b", i, sram0[i], i, sram1[i]);
        end
        $fdisplay(F_HANDLE, "***** WH *****");
        for(i = `ADDR_WH_START; i <= `ADDR_WH_END; i = i + 1) begin
            $fdisplay(F_HANDLE, "sram[%d] %b, sram[%h] %b", i, sram0[i], i, sram1[i]);
        end
        $fdisplay(F_HANDLE, "***** WO *****");
        for(i = `ADDR_WO_START; i <= `ADDR_WO_END; i = i + 1) begin
            $fdisplay(F_HANDLE, "sram[%d] %b, sram[%h] %b", i, sram0[i], i, sram1[i]);
        end
        $fdisplay(F_HANDLE, "****** INPUT *****");
        for(i = 0; i <= 10000; i = i + 1) begin
            $fdisplay(F_HANDLE, "input_data[%h] %b", i, input_data[i]);
        end
        $fdisplay(F_HANDLE, "****** LABEL *****");
        for(i = 0; i <= 10000; i = i + 1) begin
            $fdisplay(F_HANDLE, "label_data[%h] %b", i, label_data[i]);
        end

        repeat(300) begin
            @(posedge clk);
            @(posedge clk);

            
            x_in <= input_data[n_loop % 8];

            @(posedge clk);
            @(posedge clk);

            for(i = `ADDR_INPUT_START; i <= `ADDR_INPUT_END; i = i + 1) begin
                tbench_sram0_addr <= i;
                tbench_sram0_cs_n <= 0;
                tbench_sram0_we_n <= 0;
                tbench_sram0_data_output_en <= 1;
                tbench_sram0_data_output <= x_in;
                @(posedge clk);
                @(posedge clk);
                // $display("%b sram0_addr %h, n_loop %d, data_output %b, input_data %b, sram0[%h] %b", internal_enable, tbench_sram0_addr, n_loop, tbench_sram0_data_output, input_data[n_loop], i, sram0[i]);
            end

            tbench_sram0_cs_n <= 1;
            tbench_sram0_we_n <= 1;
            tbench_sram0_data_output_en <= 0;

            @(posedge clk);
            @(posedge clk);

            for(i = `ADDR_LABEL_START; i <= `ADDR_LABEL_END; i = i + 1) begin
                tbench_sram0_addr <= i;
                tbench_sram0_cs_n <= 0;
                tbench_sram0_we_n <= 0;
                tbench_sram0_data_output_en <= 1;
                tbench_sram0_data_output <= t_in;
                @(posedge clk);
                @(posedge clk);
                // $display("%b sram0_addr %h, n_loop %d, data_output %b, label_data %b, sram0[%h] %b", internal_enable, tbench_sram0_addr, n_loop, tbench_sram0_data_output, label_data[n_loop], i, sram0[i]);
            end

            tbench_sram0_cs_n <= 1;
            tbench_sram0_we_n <= 1;
            tbench_sram0_data_output_en <= 0;

            @(posedge clk);

            @(posedge clk);
            /***** Reset *****/
            @(posedge clk);
            gpio_in <= 32'h10;

            @(posedge clk);
            while(gpio_out != 32'h10) @(posedge clk);
            /***** Run *****/
            @(posedge clk);
            // gpio_in <= 32'h4;
            gpio_in <= 32'h8;
            @(posedge clk);
            while(gpio_out != 32'hf) @(posedge clk);

            // if(n_loop % 4 == 3)
            //     t_in <= 8'b00100000;
            // else
            //     t_in <= 8'b00000000;
            t_in <= x_in;


            @(posedge clk);
            // if(tbench.inst_rnn_top.time_0 == 0) begin
                for(i = 0; i <= `N_OUT - 1; i = i + 1) begin
                    /****************************************/
                    /************** INPUT *******************/
                    /****************************************/
                    // $display("%d sram0[%3h] %b, x0 %b, x1 %b, x2 %b, x3 %b, x4 %b, x5 %b, x6 %b, x7 %b, x8 %b, x9 %b",
                    //     n_loop,
                    //     `ADDR_INPUT_START+i,
                    //     sram0[`ADDR_INPUT_START+i],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[0].inst_x_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[1].inst_x_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[2].inst_x_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[3].inst_x_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[4].inst_x_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[5].inst_x_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[6].inst_x_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[7].inst_x_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[8].inst_x_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[9].inst_x_buffer.ram[0]
                    // );

                    // /****************************************/
                    // /************** LABEL  *******************/
                    // /****************************************/
                    // $display("%d sram0[%3h] %b, t0 %b, t1 %b, t2 %b, t3 %b, t4 %b, t5 %b, t6 %b, t7 %b, t8 %b, t9 %b",
                    //     n_loop,
                    //     `ADDR_LABEL_START+i,
                    //     sram0[`ADDR_LABEL_START+i],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[0].inst_t_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[1].inst_t_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[2].inst_t_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[3].inst_t_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[4].inst_t_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[5].inst_t_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[6].inst_t_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[7].inst_t_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[8].inst_t_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[9].inst_t_buffer.ram[0]
                    // );

                    /****************************************/
                    /************** OUTPUT ******************/
                    /****************************************/
                    // $display("%d sram0[%3h] %b, y0 %b, y1 %b, y2 %b, y3 %b, y4 %b, y5 %b, y6 %b, y7 %b, y8 %b, y9 %b",
                    //     n_loop,
                    //     `ADDR_OUTPUT_START+i,
                    //     sram0[`ADDR_OUTPUT_START+i],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[0].inst_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[1].inst_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[2].inst_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[3].inst_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[4].inst_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[5].inst_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[6].inst_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[7].inst_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[8].inst_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[9].inst_y_buffer.ram[0]
                    // );

                    // $display("%d sram0[%3h] %b, act_y0 %b, act_y1 %b, act_y2 %b, act_y3 %b, act_y4 %b, act_y5 %b, act_y6 %b, act_y7 %b, act_y8 %b, act_y9 %b",
                    //     n_loop,
                    //     `ADDR_OUTPUT_START+i,
                    //     sram0[`ADDR_OUTPUT_START+i],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[0].inst_act_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[1].inst_act_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[2].inst_act_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[3].inst_act_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[4].inst_act_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[5].inst_act_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[6].inst_act_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[7].inst_act_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[8].inst_act_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[9].inst_act_y_buffer.ram[0]
                    // );

                    /****************************************/
                    /************** HIDDEN ******************/
                    /****************************************/
                    // $display("%d sram0[%3h] %b, h0 %b, h1 %b, h2 %b, h3 %b, h4 %b, h5 %b, h6 %b, h7 %b, h8 %b, h9 %b",
                    //     n_loop,
                    //     `ADDR_OUTPUT_START+i,
                    //     sram0[`ADDR_OUTPUT_START+i],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[0].inst_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[1].inst_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[2].inst_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[3].inst_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[4].inst_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[5].inst_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[6].inst_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[7].inst_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[8].inst_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[9].inst_h_buffer.ram[0]
                    // );

                    // $display("%d sram0[%3h] %b, act_h0 %b, act_h1 %b, act_h2 %b, act_h3 %b, act_h4 %b, act_h5 %b, act_h6 %b, act_h7 %b, act_h8 %b, act_h9 %b",
                    //     n_loop,
                    //     `ADDR_OUTPUT_START+i,
                    //     sram0[`ADDR_OUTPUT_START+i],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[0].inst_act_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[1].inst_act_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[2].inst_act_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[3].inst_act_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[4].inst_act_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[5].inst_act_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[6].inst_act_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[7].inst_act_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[8].inst_act_h_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[9].inst_act_h_buffer.ram[0]
                    // );

                    // /****************************************/
                    // /************** D_Y    ******************/
                    // /****************************************/
                    // $display("%d sram0[%3h] %b, d_y0 %b, d_y1 %b, d_y2 %b, d_y3 %b, d_y4 %b, d_y5 %b, d_y6 %b, d_y7 %b, d_y8 %b, d_y9 %b",
                    //     n_loop,
                    //     `ADDR_OUTPUT_START+i,
                    //     sram0[`ADDR_OUTPUT_START+i],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[0].inst_d_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[1].inst_d_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[2].inst_d_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[3].inst_d_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[4].inst_d_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[5].inst_d_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[6].inst_d_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[7].inst_d_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[8].inst_d_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[9].inst_d_y_buffer.ram[0]
                    // );

                    /****************************************/
                    /************** DELTA_Y    ******************/
                    /****************************************/
                    // $display("%d sram0[%3h] %h, delta_y0 %h, delta_y1 %h, delta_y2 %h, delta_y3 %h, delta_y4 %h, delta_y5 %h, delta_y6 %h, delta_y7 %h, delta_y8 %h, delta_y9 %h",
                    //     n_loop,
                    //     `ADDR_OUTPUT_START+i,
                    //     sram0[`ADDR_OUTPUT_START+i],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[0].inst_delta_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[1].inst_delta_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[2].inst_delta_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[3].inst_delta_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[4].inst_delta_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[5].inst_delta_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[6].inst_delta_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[7].inst_delta_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[8].inst_delta_y_buffer.ram[0],
                    //     tbench.inst_rnn_top.loop_gen_inst_buffer[9].inst_delta_y_buffer.ram[0]
                    // );

                    /*******************************************/
                    /*************** SRAM **********************/
                    /*******************************************/
                    $display("%d %d input:srma0[%3h] %b, label:sram0[%3h] %b, output:sram0[%3h] %b, debug_2:%h, debug_3:%h, debug_4:%h, debug_5:%h, debug_6:%h, debug_7:%h",
                        counter,
                        n_loop,
                        `ADDR_INPUT_START+i,
                        sram0[`ADDR_INPUT_START+i],
                        `ADDR_LABEL_START+i,
                        sram0[`ADDR_LABEL_START+i],
                        `ADDR_OUTPUT_START+i,
                        sram0[`ADDR_OUTPUT_START+i],
                        debug_2,
                        debug_3,
                        debug_4,
                        debug_5,
                        debug_6,
                        debug_7
                        );
                    //$fdisplay(F_LOSS, "%b %b", sram0[`ADDR_LABEL_START+i], sram0[`ADDR_OUTPUT_START+i]);
                    @(posedge clk);
                end // for
            // end // if
            // $fdisplay(F_LOSS, "%b", tbench.inst_rnn_top.loop_gen_inst_buffer[0].inst_delta_y_buffer.ram[0]);
            @(posedge clk);

            if(n_loop == 10000) n_loop <= 0;
            else                n_loop <= n_loop + 1;
        end // repeat

        $fdisplay(F_HANDLE, "**************");
        $fdisplay(F_HANDLE, "*** AFTER ****");
        $fdisplay(F_HANDLE, "**************");
        $fdisplay(F_HANDLE, "***** WI *****");
        for(i = `ADDR_WI_START; i <= `ADDR_WI_END; i = i + 1) begin
            $fdisplay(F_HANDLE, "sram[%d] %b, sram[%h] %b", i, sram0[i], i, sram1[i]);
        end
        $fdisplay(F_HANDLE, "***** WH *****");
        for(i = `ADDR_WH_START; i <= `ADDR_WH_END; i = i + 1) begin
            $fdisplay(F_HANDLE, "sram[%d] %b, sram[%h] %b", i, sram0[i], i, sram1[i]);
        end
        $fdisplay(F_HANDLE, "***** WO *****");
        for(i = `ADDR_WO_START; i <= `ADDR_WO_END; i = i + 1) begin
            $fdisplay(F_HANDLE, "sram[%d] %b, sram[%h] %b", i, sram0[i], i, sram1[i]);
        end


        $display("******* H ******");
        for(i = `ADDR_DEBUG_H_START; i <= `ADDR_DEBUG_H_END; i = i + 1) begin
            $display("sram0[%d] %h %b", i, sram0[i], sram0[i]);
        end

        $display("******* Y ******");
        for(i = `ADDR_DEBUG_Y_START; i <= `ADDR_DEBUG_Y_END; i = i + 1) begin
            $display("sram0[%d] %h %b", i, sram0[i], sram0[i]);
        end


        $monitoroff;
        $finish();
    end



endmodule
