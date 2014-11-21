// Decoded opcode operations	XXXXX: Possibly change to global `define parameters
`define DECODE_ARITH	3'b000	// Arithmetic operation		op: 8'h05:8'h00			oppf: 0		sv: 0
`define DECODE_ILLEGAL	3'b001	// Illegal operation		op: 8'h0B:8'hFF			oppf: 0,1	sv: 0,1
`define DECODE_MEMORY	3'b010	// Memory operation			op: 					oppf: 1		sv: 0
`define DECODE_PRIVATE	3'b011	// Private operation		op: 8'h09:8'h06, 8'h0A	oppf: 1		sv: 1
`define DECODE_PMEMORY	3'b100	// Protected operation		op: 8'h09:8'h06			oppf: 1		sv: 0
`define DECODE_SV		3'b101	// Restricted operation		op: 8'h0A				oppf: 0		sv: 1

module dut (
	// Port declarations
	input wire			clk,
	input wire			reset_n,
	input wire	[31:0]	A,
	input wire	[31:0]	B,
	input wire	[7:0]	op,
	input wire			op_pf,
	input wire			sv,
	input wire			start,
	output reg			done,
	output reg	[63:0]	result,
	output reg	[5:0]	err,
	output bit			gp
);

	// Device internal signals
		// Device FSM signals
	reg [2:0]	icr_dut_fsm;			// Device FSM state
		// Control signals
	reg					ics_en_alu;		// ALU compute enable
	reg					ics_en_wr;		// Memory write enable
	reg					ics_en_rd;		// Memory read enable
	reg			[3:0]	ics_dec_op;		// Decoded opcode
	reg					ics_en_mem;		// Memory operation enable
		// Data registers
	reg			[63:0]	edr_alu_res;	// Result from ALU operation
	reg			[31:0]	idr_addr_wr;	// Memory write address
	reg			[31:0]	idr_addr_rd;	// Memory read address
	reg			[31:0]	idr_data_wr;	// Memory write
	wire		[31:0]	idr_data_rd;	// Memory read
//	reg 		[31:0]	t_reg_ir;		// XXXXX: Temporary register to hold data in from memory
		// Error signals
	reg 				ees_addr_werr;	// Memory write error
	reg 				ees_addr_rerr;	// Memory read error
	reg 				ies_dut_derr;	// Device decode error
	reg					ees_alu_err;	// ALU opcode error
	reg					ees_dut_memc;	// Memory controller error
	reg					ies_dut_iop;	// Device illegal opcode error
	
	// Internal modules	
		// Device memory controller
	dut_memcont i_mod_memcont(
		.clk			(clk			),	// Clock
		.ecr_mem_op		(op				),	// Memory opcode
		.ecs_en_mem		(ics_en_mem		),	// Memory operation enable
		.ecs_en_wr		(ics_en_wr		),	// Memory write enable
		.ecs_en_rd		(ics_en_rd		),	// Memory read enable
		.ics_memc_err	(ees_dut_memc	)	// Memory controller error
	);
		// Device memory module
	dut_memory i_mod_mem(
		.clk			(clk			),	// Clock
		.ecs_en_wr		(ics_en_wr		),	// Write-enable signal
		.ecs_en_rd		(ics_en_rd		),	// Read-enable signal
		.edr_addr_wr	(idr_addr_wr	),	// Write address
		.edr_addr_rd	(idr_addr_rd	),	// Read address
		.edr_data_wr	(idr_data_wr	),	// Data in (for writing to memory)
		.edr_data_rd	(idr_data_rd	),	// Data out (for reading from memory)
		.ies_addr_werr	(ees_addr_werr	),	// Memory write error signal
		.ies_addr_rerr	(ees_addr_rerr	)	// Memory read error signal
	);
		// Device ALU module
	dut_alu i_mod_alu(
	// Port declarations
		.clk			(clk			),	// Clock
		.reset_n		(reset_n		),	// Reset
		.edr_alu_in0	(A				),	// ALU input operand A
		.edr_alu_in1	(B				),	// ALU input operand B
		.ecs_alu_op		(op				),	// ALU opcode
		.op_pf			(op_pf			),	// XXXXX: Needs implementation
		.ecs_alu_sv		(sv				),	// ALU extra opcode control signal
		.ecs_alu_comp	(ics_en_alu		),	// ALU compute control signal	XXXXX: Probably unnecessary
//		.ics_alu_val	(				),	// ALU result valid signal	XXXXX: Should be handled by device
//		.idr_alu_maddr	(				),	// ALU memory address out register for memory operations	XXXXX: Possibly move to main module
		.idr_alu_res	(edr_alu_res	),	// ALU operation result register	XXXXX: Probably move to temporary register
		.ies_alu_err	(ees_alu_err	)	// ALU error signal; asserted high for one clock cycle when an invalid opcode is passed
	);
	
	// Device Controller States
	parameter FSM_DUT_IDLE		= 3'b000;	// During this state, the device is inactive and awaiting a start signal and inputs to start
	parameter FSM_DUT_DECODE	= 3'b010;	// During this state, the device decodes the opcode to determine the function the device is to perform
	parameter FSM_DUT_COMPUTE	= 3'b011;	// During this state, the device carries out the function determined in the previous state
	parameter FSM_DUT_SIG		= 3'b100;	// During this state, disable control lines
	parameter FSM_DUT_DONE		= 3'b101;	// During this state, all computations are finished

	// Device control FSM
	always @(posedge clk)
		if (!reset_n) begin
			icr_dut_fsm	<= FSM_DUT_IDLE;
			// Clear control signals and data
			ics_en_mem	<= 1'b0;
			ics_en_alu	<= 1'b0;
			ics_dec_op	<= 4'h0;
			// Clear errors
			ies_dut_derr <= 1'b0;
			ies_dut_iop <= 1'b0;
		end
		else
			case (icr_dut_fsm)
				FSM_DUT_IDLE: begin	// Idle state
//					ics_dec_op <= 4'h0;
					if (start) begin
						icr_dut_fsm <= FSM_DUT_DECODE;
					end
				end
				FSM_DUT_DECODE: begin
					dut_decode(op, op_pf, sv, ics_dec_op);
					idr_addr_wr <= A;	// Prepare for memory access
					idr_data_wr <= B;
					idr_addr_rd <= A;
					icr_dut_fsm <= FSM_DUT_DECODE;
				end
				FSM_DUT_COMPUTE: begin
					case (ics_dec_op)
						`DECODE_ARITH:		ics_en_alu <= 1'b1;
						`DECODE_ILLEGAL:	ies_dut_iop <= 1'b1;
						`DECODE_MEMORY:		ics_en_mem <= 1'b1;
						`DECODE_PRIVATE:	ics_en_alu <= 1'b1;
						`DECODE_PMEMORY:	ics_en_mem <= 1'b1;
						`DECODE_SV:			result <= 64'h00000000DEADBEEF;	// XXXXX: Operation for special opcode flag needs to be added here
						default: ies_dut_derr <= 1;	// Signal indicates an error in decoding the opcode
					endcase
					icr_dut_fsm <= FSM_DUT_SIG;
				end
				FSM_DUT_SIG: begin
					ics_en_alu <= 1'b0;
					ics_en_mem <= 1'b0;
					icr_dut_fsm <= FSM_DUT_DONE;
				end
				FSM_DUT_DONE: begin
					icr_dut_fsm <= FSM_DUT_IDLE;

				end
				default: begin
					icr_dut_fsm <= FSM_DUT_IDLE;	// Reset to idle state if FSM enters an invalid state
				end
			endcase
	
	// Assign outgoing control and error signals
	assign done = (icr_dut_fsm == FSM_DUT_DONE);
	assign gp = (ees_addr_werr | ees_addr_rerr | ies_dut_derr | ees_alu_err | ees_dut_memc | ies_dut_iop);
	assign err[5] = ees_addr_werr;
	assign err[4] = ees_addr_rerr;
	assign err[3] = ies_dut_derr;
	assign err[2] = ees_alu_err;
	assign err[1] = ees_dut_memc;
	assign err[0] = ies_dut_iop;
	
	/*	Task decodes the incoming opcode
		Six possible states, including the default: illegal
	*/
	task dut_decode (
		input		[7:0]	ecr_alu_op,		// ALU opcode
		input				ecs_alu_oppf,	// ALU opcode prefix
		input				ecs_alu_sv,		// ALU restricted operating mode
		output reg	[3:0]	icr_dut_dop		// Device decoded opcode
	);

		if (ecs_alu_sv) 
			if (ecs_alu_oppf)
				if ((ecr_alu_op >= 8'h06 && ecr_alu_op <= 8'h09) || ecr_alu_op == 8'h0A) icr_dut_dop <= `DECODE_PRIVATE;
				else icr_dut_dop <= `DECODE_ILLEGAL;
			else
				if (ecr_alu_op == 8'h0A) icr_dut_dop <= `DECODE_SV;
				else icr_dut_dop <= `DECODE_ILLEGAL;
		else
			if (ecs_alu_oppf)
				if (ecr_alu_op <= 8'h05) icr_dut_dop <= `DECODE_MEMORY;
				else if (ecr_alu_op >= 8'h06 && ecr_alu_op <= 8'h09) icr_dut_dop <= `DECODE_PMEMORY;
				else icr_dut_dop <= `DECODE_ILLEGAL;
			else
				if (ecr_alu_op <= 8'h05) icr_dut_dop <= `DECODE_ARITH;
				else icr_dut_dop <= `DECODE_ILLEGAL;
	endtask
endmodule

/*	ALU module with single cycle operation
	Opcode is limited to 8'h05:8'h00
	Error signal asserted high on input of illegal opcode
*/
module dut_alu (
	// Port declarations
	input wire			clk,			// Clock
	input wire			reset_n,		// Reset
	input wire	[31:0]	edr_alu_in0,	// ALU input operand A
	input wire	[31:0]	edr_alu_in1,	// ALU input operand B
	input wire	[7:0]	ecs_alu_op,		// ALU opcode
	input wire			op_pf,			// XXXXX: Needs implementation
	input wire			ecs_alu_sv,		// ALU extra opcode control signal
	input wire			ecs_alu_comp,	// ALU compute control signal	XXXXX: Probably unnecessary
//	output reg			ics_alu_val,	// ALU result valid signal	XXXXX: Should be handled by device
//	output reg			idr_alu_maddr,	// ALU memory address out register for memory operations	XXXXX: Possibly move to main module
	output reg	[63:0]	idr_alu_res,	// ALU operation result register
	output reg			ies_alu_err		// ALU error signal; asserted high for one clock cycle when an invalid opcode is passed
);

	// ALU Operation Codes
		// Arithmetic and Logical Operations
	parameter OP_ALU_ADD	= 8'h00;	// Arithmetic Addition
	parameter OP_ALU_SUB	= 8'h01;	// Arithmetic Subtraction
	parameter OP_ALU_MUL	= 8'h02;	// Arithmetic Multiplication
	parameter OP_ALU_AND	= 8'h03;	// Logical And
	parameter OP_ALU_OR		= 8'h04;	// Logical Or
	parameter OP_ALU_XOR	= 8'h05;	// Logical Xor
//	parameter OP_ALU_NOT	= 8'h0;		// Logical Not
//	parameter OP_ALU_DIV	= 8'h0;		// Arithmetic Division
//	parameter OP_ALU_MOD	= 8'h0;		// Arithmetic Modulus
//	parameter OP_ALU_NOR	= 8'h0;		// Logical Nor
//	parameter OP_ALU_NAND	= 8'h0;		// Logical Nand
//	parameter OP_ALU_XNOR	= 8'h0;		// Logical Xnor
//	parameter OP_ALU_LSHIFT	= 8'h0;		// Logical Left Shift
//	parameter OP_ALU_RSHIFT	= 8'h0;		// Logical Right Shift
		// Comparison Operations
//	parameter OP_ALU_EQUAL	= 8'h0;		// Boolean Equal
//	parameter OP_ALU_LT		= 8'h0;		// Boolean Less Than
//	parameter OP_ALU_GT		= 8'h0;		// Boolean Greater Than
//	parameter OP_ALU_LTE	= 8'h0;		// Boolean Less Than Or Equal
//	parameter OP_ALU_GTE	= 8'h0;		// Boolean Greater Than Or Equal
		// Memory Operations XXXXX: Possibly move to DUT control rather than ALU
//	parameter OP_ALU_STORE	= 8'h0;		// Store data in operand B in memory location A
//	parameter OP_ALU_LOAD	= 8'h0;		// Load data in memory location A
		// Control Operations
//	parameter OP_ALU_NULL	= 8'h0;		// No operation
//	parameter OP_ALU_ERROR	= 8'h0;		// Invalid opcode

	always @(posedge clk) begin
		if (!reset_n) begin
			idr_alu_res <= 64'h0000000000000000;
			ies_alu_err <= 1'b0;
		end
		else if (ecs_alu_comp == 1'b1) begin
			ies_alu_err <= 1'b0;
			case(ecs_alu_op)
				OP_ALU_ADD:		idr_alu_res <= edr_alu_in0 + edr_alu_in1;
				OP_ALU_SUB:		idr_alu_res <= edr_alu_in0 - edr_alu_in1;
				OP_ALU_MUL:		idr_alu_res <= edr_alu_in0 * edr_alu_in1;
				OP_ALU_AND:		idr_alu_res <= edr_alu_in0 & edr_alu_in1;
				OP_ALU_OR:		idr_alu_res <= edr_alu_in0 | edr_alu_in1;
				OP_ALU_XOR:		idr_alu_res <= edr_alu_in0 ^ edr_alu_in1;
/*				OP_ALU_NOT:		idr_alu_res <= ~edr_alu_in0;
				OP_ALU_DIV:		idr_alu_res <= edr_alu_in0 / edr_alu_in1;
				OP_ALU_MOD:		idr_alu_res <= edr_alu_in0 % edr_alu_in1;
				OP_ALU_NOR:		idr_alu_res <= edr_alu_in0 ~| edr_alu_in1;
				OP_ALU_NAND:	idr_alu_res <= edr_alu_in0 ~& edr_alu_in1;
				OP_ALU_XNOR:	idr_alu_res <= edr_alu_in0 ~^ edr_alu_in1;
				OP_ALU_LSHIFT:	idr_alu_res <= edr_alu_in0 << edr_alu_in1;
				OP_ALU_RSHIFT:	idr_alu_res <= edr_alu_in0 >> edr_alu_in1;
				OP_ALU_EQUAL:	if (edr_alu_in0 == edr_alu_in1)	idr_alu_res <= 1;
								else							idr_alu_res <= 0;
				OP_ALU_LT:		if (edr_alu_in0 < edr_alu_in1)	idr_alu_res <= 1;
								else							idr_alu_res <= 0;
				OP_ALU_GT:		if (edr_alu_in0 > edr_alu_in1)	idr_alu_res <= 1;
								else							idr_alu_res <= 0;
				OP_ALU_LTE:		if (edr_alu_in0 <= edr_alu_in1)	idr_alu_res <= 1;
								else							idr_alu_res <= 0;
				OP_ALU_GTE:		if (edr_alu_in0 >= edr_alu_in1)	idr_alu_res <= 1;
								else							idr_alu_res <= 0;
				OP_ALU_STORE:	idr_alu_res <= edr_alu_in0;
				OP_ALU_LOAD:	idr_alu_res <= edr_alu_in0;
				OP_ALU_NULL:	ies_alu_err <= 1'b1;
				OP_ALU_ERROR:	ies_alu_err <= 1'b1;
*/
				default: begin
					idr_alu_res <= 64'hx;
					ies_alu_err <= 1'b1;
				end
			endcase
		end
	end
endmodule

/*	Two-port memory module with dedicated read and write ports.
	Memory size is limited to two bytes: lower section [32'h000000FF:32'h00000000] and upper section [32'hFFFFFFFF:32'hFFFFFF00].
	Error signal asserted high when an illegal memory location is addressed.
	XXXXX: No error for reading from a valid location that has not been previously written yet.
*/
module dut_memory (
	input wire			clk,			// Clock
	input wire			ecs_en_wr,		// Write-enable signal
	input wire			ecs_en_rd,		// Read-enable signal
	input wire	[31:0]	edr_addr_wr,	// Write address
	input wire	[31:0]	edr_addr_rd,	// Read address
	input wire	[31:0]	edr_data_wr,	// Data in; for writing to memory
	output reg	[31:0]	edr_data_rd,	// Data out; for reading from memory
	output reg			ies_addr_werr,	// Memory write error signal
	output reg			ies_addr_rerr	// Memory read error signal
);
	reg			[31:0]	idr_data_memu [1023:0];		// Upper memory block; one byte for address 32'hFFFFFF00 to 32'hFFFFFFFF
	reg			[31:0]	idr_data_meml [1023:0];		// Lower memory block; one byte for address 32'h00000000 to 32'h000000FF
	
	always @(posedge clk) begin
		ies_addr_werr <= 0;
		if (ecs_en_wr)	// Memory write
			if (edr_addr_wr <= 32'h000000FF) idr_data_meml[edr_addr_wr] <= edr_data_wr;
			else if (edr_addr_wr >= 32'hFFFFFF00) idr_data_memu[edr_addr_wr] <= edr_data_wr;
			else ies_addr_werr <= 1;
	end
	always @(posedge clk) begin
		ies_addr_rerr <= 0;
		if (ecs_en_rd)
			if (edr_addr_rd <= 32'h000000FF) edr_data_rd <= idr_data_meml[edr_addr_rd];
			else if (edr_addr_rd >= 32'hFFFFFF00) edr_data_rd <= idr_data_memu[edr_addr_rd];
			else ies_addr_rerr <= 1;
	end
endmodule

/*	Module controls memory enable signals for memory operations
	Two possible states, LOAD:8'h00 and STORE:8'h01
*/
module dut_memcont (
	input wire			clk,			// Clock
	input wire	[7:0]	ecr_mem_op,		// Memory opcode
	input wire			ecs_en_mem,		// Memory operation enable
	output reg			ecs_en_wr,		// Memory write enable
	output reg			ecs_en_rd,		// Memory read enable
	output reg			ics_memc_err	// Memory controller error; asserted on invalid opcode
);
	always @(posedge clk)
		if (ecs_en_mem) begin
			if (ecr_mem_op == 8'h00) begin		// Memory read (load)
				ecs_en_wr <= 0;
				ecs_en_rd <= 1;
			end
			else if (ecr_mem_op == 8'h01) begin	// Memory write (store)
				ecs_en_wr <= 1;
				ecs_en_rd <= 0;
			end
			else begin							// Exception; controller should not reach this state
				ics_memc_err <= 1;
				ecs_en_wr <= 0;
				ecs_en_rd <= 0;
			end
		end
		else begin								// Disable memory operations
			ics_memc_err <= 0;
			ecs_en_wr <= 0;
			ecs_en_rd <= 0;
		end
endmodule


