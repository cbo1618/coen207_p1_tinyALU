module tinyalu(
	// Port declarations
	input wire [7:0] A,
	input wire [7:0] B,
	input wire clk,
	input wire [2:0] op,
	input wire reset_n,
	input wire start,
	output reg done,
	output reg [15:0] result
);

	// Internal signals
	reg done_aax;
	reg done_mult;
	reg [15:0] result_aax;
	reg [15:0] result_mult;
	reg start_single;
	reg start_mult;
	reg done_internal;

	// Internal modules	
	single_cycle add_and_xor(
		.A				(A				),
		.B				(B				),
		.clk			(clk			),
		.op				(op				),
		.reset_n		(reset_n		),
		.start			(start_single	),
		.done_aax		(done_aax		),
		.result_aax		(result_aax		)
	);
	three_cycle mult(
		.A				(A				),
		.B				(B				),
		.clk			(clk			),
		.reset_n		(reset_n		),
		.start			(start_mult		),
		.done_mult		(done_mult		),
		.result_mult	(result_mult	)
	);
	/*
	// start_mux
	assign start_single = (op[2] == 1'b0) ? start : (op[2] == 1'b1) ? 1'b0 : 1'bx;
	assign start_mult = (op[2] == 1'b0) ? 1'b0 : (op[2] == 1'b1) ? start : 1'bx;

	// result_mux
	assign result = (op[2] == 1'b0) ? result_aax : (op[2] == 1'b1) ? result_mult : 1'bx;

	// done_mux
	assign done_internal = (op[2] == 1'b0) ? done_aax : (op[2] == 1'b1) ? done_mult : 1'bx;
	*/
	assign start_single = (op[2] == 1'b0) ? start : (op == 3'b100) ? 1'b0 : 1'bx;
	assign start_mult = (op[2] == 1'b0) ? 1'b0 : (op == 3'b100) ? start : 1'bx;

	// result_mux
	assign result = (op[2] == 1'b0) ? result_aax : (op == 3'b100) ? result_mult : 1'bx;

	// done_mux
	assign done_internal = (op[2] == 1'b0) ? done_aax : (op == 3'b100) ? done_mult : 1'bx;

	assign done = done_internal;
endmodule
