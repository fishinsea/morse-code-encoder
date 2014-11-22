module morse (input [1:0]KEY, input [2:0]SW, input CLOCK_50, output [0:0]LEDR);
	wire [3:0] length; // number of ones represent length of morse code
	wire [3:0] morse; // morse code translation
	wire enable; // enables the clock signal every .5 seconds
	
	letter_select ls (SW[2:0], morse[3:0], length[3:0]);
	clock_enable (CLOCK_50, enable);
	state_mh (KEY[1], KEY[0], morse[3:0], length[3:0], CLOCK_50, enable, LEDR[0]);

endmodule

module state_mh (input start, input stop, input [3:0]morse, input [3:0]length, input clock, input enable, output [0:0]z_out); // leds for debugging

	reg [3:0] len_counter; // copy of length
	reg [2:0] ycurr, ynext; // current and next state of fsm
	reg [3:0] morse_reg; // left-most bit processed each time
	
	// states, a = reset
	//         b = key[1] is pressed
	//         c, d, e = 0.5 second led on each, totalling 1.5sec
	parameter a = 3'b000, b = 3'b001, c = 3'b010, d = 3'b011, e = 3'b100;
	
	// state table
	always @(*) begin
		case (ycurr)
			a: if (!start) 
					ynext = b;
				else
					ynext = a;
					
			b: if (morse_reg[3])
					ynext = c;        // b -> c -> d -> e = 0.5 + 0.5 + 0.5 = 1.5 seconds 'dash'
				else
					ynext = e;        // b -> e = 0.5 seconds 'dot'
				
			c: ynext = d;
			
			d: ynext = e;
			
			e: if (!len_counter[3])
					ynext = a; // done    // end of sequence
				else
					ynext = b;
					
			default: ynext = 3'b000;
			endcase
		end

		always @(posedge clock) begin
			if (enable) begin
				ycurr <= ynext;
				
				if (ynext == a) begin
					len_counter <= length;
					morse_reg <= morse;
				end
				
				if (!stop)
					ycurr <= a;
				else 
					if (ynext == e) begin
					morse_reg[3] <= morse_reg[2];     // moves onto the next value
					morse_reg[2] <= morse_reg[1];
					morse_reg[1] <= morse_reg[0];
					morse_reg[0] <= 1'b0;
					len_counter[3] <= len_counter[2]; // decreases length by one after each pulse
					len_counter[2] <= len_counter[1];
					len_counter[1] <= len_counter[0];
					len_counter[0] <= 1'b0;
				end
			end
		end
		
		
	// assigns outbit
	assign z_out[0] = (ycurr == b) | (ycurr == c) | (ycurr == d); 
		
endmodule

module letter_select (input [2:0] selector, output reg[3:0] morse, output reg[3:0] len);
  // defines dash/dot patterns for letters and the lengths of their sequences
  
	parameter A = 3'b000, B = 3'b001, C = 3'b010, D = 3'b011;
	parameter E = 3'b100, F = 3'b101, G = 3'b110, H = 3'b111;

	always @(selector) begin
		case (selector[2:0])
			A: begin
				morse = 4'b0100;
				len = 4'b1100; 
				end
			B: begin
				morse = 4'b1000;
				len = 4'b1111; 
				end
			C: begin
				morse = 4'b1010;
				len = 4'b1111; 
				end
			D: begin
				morse = 4'b1000;
				len = 4'b1110; 
				end
			E: begin
				morse = 4'b0000;
				len = 4'b1000; 
				end
			F: begin
				morse = 4'b0010;
				len = 4'b1111; 
				end
			G: begin
				morse = 4'b1100;
				len = 4'b1110; 
				end
			H: begin
				morse = 4'b0000;
				len = 4'b1111; 
				end
		endcase
	end
	
endmodule

module clock_enable(input CLOCKin, output reg enable); // convert 50mhz to half-second CLOCK cycles
	reg [24:0]counter;
	
	always @(posedge CLOCKin)
		if (counter ==  25000000) begin
			counter <= 0;
			enable <= 1;
		end
		else begin
			counter <= counter + 1;
			enable <= 0;
		end
endmodule
