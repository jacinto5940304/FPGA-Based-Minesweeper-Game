module final(
    input clk,
    input rst,
    input _BTNU, //button, up
    input _BTND, 
    input _BTNR,
    input _BTNL,
    input sw0,
    input sw1,
    input sw2, //test
    input sw15,
    inout wire PS2_DATA,
    inout wire PS2_CLK,
    output [3:0] DIGIT,
    output [6:0] DISPLAY,
    output reg [15:0] LED,
    output [3:0] vgaRed,
    output [3:0] vgaGreen,
    output [3:0] vgaBlue,
    output hsync,
    output vsync
);
    //test
    wire [3:0] random_x,
    wire [3:0] random_y
    
    // clock
    wire clk_23, clk_1hz, clk_25MHz;

    //mine_number
    wire [3:0] mine_number;
    integer i, j;

    //SevenSegment
    reg [15:0] nums = 16'hAAAA, next_nums;

    //time counter
    reg [7:0] time_cnt = 99, next_time_cnt;
    //reg [3:0] time_1, next_time_1, time_2, next_time_2;

    //button
    wire de_btnL, de_btnR, de_btnU, de_btnD, BTNU, BTND, BTNR, BTNL;

    //led
    reg [15:0] next_led;
    reg [3:0] cnt_led, next_cnt_led;

    //state
    reg [2:0] state, next_state, prev_state; //prev_state?????debug?????
    parameter STATE_IDLE    = 3'b000;
    parameter STATE_NORMAL   = 3'b001;
    parameter STATE_SAND = 3'b010;
    parameter STATE_WIN  = 3'b011;
    parameter STATE_LOSE  = 3'b100;
    parameter STATE_DEBUG = 3'b101;


    debounce d1(.clk(clk),.pb(_BTNL),.pb_debounced(de_btnL));
    debounce d2(.clk(clk),.pb(_BTNR),.pb_debounced(de_btnR));
    debounce d3(.clk(clk),.pb(_BTNU),.pb_debounced(de_btnU));
    debounce d4(.clk(clk),.pb(_BTND),.pb_debounced(de_btnD));
    one_pulse o1(.clk(clk),.pb_in(de_btnL),.pb_out(BTNL));
    one_pulse o2(.clk(clk),.pb_in(de_btnR),.pb_out(BTNR));
    one_pulse o3(.clk(clk),.pb_in(de_btnU),.pb_out(BTNU));
    one_pulse o4(.clk(clk),.pb_in(de_btnD),.pb_out(BTND));

    clock_divider #(23) c23(.clk(clk), .clk_div(clk_23));
    clock_divider_25M c25(.clk(clk), .clk1(clk_25MHz));
    my_clock_divider #(100_000_000) c_1hz(.clk(clk),.clk_div(clk_1hz));
    
    //ssg
    SevenSegment seven_seg (
        .display(DISPLAY),
        .digit(DIGIT),
        .nums(nums),
        .rst(rst),
        .clk(clk)
    );

    //keyboard   
	wire [511:0] key_down;
	wire [8:0] last_change;
	wire been_ready;

    KeyboardDecoder key_de (
        .key_down(key_down),
        .last_change(last_change),
        .key_valid(been_ready),
        .PS2_DATA(PS2_DATA),
        .PS2_CLK(PS2_CLK),
        .rst(rst),
        .clk(clk)
    );

    //vga
    wire valid;
    wire [9:0] h_cnt; //640
    wire [9:0] v_cnt;  //480

    my_pixel_gen pix_ge(
        .rst(rst),
        .clk(clk),
        .state(state),
        .h_cnt(h_cnt),
        .valid(valid),
        .vgaRed(vgaRed),
        .vgaGreen(vgaGreen),
        .vgaBlue(vgaBlue),
        .v_cnt(v_cnt),
        .key_down(key_down),
        .been_ready(been_ready),
        .last_change(last_change),
        .mine_number(mine_number),
        .random_x(random_x),
        .random_y(random_y)
    );
    vga_controller   vga_inst(
        .pclk(clk_25MHz),
        .reset(rst),
        .hsync(hsync),
        .vsync(vsync),
        .valid(valid),
        .h_cnt(h_cnt),
        .v_cnt(v_cnt)
    );

    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////

    
    //SevenSegment, nums
    always@(posedge clk)begin
        nums <= next_nums;
    end
    always@(*)begin
        next_nums = nums;
        case(state)
            STATE_IDLE :begin
                next_nums = 16'hAAAA; //----
            end
            STATE_NORMAL :begin
                next_nums[15:12] = mine_number/10;
                next_nums[11:8] = mine_number%10;
                // next_nums[7:4] = time_cnt/10;
                // next_nums[3:0] = time_cnt%10;
                next_nums[7:4] = random_x;
                next_nums[3:0] = random_y;
            end
            STATE_SAND :begin
                next_nums[15:12] = mine_number/10;
                next_nums[11:8] = mine_number%10;
                next_nums[7:4] = time_cnt/10;
                next_nums[3:0] = time_cnt%10;
            end
            STATE_WIN  :begin
                next_nums[15:12] = 4'hE;  //AA--
                next_nums[11:8] = 4'hE;
                next_nums[7:4] = time_cnt/10;
                next_nums[3:0] = time_cnt%10;
            end
            STATE_LOSE :begin
                next_nums = 16'hFFFF;
            end
            STATE_DEBUG : begin
                next_nums = 16'hDDDD; //
            end
        endcase
    end

    //time counter

    always@(posedge clk_1hz or posedge rst)begin
        if(rst)begin
            time_cnt <= 99;
        end
        else begin
            time_cnt <= next_time_cnt;
        end
    end
    always@(*)begin
        next_time_cnt = time_cnt;
        case(state)
            STATE_IDLE :begin
                next_time_cnt = 99;
            end
            STATE_NORMAL :begin
                if(time_cnt > 0)begin
                    next_time_cnt = time_cnt-1;
                end
            end
            STATE_SAND :begin
                if(time_cnt > 0)begin
                    next_time_cnt = time_cnt-1;
                end
            end
            STATE_WIN  :begin
                next_time_cnt = time_cnt;
            end
            STATE_LOSE :begin
                next_time_cnt = 99;
            end
            STATE_DEBUG : begin
                next_time_cnt = time_cnt;
            end
        endcase
    end
    
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
    //STATE
    always@(posedge clk or posedge rst)begin
        if(rst)begin
            state <= STATE_IDLE;
        end
        else begin
            state <= next_state;
        end
    end
    always@(*)begin
        next_state = state;
        case(state)
            STATE_IDLE :begin
                if(sw15)begin
                    prev_state = STATE_IDLE;
                    next_state = STATE_DEBUG;
                end
                else begin
                    if(BTNU && sw0)begin
                        next_state = STATE_NORMAL;
                    end
                    else if(BTNU && !sw0)begin
                        next_state = STATE_SAND;
                    end
                end
            end
            STATE_NORMAL :begin
                //test
                if(sw15)begin
                    prev_state = STATE_NORMAL;
                    next_state = STATE_DEBUG;
                end
                else begin
                    if(sw1)begin
                        next_state = STATE_WIN;
                    end
                    else if(time_cnt == 0)begin
                        next_state = STATE_LOSE;
                    end
                end
                //test
            end
            STATE_SAND :begin
                //test
                if(sw15)begin
                    prev_state = STATE_SAND;
                    next_state = STATE_DEBUG;
                end
                else begin
                    if(sw2)begin
                        next_state = STATE_LOSE;
                    end
                end
                //test
            end
            STATE_WIN  :begin
                if(cnt_led == 5)begin
                    next_state = STATE_IDLE;
                end
            end
            STATE_LOSE :begin
                if(cnt_led == 15)begin
                    next_state = STATE_IDLE;
                end
                else if(time_cnt == 0)begin
                    next_state = STATE_LOSE;
                end
            end
            STATE_DEBUG : begin
                if(!sw15)begin
                    next_state = prev_state;
                end
            end
        endcase
    end

//////////////////////////////////////////////////////////////////////////////////////////////////////////////

    //LED 
    always@(posedge rst or posedge clk_23)begin
        if(rst)begin
            LED[15:0] <= 16'b0000_0000_0000_0000;
            cnt_led <= 3'b0;
        end
        else begin
            LED[15:0] <= next_led[15:0];
            if(state == STATE_WIN || state == STATE_LOSE )
                cnt_led <= next_cnt_led;
            else 
                cnt_led <= 3'b0;
        end
    end
    always@(*)begin
        next_led[15:0] = LED[15:0];
        next_cnt_led[3:0] = cnt_led[3:0];

        case(state)
            STATE_IDLE : next_led = 16'b0000_0000_0000_0001;
            STATE_NORMAL : next_led = 16'b0000_0000_0000_0011;
            STATE_SAND : next_led = 16'b0000_0000_0000_1111;
            
            STATE_WIN: begin
                if(LED == 16'b0000_0000_0000_1111 || LED == 16'b0000_0000_0000_0011)next_led = 16'b1010_0000_0000_0000;
                else begin
                    //if(cnt_led == 5), change state to IDLE
                    if(LED != 16'b0000_0000_0000_0001)begin
                        next_led = LED/2;
                    end
                    else begin
                        next_led = 16'b1010_0000_0000_0000;
                        next_cnt_led = cnt_led + 1;
                    end
                end
            end

            STATE_LOSE : begin
                if(LED == 16'b0000_0000_0000_1111 || LED == 16'b0000_0000_0000_0011)next_led = 16'b0010_1000_0010_0001; //1
                else begin
                    //if(cnt_led == 15), change state to IDLE
                    if(LED == 16'b0010_1000_0010_0001)begin
                        next_led = 16'b0001_0100_1000_0010; //2
                    end
                    else if(LED == 16'b0001_0100_1000_0010)begin
                        next_led = 16'b0100_0010_0001_1000; //3
                    end
                    else if(LED == 16'b0100_0010_0001_1000)begin
                        next_led = 16'b0010_1000_0010_0001; //1
                        next_cnt_led = cnt_led + 1;
                    end
                end
            end

            STATE_DEBUG : begin
                next_led = 16'b0100_0000_0000_0000;
            end
        endcase
    end
endmodule
//////////////////////////////////////////////////////////////////////////////////////////////////////////////
// hard : 2-d array cant be the port to a module
////
module my_pixel_gen(
    input rst,
    input clk,
    input [2:0] state,
    input [9:0] h_cnt,
    input valid,
    output reg [3:0] vgaRed,
    output reg [3:0] vgaGreen,
    output reg [3:0] vgaBlue,
    input [9:0] v_cnt,
    input been_ready,            // keyboard three king 
    input [511:0] key_down,
    input [8:0] last_change,
    output reg [3:0] mine_number,
    output reg [3:0] random_x,
    output reg [3:0] random_y
    );

    // mine number
    reg [3:0] next_mine_number;
    parameter STATE_IDLE    = 3'b000;
    parameter STATE_NORMAL   = 3'b001;
    parameter STATE_SAND = 3'b010;
    parameter STATE_WIN  = 3'b011;
    parameter STATE_LOSE  = 3'b100;
    parameter STATE_DEBUG = 3'b101;

    integer i;
    integer j ;
    parameter [8:0] LEFT_SHIFT_CODES  = 9'b0_0001_0010;
	parameter [8:0] RIGHT_SHIFT_CODES = 9'b0_0101_1001;
	wire shift_down;
    assign shift_down = (key_down[LEFT_SHIFT_CODES] == 1'b1 || key_down[RIGHT_SHIFT_CODES] == 1'b1) ? 1'b1 : 1'b0;

	reg [4:0] key_num_x, key_num_y;
    parameter [8:0] KEY_CODES [0:31] = {
		9'b0_0001_0110,	// 1 => 16
		9'b0_0001_1110,	// 2 => 1E
		9'b0_0010_0110,	// 3 => 26
		9'b0_0010_0101,	// 4 => 25
        9'b0_0010_1110,	// 5 => 2E
        9'b0_0011_0110,	// 6 => 36
        9'b0_0011_1101,	// 7 => 3D
        9'b0_0011_1110,	// 8 => 3E

		9'b0_0001_0101, // Q => 15
        9'b0_0001_1101, // W => 1D
        9'b0_0010_0100, // E => 24
        9'b0_0010_1101, // R => 2D
        9'b0_0010_1100,	// T => 2C
        9'b0_0011_0101,	// Y => 35
        9'b0_0011_1100,	// U => 3C
        9'b0_0100_0011,	// I => 43

        9'b0_0001_1100, // A => 1C
        9'b0_0001_1011, // S => 1B
        9'b0_0010_0011, // D => 23
        9'b0_0010_1011, // F => 2B
        9'b0_0011_0100, // G => 34
        9'b0_0011_0011, // H => 33
        9'b0_0011_1011, // J => 3B
        9'b0_0100_0010, // K => 42

        9'b0_0001_1010, // Z => 1A
        9'b0_0010_0010, // X => 22
        9'b0_0010_0001, // C => 21
        9'b0_0010_1010, // V => 2A
        9'b0_0011_0010, // B => 32
        9'b0_0011_0001, // N => 31
        9'b0_0011_1010, // M => 3A
        9'b0_0100_0001  // , => 41
	};

    always @ (*) begin
		case (last_change)
			KEY_CODES[00] : begin
                key_num_x = 4'd0;
                key_num_y = 4'd0;
            end
			KEY_CODES[01] : begin
                key_num_x = 4'd1;
                key_num_y = 4'd0;
            end
			KEY_CODES[02] : begin
                key_num_x = 4'd2;
                key_num_y = 4'd0;
            end
			KEY_CODES[03] : begin
                key_num_x = 4'd3;
                key_num_y = 4'd0;
            end
			KEY_CODES[04] : begin
                key_num_x = 4'd4;
                key_num_y = 4'd0;
            end
			KEY_CODES[05] : begin
                key_num_x = 4'd5;
                key_num_y = 4'd0;
            end
			KEY_CODES[06] : begin
                key_num_x = 4'd6;
                key_num_y = 4'd0;
            end
			KEY_CODES[07] : begin
                key_num_x = 4'd7;
                key_num_y = 4'd0;
            end
			KEY_CODES[08] : begin
                key_num_x = 4'd0;
                key_num_y = 4'd1;
            end
			KEY_CODES[09] : begin
                key_num_x = 4'd1;
                key_num_y = 4'd1;
            end
			KEY_CODES[10] : begin
                key_num_x = 4'd2;
                key_num_y = 4'd1;
            end
			KEY_CODES[11] : begin
                key_num_x = 4'd3;
                key_num_y = 4'd1;
            end
			KEY_CODES[12] : begin
                key_num_x = 4'd4;
                key_num_y = 4'd1;
            end
			KEY_CODES[13] : begin
                key_num_x = 4'd5;
                key_num_y = 4'd1;
            end
			KEY_CODES[14] : begin
                key_num_x = 4'd6;
                key_num_y = 4'd1;
            end
			KEY_CODES[15] : begin
                key_num_x = 4'd7;
                key_num_y = 4'd1;
            end
			KEY_CODES[16] : begin
                key_num_x = 4'd0;
                key_num_y = 4'd2;
            end
			KEY_CODES[17] : begin
                key_num_x = 4'd1;
                key_num_y = 4'd2;
            end
			KEY_CODES[18] : begin
                key_num_x = 4'd2;
                key_num_y = 4'd2;
            end
			KEY_CODES[19] : begin
                key_num_x = 4'd3;
                key_num_y = 4'd2;
            end
			KEY_CODES[20] : begin
                key_num_x = 4'd4;
                key_num_y = 4'd2;
            end
			KEY_CODES[21] : begin
                key_num_x = 4'd5;
                key_num_y = 4'd2;
            end
			KEY_CODES[22] : begin
                key_num_x = 4'd6;
                key_num_y = 4'd2;
            end
			KEY_CODES[23] : begin
                key_num_x = 4'd7;
                key_num_y = 4'd2;
            end
			KEY_CODES[24] : begin
                key_num_x = 4'd0;
                key_num_y = 4'd3;
            end
			KEY_CODES[25] : begin
                key_num_x = 4'd1;
                key_num_y = 4'd3;
            end
			KEY_CODES[26] : begin
                key_num_x = 4'd2;
                key_num_y = 4'd3;
            end
			KEY_CODES[27] : begin
                key_num_x = 4'd3;
                key_num_y = 4'd3;
            end
			KEY_CODES[28] : begin
                key_num_x = 4'd4;
                key_num_y = 4'd3;
            end
			KEY_CODES[29] : begin
                key_num_x = 4'd5;
                key_num_y = 4'd3;
            end
			KEY_CODES[30] : begin
                key_num_x = 4'd6;
                key_num_y = 4'd3;
            end
			KEY_CODES[31] : begin
                key_num_x = 4'd7;
                key_num_y = 4'd3;
            end
			default		  : begin
                key_num_x = 5'd31;
                key_num_y = 5'd31;
            end
		endcase
	end


    // hard: how to determine the number nearby the mine
    // default map
///////////////////////////////////////////////////////////////////////////////////////////////////////////
    // LFSR
    reg [3:0] def_map [0:3][0:7];
    reg [3:0] next_def_map [0:3][0:7];
    reg [15:0] lfsr = 16'b0000_0000_0000_0000;
    reg [1:0] random_posx[9:0];
    reg [2:0] random_posy[9:0];
    integer mines_placed = 0;

    // updata LFSR
    always @(posedge clk or posedge rst) begin
        if (rst)
            lfsr <= 16'b0000_0000_0000_0000;
        else
            lfsr <= lfsr + 1; 
    end


    always @(posedge clk or posedge rst) begin
        if (rst) begin
            for (i = 0; i < 8; i=i+1) begin
                for (j = 0; j < 4; j=j+1) begin
                    def_map[j][i] <= 0;
                end
            end
            mines_placed <= 0;
        end 
        else begin
            for (i = 0; i < 8; i=i+1) begin
                for (j = 0; j < 4; j=j+1) begin
                    def_map[j][i] <= next_def_map[j][i];
                end
            end
            if (mines_placed == 0) begin
                //random
                for(i = 0 ; i<10 ; i=i+1)begin
                    random_posx[i] <= (5*lfsr[i]+4*lfsr[i+1]+3*lfsr[i+2]+2*lfsr[i+3]+lfsr[i+3])%8;
                    random_posy[i] <= (lfsr[i]+2*lfsr[i+1]+3*lfsr[i+2]+4*lfsr[i+3]+5*lfsr[i+3])%4;
                    if (def_map[random_posy[i]][random_posx[i]] == 4'd8) begin
                        def_map[random_posy[i]][random_posx[i]] <= 4'd6;
                    end
                end
                mines_placed <= 10;
            end
        end
    end
    ////////////////////////////////////////////////////////////////////////////////////////
    always@(*)begin
        for (i = 0; i < 8; i=i+1) begin
            for (j = 0; j < 4; j=j+1) begin
                next_def_map[j][i] = def_map[j][i];
            end
        end
        for(i = 0; i < 8; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                if(def_map[j][i] == 4'd6) begin
                    if(i>0 && j>0 && def_map[j-1][i-1] < 4'd5) begin    //1
                        next_def_map[j-1][i-1] = def_map[j-1][i-1] + 1;
                    end
                    if(j>0 && def_map[j-1][i] < 4'd5) begin             //2
                        next_def_map[j-1][i] = def_map[j-1][i] + 1;
                    end
                    if(i<7 && j>0 && def_map[j-1][i+1] < 4'd5) begin    //3 
                        next_def_map[j-1][i+1] = def_map[j-1][i+1] + 1;
                    end
                    if(i>0 && def_map[j][i-1] < 4'd5) begin             //4
                        next_def_map[j][i-1] = def_map[j][i-1] + 1;
                    end
                    if(i<7 && def_map[j][i+1] < 4'd5) begin             //6
                        next_def_map[j][i+1] = def_map[j][i+1] + 1;
                    end
                    if(i>0 && j<3 && def_map[j+1][i-1] < 4'd5) begin    //7
                        next_def_map[j+1][i-1] = def_map[j+1][i-1] + 1;
                    end
                    if(j<3 && def_map[j+1][i] < 4'd5) begin             //8
                        next_def_map[j+1][i] = def_map[j+1][i] + 1;
                    end
                    if(i<7 && j<3 && def_map[j+1][i+1] < 4'd5) begin    //9
                        next_def_map[j+1][i+1] = def_map[j+1][i+1] + 1;
                    end
                end
            end
        end
        for(i = 0; i < 8; i = i + 1) begin
            for(j = 0; j < 4; j = j + 1) begin
                if(def_map[j][i] == 4'd0) begin
                    next_def_map[j][i] = 4'd8;
                end
            end
        end
    end
    //////////////////////////////////////////////////////////////////////////////////////////////////////////


    // flip or not management  
    // 0~8 : blank, one, two, three, four, taro, boom, flag, none
    reg [3:0] is_flag_or_flip [0:3][0:7];
    // reg [2:0] next_is_flag_or_flip [0:3][0:7];
    // hard : flip lots of save rigid in the same time

    always @(posedge clk) begin
        case (state)
            STATE_IDLE: begin
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        is_flag_or_flip[j][i] <= 3'd0;
                    end
                end
            end
            STATE_NORMAL: begin
                if (been_ready && key_down[last_change] == 1'b1) begin
                    if(is_flag_or_flip[key_num_y][key_num_x] == 4'd0) begin
                        if(key_num_x != 5'd31 && key_num_y != 5'd31) begin
                            is_flag_or_flip[key_num_y][key_num_x] <= (!shift_down) ? def_map[key_num_y][key_num_x] : ((mine_number > 0) ? 4'd7 : 4'd0);    
                        end
                    end
                    else if(is_flag_or_flip[key_num_y][key_num_x] == 4'd7) begin
                        if(key_num_x != 5'd31 && key_num_y != 5'd31) begin
                            is_flag_or_flip[key_num_y][key_num_x] <= (shift_down == 1'b1) ? 4'd0 : 4'd7;       
                        end
                    end
                end
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        if(is_flag_or_flip[j][i] == 4'd8) begin
                            if(j>0 && (def_map[j-1][i] < 4'd6 || def_map[j-1][i] == 4'd8)) begin             //2
                                is_flag_or_flip[j-1][i] <= def_map[j-1][i];
                            end
                            if(i>0 && (def_map[j][i-1] < 4'd6 || def_map[j][i-1] == 4'd8)) begin             //4
                                is_flag_or_flip[j][i-1] <= def_map[j][i-1];
                            end
                            if(i<7 && (def_map[j][i+1] < 4'd6 || def_map[j][i+1] == 4'd8)) begin             //6
                                is_flag_or_flip[j][i+1] <= def_map[j][i+1];
                            end
                            if(j<3 && (def_map[j+1][i] < 4'd6 || def_map[j+1][i] == 4'd8)) begin             //8
                                is_flag_or_flip[j+1][i] <= def_map[j+1][i];
                            end
                        end
                    end
                end
            end
            STATE_SAND: begin
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        is_flag_or_flip[j][i] <= 3'd0;
                    end
                end
            end
            STATE_WIN: begin
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        is_flag_or_flip[j][i] <= is_flag_or_flip[j][i];
                    end
                end
            end
            STATE_LOSE: begin
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        is_flag_or_flip[j][i] <= is_flag_or_flip[j][i];
                    end
                end
            end
            default: begin
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        is_flag_or_flip[j][i] <= 3'd0;
                    end
                end
            end
        endcase
    end

    //mine_number
    always@(posedge rst or posedge clk)begin
        if(rst)begin
            mine_number <= 10; //initial
        end
        else begin
            mine_number <= next_mine_number;
        end
    end
    always@(*)begin
        case (state)
            STATE_IDLE: next_mine_number = 10;
            STATE_NORMAL: begin
                next_mine_number = 10;
                for(i = 0; i < 8; i = i + 1) begin
                    for(j = 0; j < 4; j = j + 1) begin
                        if(is_flag_or_flip[j][i] == 4'd7) begin
                            next_mine_number = next_mine_number - 4'd1;
                        end
                    end
                end

            end
            STATE_SAND: next_mine_number = mine_number;
            STATE_WIN: next_mine_number = mine_number;
            STATE_LOSE: next_mine_number = mine_number;
            STATE_DEBUG: next_mine_number = mine_number;
            default: next_mine_number = mine_number;
        endcase
        //////////////////////////////////////////
        //here
        //////////////////////////////////////////
    end


// blank one two three boom flag
// hard : how to initialize 2d param array
// !!!! all the tiny pic data;
    parameter [11:0] picture [0:1349] = {
        //0:blank
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        //1: one
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h3AE, //color
        12'h3AE, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h3AE, //color
        12'hEEE,
        12'h3AE, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h3AE, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h3AE, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h3AE, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h3AE, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h3AE, //color
        12'h3AE, //color
        12'h3AE, //color
        12'h3AE, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        //2: two
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h5F6, //color
        12'h5F6, //color
        12'h5F6, //color
        12'h5F6, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h5F6, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h5F6, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h5F6, //color
        12'h5F6, //color
        12'h5F6, //color
        12'h5F6, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h5F6, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h5F6, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h5F6, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h5F6, //color
        12'h5F6, //color
        12'h5F6, //color
        12'h5F6, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        //3: three
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hE7A, //color
        12'hE7A, //color
        12'hE7A, //color
        12'hE7A, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hE7A, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hE7A, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hE7A, //color
        12'hE7A, //color
        12'hE7A, //color
        12'hE7A, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hE7A, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hE7A, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hE7A, //color
        12'hE7A, //color
        12'hE7A, //color
        12'hE7A, //color
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        //4: four
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h22A, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h22A, //color
        12'h22A, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'h22A, //color
        12'h22A, //color
        12'hEEE,
        12'h22A, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'h22A, //color
        12'hEEE,
        12'hEEE,
        12'h22A, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'h22A, //color
        12'h22A, //color
        12'h22A, //color
        12'h22A, //color
        12'h22A, //color
        12'h22A, //color
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h22A, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h22A, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h22A, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h22A, //color
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        //5: taro
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h3D8, //coler
        12'hEEE,
        12'hEEE,
        12'h3D8, //coler
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'h3D8, //coler
        12'h3D8, //coler
        12'h3D8, //coler
        12'h3D8, //coler
        12'h3D8, //coler
        12'h3D8, //coler
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h3D8, //coler
        12'hEEE,
        12'hEEE,
        12'h3D8, //coler
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'h3D8, //coler
        12'h3D8, //coler
        12'h3D8, //coler
        12'h3D8, //coler
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h3D8, //coler
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'h3D8, //coler
        12'h3D8, //coler
        12'h3D8, //coler
        12'h3D8, //coler
        12'h3D8, //coler
        12'h3D8, //coler
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h3D8, //coler
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h3D8, //coler
        12'h3D8, //coler
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        //6: boom
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h000,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h000,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h000,
        12'h000,
        12'h000,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'hEEE,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h999,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h999,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'hEEE,
        12'h000,
        12'h000,
        12'h000,
        12'h000,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h000,
        12'h000,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        //7: flag
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h000, //color
        12'hF00, //color
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h000, //color
        12'hF00, //color
        12'hF00, //color
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h000, //color
        12'hF00, //color
        12'hF00, //color
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h000, //color
        12'hF00, //color
        12'hF00, //color
        12'hF00, //color
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h000, //color
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h000, //color
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h000, //color
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h000, //color
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'h000, //color
        12'h000, //color
        12'h000, //color
        12'h000, //color
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'h000, //color
        12'h000, //color
        12'h000, //color
        12'h000, //color
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'hAAB,
        12'h889,
        12'h889,//
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        //8: none
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'hEEE,
        12'h889,
        12'h889,//
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889,
        12'h889
    };

always @(*) begin
    if(!valid)
        {vgaRed, vgaGreen, vgaBlue} = 12'h0;
    else 
        {vgaRed, vgaGreen, vgaBlue} = picture[(is_flag_or_flip[v_cnt/120][h_cnt/80])*150 + ((v_cnt%120)>>3)*10 + ((h_cnt%80)>>3)];
end

endmodule

module KeyboardDecoder(
	output reg [511:0] key_down,
	output wire [8:0] last_change,
	output reg key_valid,
	inout wire PS2_DATA,
	inout wire PS2_CLK,
	input wire rst,
	input wire clk
    );
    
    parameter [1:0] INIT			= 2'b00;
    parameter [1:0] WAIT_FOR_SIGNAL = 2'b01;
    parameter [1:0] GET_SIGNAL_DOWN = 2'b10;
    parameter [1:0] WAIT_RELEASE    = 2'b11;
    
	parameter [7:0] IS_INIT			= 8'hAA;
    parameter [7:0] IS_EXTEND		= 8'hE0;
    parameter [7:0] IS_BREAK		= 8'hF0;
    
    reg [9:0] key;		// key = {been_extend, been_break, key_in}
    reg [1:0] state;
    reg been_ready, been_extend, been_break;
    
    wire [7:0] key_in;
    wire is_extend;
    wire is_break;
    wire valid;
    wire err;
    
    wire [511:0] key_decode = 1 << last_change;
    assign last_change = {key[9], key[7:0]};
    
    KeyboardCtrl_0 inst (
		.key_in(key_in),
		.is_extend(is_extend),
		.is_break(is_break),
		.valid(valid),
		.err(err),
		.PS2_DATA(PS2_DATA),
		.PS2_CLK(PS2_CLK),
		.rst(rst),
		.clk(clk)
	);
	
	one_pulse op (
		.pb_out(pulse_been_ready),
		.pb_in(been_ready),
		.clk(clk)
	);
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		state <= INIT;
    		been_ready  <= 1'b0;
    		been_extend <= 1'b0;
    		been_break  <= 1'b0;
    		key <= 10'b0_0_0000_0000;
    	end else begin
    		state <= state;
			been_ready  <= been_ready;
			been_extend <= (is_extend) ? 1'b1 : been_extend;
			been_break  <= (is_break ) ? 1'b1 : been_break;
			key <= key;
    		case (state)
    			INIT : begin
    					if (key_in == IS_INIT) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready  <= 1'b0;
							been_extend <= 1'b0;
							been_break  <= 1'b0;
							key <= 10'b0_0_0000_0000;
    					end else begin
    						state <= INIT;
    					end
    				end
    			WAIT_FOR_SIGNAL : begin
    					if (valid == 0) begin
    						state <= WAIT_FOR_SIGNAL;
    						been_ready <= 1'b0;
    					end else begin
    						state <= GET_SIGNAL_DOWN;
    					end
    				end
    			GET_SIGNAL_DOWN : begin
						state <= WAIT_RELEASE;
						key <= {been_extend, been_break, key_in};
						been_ready  <= 1'b1;
    				end
    			WAIT_RELEASE : begin
    					if (valid == 1) begin
    						state <= WAIT_RELEASE;
    					end else begin
    						state <= WAIT_FOR_SIGNAL;
    						been_extend <= 1'b0;
    						been_break  <= 1'b0;
    					end
    				end
    			default : begin
    					state <= INIT;
						been_ready  <= 1'b0;
						been_extend <= 1'b0;
						been_break  <= 1'b0;
						key <= 10'b0_0_0000_0000;
    				end
    		endcase
    	end
    end
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		key_valid <= 1'b0;
    		key_down <= 511'b0;
    	end else if (key_decode[last_change] && pulse_been_ready) begin
    		key_valid <= 1'b1;
    		if (key[8] == 0) begin
    			key_down <= key_down | key_decode;
    		end else begin
    			key_down <= key_down & (~key_decode);
    		end
    	end else begin
    		key_valid <= 1'b0;
			key_down <= key_down;
    	end
    end

endmodule

module vga_controller (
    input wire pclk, reset,
    output wire hsync, vsync, valid,
    output wire [9:0]h_cnt,
    output wire [9:0]v_cnt
    );

    reg [9:0]pixel_cnt;
    reg [9:0]line_cnt;
    reg hsync_i,vsync_i;

    parameter HD = 640;
    parameter HF = 16;
    parameter HS = 96;
    parameter HB = 48;
    parameter HT = 800; 
    parameter VD = 480;
    parameter VF = 10;
    parameter VS = 2;
    parameter VB = 33;
    parameter VT = 525;
    parameter hsync_default = 1'b1;
    parameter vsync_default = 1'b1;

    always @(posedge pclk)
        if (reset)
            pixel_cnt <= 0;
        else
            if (pixel_cnt < (HT - 1))
                pixel_cnt <= pixel_cnt + 1;
            else
                pixel_cnt <= 0;

    always @(posedge pclk)
        if (reset)
            hsync_i <= hsync_default;
        else
            if ((pixel_cnt >= (HD + HF - 1)) && (pixel_cnt < (HD + HF + HS - 1)))
                hsync_i <= ~hsync_default;
            else
                hsync_i <= hsync_default; 

    always @(posedge pclk)
        if (reset)
            line_cnt <= 0;
        else
            if (pixel_cnt == (HT -1))
                if (line_cnt < (VT - 1))
                    line_cnt <= line_cnt + 1;
                else
                    line_cnt <= 0;

    always @(posedge pclk)
        if (reset)
            vsync_i <= vsync_default; 
        else if ((line_cnt >= (VD + VF - 1)) && (line_cnt < (VD + VF + VS - 1)))
            vsync_i <= ~vsync_default; 
        else
            vsync_i <= vsync_default; 

    assign hsync = hsync_i;
    assign vsync = vsync_i;
    assign valid = ((pixel_cnt < HD) && (line_cnt < VD));

    assign h_cnt = (pixel_cnt < HD) ? pixel_cnt : 10'd0;
    assign v_cnt = (line_cnt < VD) ? line_cnt : 10'd0;

endmodule

module SevenSegment(
	output reg [6:0] display,
	output reg [3:0] digit,
	input wire [15:0] nums,
	input wire rst,
	input wire clk
    );
    
    reg [15:0] clk_divider;
    reg [3:0] display_num;
    
    always @ (posedge clk, posedge rst) begin
    	if (rst) begin
    		clk_divider <= 15'b0;
    	end else begin
    		clk_divider <= clk_divider + 15'b1;
    	end
    end
    
    always @ (posedge clk_divider[15], posedge rst) begin
    	if (rst) begin
    		display_num <= 4'b0000;
    		digit <= 4'b1111;
    	end else begin
    		case (digit)
    			4'b1110 : begin
    					display_num <= nums[7:4];
    					digit <= 4'b1101;
    				end
    			4'b1101 : begin
						display_num <= nums[11:8];
						digit <= 4'b1011;
					end
    			4'b1011 : begin
						display_num <= nums[15:12];
						digit <= 4'b0111;
					end
    			4'b0111 : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end
    			default : begin
						display_num <= nums[3:0];
						digit <= 4'b1110;
					end				
    		endcase
    	end
    end
    
    always @ (*) begin
    	case (display_num)
    		0 : display = 7'b100_0000;
			1 : display = 7'b111_1001;                                                  
			2 : display = 7'b010_0100;                                                  
			3 : display = 7'b011_0000;                                               
			4 : display = 7'b001_1001;                                                 
			5 : display = 7'b001_0010;                                                 
			6 : display = 7'b000_0010;  
			7 : display = 7'b111_1000;  
			8 : display = 7'b000_0000;  
			9 : display = 7'b001_0000;
			10: display = 7'b011_1111;  //DASH 
            11: display = 7'b111_1111;  //NONE 
			13: display = 7'b000_0110;  //E
            14: display = 7'b000_1000;  //A
			15: display = 7'b000_1110;  //F  
			default : display = 7'b1111111;
    	endcase
    end
    
endmodule

module debounce (
	input wire clk,
	input wire pb, 
	output wire pb_debounced 
    );
	reg [3:0] shift_reg; 

	always @(posedge clk) begin
		shift_reg[3:1] <= shift_reg[2:0];
		shift_reg[0] <= pb;
	end

	assign pb_debounced = ((shift_reg == 4'b1111) ? 1'b1 : 1'b0);

endmodule

module one_pulse (
    input wire clk,
    input wire pb_in,
    output reg pb_out
    );

	reg pb_in_delay;

	always @(posedge clk) begin
		if (pb_in == 1'b1 && pb_in_delay == 1'b0) begin
			pb_out <= 1'b1;
		end else begin
			pb_out <= 1'b0;
		end
	end
	
	always @(posedge clk) begin
		pb_in_delay <= pb_in;
	end
endmodule

module clock_divider #(parameter n = 24)
    (input clk,
    output clk_div
    );

    reg[n-1:0]num;
    wire[n-1:0]next_num;
    always@(posedge clk)begin
        num <= next_num;
    end
    assign next_num = num + 1;
    assign clk_div = num[n-1];
endmodule

module my_clock_divider #(parameter DIV = 28'd0)
    (
    input clk,
    output reg clk_div
    );
    // 2^28 ~ 10^8
    reg [28:0] counter = 28'd0;
    always @(posedge clk) begin
        counter <= counter + 1;
        if(counter >= DIV - 1) counter <= 28'd0;
        clk_div <= (counter < DIV / 2) ? 1'b1 : 1'b0;
    end
endmodule

module clock_divider_25M(clk1, clk);
    input clk;
    output clk1;

    reg [1:0] num;
    wire [1:0] next_num;

    always @(posedge clk) begin
        num <= next_num;
    end

    assign next_num = num + 1'b1;
    assign clk1 = num[1];

endmodule
