    /********** 全て0.25 **********/
    task sram_initialization;
        for(i = 0; i <= 4095 ; i = i + 1)
        begin
            sram0[i] <= 8'b0_00_01000;
            sram1[i] <= 8'b0_00_00000;
        end
    endtask

    /********** 適当 **********/
    task sram_initialization;
        for(i = 0; i <= 4095 ; i = i + 1)
        begin
            sram0[i] <= 8'b0_10_01001;
            sram1[i] <= 8'b1_00_10010;
        end
    endtask

    /********** 入力データ: 全て-0.25 **********/
    /********** ラベル    : 先頭だけ1 **********/ 
    /********** In -> Hiddenの重み : 全て-0.25 **********/
    /********** Hidden -> Outの重み: 全て0.25 **********/
    task sram_initialization;
        for(i = 0; i <= 4095 ; i = i + 1)
        begin
        if(i <= `ADDR_WH_END)
        begin
            sram0[i] <= 8'b1_11_11000;
            sram1[i] <= 8'b0_00_00000;
        end
        else if(i <= `ADDR_WO_END)
        begin
            sram0[i] <= 8'b0_00_01000;
            sram1[i] <= 8'b0_00_00000;
        end
        else if(i <= `ADDR_INPUT_END)
        begin
            sram0[i] <= 8'b1_11_11000;
        end
        else if(i <= `ADDR_LABEL_END)
        begin
            if(i == `ADDR_LABEL_START)
                sram0[i] <= 8'b0_01_00000;
            else
                sram0[i] <= 8'b0_00_00000;
        end

        end
    endtask

    /********** 適当な数字 **********/
    task sram_initialization;
        for(i = 0; i <= 4095 ; i = i + 1)
        begin
            // sram[i] <= 8'b0_00_01000;
            j = i % 10;
            if(i <=`ADDR_WH_END)
            begin
                if(j == 0 || j == 2 || j == 5 ||
                   j == 8 || j == 9)
                begin
                    sram0[i] <= 8'b0000_1000;
                    sram1[i] <= 8'b1111_1000;
                end
                else
                begin
                    sram0[i] <= 8'b1111_1001;
                    sram1[i] <= 8'b0000_1001;
                end
            end
            else if(i <= `ADDR_WO_END)
                if(j == 0 || j == 2 || j == 5 ||
                   j == 8 || j == 9)
                begin
                    sram0[i] <= 8'b0000_1010;
                    sram1[i] <= 8'b1111_1010;
                end
                else
                begin
                    sram0[i] <= 8'b1111_1011;
                    sram1[i] <= 8'b0000_1011;
                end
            else if(i <= `ADDR_INPUT_END)
                sram0[i] <= 8'b0000_0111 << (i % 8);
            else if(i <= `ADDR_LABEL_END)
                if(i == `ADDR_LABEL_END)
                    sram0[i] <= 8'b0010_0000;
                else
                    sram0[i] <= 8'b0000_0000;
        end
    endtask



    /********** 適当 **********/
    /********** DEC -> BIN encoder **********/
     task sram_label_init;
         if(j == 10)
         begin
             sram0[`ADDR_LABEL_START    ] <= 8'b0_00_00000;
             sram0[`ADDR_LABEL_START + 1] <= 8'b0_01_00000;
             sram0[`ADDR_LABEL_START + 2] <= 8'b1_00_01000;
             sram0[`ADDR_LABEL_START + 3] <= 8'b0_01_00000;
         end
     endtask

     /********** one-hot入力 **********/
     task sram_initialization;
     begin
         for(i = 0; i <= 4095 ; i = i + 1)
         begin
         if(i <= `ADDR_WH_END)
         begin
             sram0[i] <= 8'b0_00_10000;
             sram1[i] <= 0;
         end
         else if(i <= `ADDR_WO_END)
         begin
             sram0[i] <= 0;
             sram1[i] <= 0;
         end
         else if(i <= `ADDR_INPUT_END)
         begin
             if(i % 16 == 10)
             begin
                 j = i % 16;
                 sram0[i] <= 8'b0_01_00000;
                 sram1[i] <= 8'b0_01_00000;
             end
             else
             begin
                 sram0[i] <= 8'b0_00_01000;
                 sram1[i] <= 0;
             end
         end
         else if(i <= `ADDR_LABEL_END)
         begin
             sram0[i] <= 0;
             sram1[i] <= 0;
         end
    end
    end
     endtask
