module single_cycle(
	// Port declarations
	input wire [7:0] A,
	input wire [7:0] B,
	input wire clk,
	input wire [2:0] op,
	input wire reset_n,
	input wire start,
	output reg done_aax,
	output reg [15:0] result_aax
	);

	// Internal signals
	reg [7:0] a_int;
	reg [7:0] b_int;
	reg [15:0] mul_int1;
	reg [15:0] mul_int2;
	reg done_aax_int;
	
	// ALU OP Codes
	parameter OP_ADD  = 3'b001;
	parameter OP_AND  = 3'b010;
	parameter OP_XOR = 3'b011;
		
	always @(posedge clk) begin
		// Synchronous reset
		if(!reset_n) begin
			result_aax <= 16'h0000;
		end
		// ALU Operation
		else if (start) begin
			case(op)
				OP_ADD: result_aax <= A + B;
				OP_AND: result_aax <= A & B;
				OP_XOR: result_aax <= A ^ B;
				default: result_aax <= 16'h0000; // null
			endcase
		end
	end

	// Set done signal
	always @(posedge clk or !reset_n) begin
		if(!reset_n) begin
			done_aax_int <= 1'b0;
		end
		else begin
			if ((start) && (op != 3'b000)) done_aax_int <= 1'b1;
			else done_aax_int <= 1'b0;
		end
	end
	assign done_aax = done_aax_int;
endmodule
