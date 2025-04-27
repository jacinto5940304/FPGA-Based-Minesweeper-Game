    reg [3:0] input_map [0:3][0:7];

    // input map management
    always @(*) begin
        if(state == STATE_SAND) begin
            if (been_ready && key_down[last_change] == 1'b1) begin
                if(is_flag_or_flip[key_num_y][key_num_x] == 4'd0) begin
                    if(key_num_x != 5'd31 && key_num_y != 5'd31) begin
                        input_map[key_num_y][key_num_x] = 4'd6;    
                    end
                end
            end
        end
        else begin
            input_map[0][0] = 4'd0; input_map[0][1] = 4'd0; input_map[0][2] = 4'd0; input_map[0][3] = 4'd0; input_map[0][4] = 4'd0; input_map[0][5] = 4'd0; input_map[0][6] = 4'd0; input_map[0][7] = 4'd0;
            input_map[1][0] = 4'd0; input_map[1][1] = 4'd0; input_map[1][2] = 4'd0; input_map[1][3] = 4'd0; input_map[1][4] = 4'd0; input_map[1][5] = 4'd0; input_map[1][6] = 4'd0; input_map[1][7] = 4'd0;
            input_map[2][0] = 4'd0; input_map[2][1] = 4'd6; input_map[2][2] = 4'd0; input_map[2][3] = 4'd0; input_map[2][4] = 4'd0; input_map[2][5] = 4'd0; input_map[2][6] = 4'd0; input_map[2][7] = 4'd0;
            input_map[3][0] = 4'd0; input_map[3][1] = 4'd0; input_map[3][2] = 4'd0; input_map[3][3] = 4'd0; input_map[3][4] = 4'd0; input_map[3][5] = 4'd0; input_map[3][6] = 4'd0; input_map[3][7] = 4'd0;
        end
    end

    // generate the answer map
    reg [3:0] def_map [0:3][0:7];
    always @(*) begin
        case (state)
            // target : use random and generate the hint number
            STATE_IDLE: begin
                def_map[0][0] = 4'd0; def_map[0][1] = 4'd0; def_map[0][2] = 4'd0; def_map[0][3] = 4'd0; def_map[0][4] = 4'd0; def_map[0][5] = 4'd0; def_map[0][6] = 4'd0; def_map[0][7] = 4'd0;
                def_map[1][0] = 4'd0; def_map[1][1] = 4'd0; def_map[1][2] = 4'd6; def_map[1][3] = 4'd0; def_map[1][4] = 4'd0; def_map[1][5] = 4'd0; def_map[1][6] = 4'd0; def_map[1][7] = 4'd0;
                def_map[2][0] = 4'd0; def_map[2][1] = 4'd6; def_map[2][2] = 4'd0; def_map[2][3] = 4'd6; def_map[2][4] = 4'd0; def_map[2][5] = 4'd0; def_map[2][6] = 4'd0; def_map[2][7] = 4'd0;
                def_map[3][0] = 4'd0; def_map[3][1] = 4'd0; def_map[3][2] = 4'd0; def_map[3][3] = 4'd0; def_map[3][4] = 4'd0; def_map[3][5] = 4'd0; def_map[3][6] = 4'd0; def_map[3][7] = 4'd0;
                // random
                // def_map[counter_y % 4][counter_x % 8] = 4'd6;
                // def_map[(counter_y+counter_x) % 4][(counter_y+counter_x) % 8] = 4'd6;
                // def_map[(3*counter_y) % 4][(3*counter_y+counter_x) % 8] = 4'd6;
                // def_map[(counter_y*5) % 4][(counter_x*5) % 8] = 4'd6;
                // def_map[(3*counter_y+counter_x) % 4][(3*counter_y+counter_x) % 8] = 4'd6;
                // def_map[(3*counter_y + 2) % 4][(3*counter_y+counter_x + 4) % 8] = 4'd6;
                // def_map[(5*counter_y+2*counter_x)  % 4][(5*counter_y+2*counter_x)  % 8] = 4'd6;
                // def_map[(7*counter_y) % 4][(4*counter_x) % 8] = 4'd6;
                // def_map[(3*counter_y + 5) % 4][(3*counter_x + 5) % 8] = 4'd6;  
                // def_map[(counter_y + 3) % 4][(counter_x + 3) % 8] = 4'd6;    
                // generate the hint number
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        if(def_map[j][i] == 4'd6) begin
                            if(i>0 && j>0 && def_map[j-1][i-1] < 4'd5) begin    //1
                                def_map[j-1][i-1] = def_map[j-1][i-1] + 1;
                            end
                            if(j>0 && def_map[j-1][i] < 4'd5) begin             //2
                                def_map[j-1][i] = def_map[j-1][i] + 1;
                            end
                            if(i<7 && j>0 && def_map[j-1][i+1] < 4'd5) begin    //3 
                                def_map[j-1][i+1] = def_map[j-1][i+1] + 1;
                            end
                            if(i>0 && def_map[j][i-1] < 4'd5) begin             //4
                                def_map[j][i-1] = def_map[j][i-1] + 1;
                            end
                            if(i<7 && def_map[j][i+1] < 4'd5) begin             //6
                                def_map[j][i+1] = def_map[j][i+1] + 1;
                            end
                            if(i>0 && j<3 && def_map[j+1][i-1] < 4'd5) begin    //7
                                def_map[j+1][i-1] = def_map[j+1][i-1] + 1;
                            end
                            if(j<3 && def_map[j+1][i] < 4'd5) begin             //8
                                def_map[j+1][i] = def_map[j+1][i] + 1;
                            end
                            if(i<7 && j<3 && def_map[j+1][i+1] < 4'd5) begin    //9
                                def_map[j+1][i+1] = def_map[j+1][i+1] + 1;
                            end
                        end
                    end
                end
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        if(def_map[j][i] == 4'd0) begin
                            def_map[j][i] = 4'd8;
                        end
                    end
                end
            end
            // operator cant in the NORMAL state !!!
            STATE_NORMAL: begin
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        def_map[j][i] = def_map[j][i];
                    end
                end 
            end
            // hard : install the mines
            // target : install the mines and generate the hint number
            STATE_SAND: begin
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        def_map[j][i] = input_map[j][i];
                    end
                end   
                if (been_ready && key_down[last_change] == 1'b1) begin
                    if(is_flag_or_flip[key_num_y][key_num_x] == 4'd0) begin
                        if(key_num_x != 5'd31 && key_num_y != 5'd31) begin
                            def_map[key_num_y][key_num_x] = 4'd6;    
                        end
                    end
                end
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        if(def_map[j][i] == 4'd6) begin
                            if(i>0 && j>0 && def_map[j-1][i-1] < 4'd5) begin    //1
                                def_map[j-1][i-1] = def_map[j-1][i-1] + 1;
                            end
                            if(j>0 && def_map[j-1][i] < 4'd5) begin             //2
                                def_map[j-1][i] = def_map[j-1][i] + 1;
                            end
                            if(i<7 && j>0 && def_map[j-1][i+1] < 4'd5) begin    //3 
                                def_map[j-1][i+1] = def_map[j-1][i+1] + 1;
                            end
                            if(i>0 && def_map[j][i-1] < 4'd5) begin             //4
                                def_map[j][i-1] = def_map[j][i-1] + 1;
                            end
                            if(i<7 && def_map[j][i+1] < 4'd5) begin             //6
                                def_map[j][i+1] = def_map[j][i+1] + 1;
                            end
                            if(i>0 && j<3 && def_map[j+1][i-1] < 4'd5) begin    //7
                                def_map[j+1][i-1] = def_map[j+1][i-1] + 1;
                            end
                            if(j<3 && def_map[j+1][i] < 4'd5) begin             //8
                                def_map[j+1][i] = def_map[j+1][i] + 1;
                            end
                            if(i<7 && j<3 && def_map[j+1][i+1] < 4'd5) begin    //9
                                def_map[j+1][i+1] = def_map[j+1][i+1] + 1;
                            end
                        end
                    end
                end
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        if(def_map[j][i] == 4'd0) begin
                            def_map[j][i] = 4'd8;
                        end
                    end
                end
            end
            default: begin
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        def_map[j][i] = def_map[j][i];
                    end
                end 
            end
        endcase
    end