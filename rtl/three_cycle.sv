module three_cycle(
	// Port declarations
	input wire [7:0] A,
	input wire [7:0] B,
	input wire clk,
	input wire reset_n,
	input wire start,
	output reg done_mult,
	output reg [15:0] result_mult
);
	// Internal signals
	reg [7:0] a_int;
	reg [7:0] b_int;
	reg [15:0] mult1;
	reg [15:0] mult2;
	reg done3;
	reg done2;
	reg done1;
	reg done_mult_int;

	always @(posedge clk or !reset_n) begin
		// Asynchronous reset
		if(!reset_n) begin
			done_mult_int <= 1'b0;
			done3 <= 1'b0;
			done2 <= 1'b0;
			done1 <= 1'b0;
			a_int <= 8'h00;
			b_int <= 8'h00;
			mult1 <= 16'h0000;
			mult2 <= 16'h0000;
			result_mult <= 16'h0000;
		end
		// Three cycle multiply
		else begin
			a_int <= A;
			b_int <= B;
			mult1 <= a_int * b_int;
			mult2 <= mult1;
			result_mult <= mult2;
			done3 <= start && !done_mult_int;
			done2 <= done3 && !done_mult_int;
			done1 <= done2 && !done_mult_int;
			done_mult_int  <= done1 && !done_mult_int;
		end
	end	
	assign done_mult = done_mult_int;
endmodule
