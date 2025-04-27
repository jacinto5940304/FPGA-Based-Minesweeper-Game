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