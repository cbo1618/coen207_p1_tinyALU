// Decoded opcode operations
`define DECODE_ARITH	3'b000	// Arithmetic operation		op: 8'h05:8'h00			oppf: 0		sv: 0
`define DECODE_ILLEGAL	3'b001	// Illegal operation		op: 8'h0B:8'hFF			oppf: 0,1	sv: 0,1
`define DECODE_MEMORY	3'b010	// Memory operation			op: 8'h01:8'h00			oppf: 1		sv: 0
`define DECODE_PRIVATE	3'b011	// Private operation		op: 8'h09:8'h06			oppf: 1		sv: 1
`define DECODE_PMEMORY	3'b100	// Protected operation		op: 8'h07:8'h06			oppf: 1		sv: 0
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
	output reg	[7:0]	err,
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
	reg			[7:0]	idr_data_OP;	// Register to hold opcode
		// Data registers
	reg			[63:0]	edr_alu_res;	// Result from ALU operation
	reg			[31:0]	idr_addr_wr;	// Memory write address
	reg			[31:0]	idr_addr_rd;	// Memory read address
	reg			[31:0]	idr_data_wr;	// Memory write
	wire		[31:0]	idr_data_rd;	// Memory read
//	reg			[31:0]	idr_addr_
	reg 		[31:0]	idr_data_A;		// Register to hold input A
	reg			[31:0]	idr_data_B;		// Register to hold input B
		// Error signals
	reg 				ees_addr_werr;	// Memory write error
	reg 				ees_addr_rerr;	// Memory read error
	reg 				ies_dut_derr;	// Device decode error
	reg					ees_alu_err;	// ALU opcode error
	reg					ees_dut_memc;	// Memory controller error
	reg					ies_dut_iop;	// Device illegal opcode error
	
	// Internal modules
		// Device opcode decoder
	dut_decode i_mod_decode(
		.clk			(clk			),
		.ecr_alu_op		(op				),	// ALU opcode
		.ecs_alu_oppf	(op_pf			),	// ALU opcode prefix
		.ecs_alu_sv		(sv				),	// ALU restricted operating mode
		.icr_dut_dop	(ics_dec_op		)	// Device decoded opcode
	);
		// Device memory controller
	dut_memcont i_mod_memcont(
		.clk			(clk			),	// Clock
		.ecr_mem_op		(idr_data_OP	),	// Memory opcode
		.edr_addr_wr	(idr_addr_wr	),	// Memory write address
		.edr_addr_rd	(idr_addr_rd	),	// Memory read address
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
		.edr_alu_in0	(idr_data_A		),	// ALU input operand A
		.edr_alu_in1	(idr_data_B		),	// ALU input operand B
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
	parameter FSM_DUT_DECODE	= 3'b001;	// During this state, the device decodes the opcode to determine the function the device is to perform
	parameter FSM_DUT_COMPUTE	= 3'b010;	// During this state, the device carries out the function determined in the previous state
	parameter FSM_DUT_SIG		= 3'b011;	// During this state, disable control lines
	parameter FSM_DUT_PRIV		= 3'b100;	// During this state, private operations compute and complete
	parameter FSM_DUT_PAD		= 3'b101;	// Padding for operations to complete
	parameter FSM_DUT_RES		= 3'b110;	// During this state, set the result
	parameter FSM_DUT_DONE		= 3'b111;	// During this state, all computations are finished

	// Device control FSM
	always @(posedge clk) begin
		if (!reset_n) begin
			icr_dut_fsm	<= FSM_DUT_IDLE;
			// Clear control signals and data
			ics_en_mem	<= 1'b0;
			ics_en_alu	<= 1'b0;
			idr_data_A	<= 32'h00000000;
			idr_data_B	<= 32'h00000000;
			idr_addr_wr	<= 32'h00000000;
			idr_addr_rd	<= 32'h00000000;
//			ics_dec_op	<= 4'h0;		// XXXXX: decoder needs reset and error
			// Clear errors
			ies_dut_derr <= 8'h00;
			ies_dut_iop <= 1'b0;
		end
		else
			case (icr_dut_fsm)
				FSM_DUT_IDLE: begin	// Idle state
//$display("#####Idle.");	// TEMP
					if (start) begin
//$display("#####Process started. A=%h, B=%h",idr_data_A,idr_data_B);	// TEMP
						idr_data_A <= A;
						idr_data_B <= B;
						idr_data_OP <= op;
						icr_dut_fsm <= FSM_DUT_DECODE;
					end
				end
				FSM_DUT_DECODE: begin
//$display("#####Decode.");	// TEMP
					idr_addr_wr = idr_data_A;	// Prepare for memory access
					idr_addr_rd = idr_data_A;
					idr_data_wr = idr_data_B;
					icr_dut_fsm <= FSM_DUT_COMPUTE;
					if (ics_dec_op == `DECODE_SV) begin
																	idr_addr_rd = 32'hFFFFFFFF;
												idr_data_A = 32'hFFFFFFFF; // TEST
												idr_data_OP = 8'h06;
					end
				end
				FSM_DUT_COMPUTE: begin
//$display("#####Compute.");	// TEMP
					case (ics_dec_op)
						`DECODE_ARITH:		ics_en_alu <= 1'b1;
						`DECODE_ILLEGAL:	ies_dut_iop <= 1'b1;
						`DECODE_MEMORY:		ics_en_mem <= 1'b1;
						`DECODE_PRIVATE:	begin
												if (idr_addr_wr <= 32'h0000FFFF) idr_data_OP = 8'h00;
												else if (idr_addr_wr >= 32'hFFFF0000) idr_data_OP = 8'h06;
//												idr_data_OP = 8'h00;
												ics_en_mem = 1'b1;
											end
						`DECODE_PMEMORY:	ics_en_mem <= 1'b1;
						`DECODE_SV:			begin
//												idr_addr_rd = 32'hFFFFFFFF;
//												idr_data_A = 32'hFFFFFFFF; // TEST
//												idr_data_OP = 8'h06;
												ics_en_mem = 1'b1;
//$display("A=%h, OP=%h, Ena=%b", idr_addr_rd, idr_data_OP, ics_en_mem); // TEMP
//$display("&&&&&SV. %t", $time);	// TEMP
											end
						default: ies_dut_derr <= 1;	// Signal indicates an error in decoding the opcode
					endcase
					icr_dut_fsm <= FSM_DUT_SIG;
//$display("idr_data_OP=%h, idr_data_A=%h, ics_en_alu=%b", idr_data_OP,idr_data_A,ics_en_alu);
				end
				FSM_DUT_SIG: begin
//$display("#####Sig.");	// TEMP
					ics_en_alu <= 1'b0;
					ics_en_mem <= 1'b0;
					icr_dut_fsm <= FSM_DUT_PRIV;
				end
				FSM_DUT_PRIV: begin
								if (ics_dec_op == `DECODE_PRIVATE) begin
									idr_data_OP = op;
									idr_data_A = idr_data_rd;
									ics_en_alu = 1'b1;
								end
					icr_dut_fsm <= FSM_DUT_PAD;
//$display("#####Pad 1.");	// TEMP
end
				FSM_DUT_PAD: begin
								if (ics_dec_op == `DECODE_PRIVATE) ics_en_alu = 1'b0;
								icr_dut_fsm <= FSM_DUT_RES;
//$display("#####Pad 2.");	// TEMP
end
				FSM_DUT_RES: begin
//$display("#####Result.");	// TEMP
					case (ics_dec_op)
						`DECODE_ARITH:		result <= edr_alu_res;
						`DECODE_ILLEGAL:	result <= 64'hxxxxxxxxxxxxxxxx;
						`DECODE_MEMORY:		if(idr_data_OP == 8'h01) result <= {32'h00000000, idr_data_wr};
											else result <= {32'h00000000, idr_data_rd};
						`DECODE_PRIVATE:	result <= edr_alu_res;
						`DECODE_PMEMORY:	if(idr_data_OP == 8'h07) result <= {32'h00000000, idr_data_wr};
											else result <= {32'h00000000, idr_data_rd};
						`DECODE_SV:			result <= {32'h00000000, idr_data_rd};
						default: ies_dut_derr <= 1;	// Signal indicates an error in decoding the opcode
					endcase
					icr_dut_fsm <= FSM_DUT_DONE;
				end
				FSM_DUT_DONE: begin
//$display("#####Done.");	// TEMP
					ics_en_alu <= 1'b0;
					ics_en_mem <= 1'b0;
					icr_dut_fsm <= FSM_DUT_IDLE;
				end
				default: begin
					icr_dut_fsm <= FSM_DUT_IDLE;	// Reset to idle state if FSM enters an invalid state
				end
			endcase
	end

	// Assign outgoing control and error signals
	//assign done = (icr_dut_fsm == FSM_DUT_DONE);
	assign done = 1'b1;
	assign gp = (ees_addr_werr | ees_addr_rerr | ies_dut_derr | ees_alu_err | ees_dut_memc | ies_dut_iop);
	assign err[7] = 1'b0;
	assign err[6] = 1'b0;
	assign err[5] = ees_addr_werr;
	assign err[4] = ees_addr_rerr;
	assign err[3] = ies_dut_derr;
	assign err[2] = ees_alu_err;
	assign err[1] = ees_dut_memc;
	assign err[0] = ies_dut_iop;
	
endmodule

/*	Task decodes the incoming opcode
	Six possible states, including the default: illegal
*/
module dut_decode (
	input wire			clk,			// Clock
	input		[7:0]	ecr_alu_op,		// ALU opcode
	input				ecs_alu_oppf,	// ALU opcode prefix
	input				ecs_alu_sv,		// ALU restricted operating mode
	output reg	[3:0]	icr_dut_dop		// Device decoded opcode
);
	always @(posedge clk)
		if (ecs_alu_sv) 
			if (ecs_alu_oppf)
				if ((ecr_alu_op >= 8'h06 && ecr_alu_op <= 8'h09) || ecr_alu_op == 8'h0A) icr_dut_dop <= `DECODE_PRIVATE;
				else icr_dut_dop <= `DECODE_ILLEGAL;
			else
				if (ecr_alu_op == 8'h0A) icr_dut_dop <= `DECODE_SV;
				else icr_dut_dop <= `DECODE_ILLEGAL;
		else
			if (ecs_alu_oppf)
				if (ecr_alu_op == 8'h00 || ecr_alu_op == 8'h01) icr_dut_dop <= `DECODE_MEMORY;
				else if (ecr_alu_op == 8'h06 || ecr_alu_op == 8'h07) icr_dut_dop <= `DECODE_PMEMORY;
				else icr_dut_dop <= `DECODE_ILLEGAL;
			else
				if (ecr_alu_op <= 8'h05) icr_dut_dop <= `DECODE_ARITH;
				else icr_dut_dop <= `DECODE_ILLEGAL;
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
	parameter OP_ALU_NOT	= 8'h06;	// Logical Not
	parameter OP_ALU_DIV	= 8'h07;	// Arithmetic Division
	parameter OP_ALU_NOR	= 8'h08;	// Logical Nor
	parameter OP_ALU_NAND	= 8'h09;		// Logical Nand
//	parameter OP_ALU_MOD	= 8'h08;	// Arithmetic Modulus
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
				OP_ALU_NOT:		idr_alu_res <= ~edr_alu_in0;
				OP_ALU_DIV:		idr_alu_res <= edr_alu_in0 / edr_alu_in1;
				OP_ALU_NOR:		idr_alu_res <= ~(edr_alu_in0 | edr_alu_in1);
				OP_ALU_NAND:	idr_alu_res <= ~(edr_alu_in0 & edr_alu_in1);
/*				OP_ALU_MOD:		idr_alu_res <= edr_alu_in0 % edr_alu_in1;
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
	reg			[31:0]	idr_data_memu [65534:0];		// Upper memory block; one byte for address 32'hFFFF0000 to 32'hFFFFFFFF
	reg			[31:0]	idr_data_meml [65534:0];		// Lower memory block; one byte for address 32'h00000000 to 32'h0000FFFF
	
	always @(posedge clk) begin
		ies_addr_werr <= 0;
		if (ecs_en_wr) begin	// Memory write
			if (edr_addr_wr <= 32'h0000FFFF) idr_data_meml[edr_addr_wr[15:0]] <= edr_data_wr;
			else if (edr_addr_wr >= 32'hFFFF0000) begin 
				idr_data_memu[edr_addr_wr[15:0]] <= edr_data_wr;
				//$display("edr_data_wr=%h", edr_data_wr); // TEMP
			end
			else ies_addr_werr <= 1;
		end
	end
	always @(posedge clk) begin
		ies_addr_rerr <= 0;
		if (ecs_en_rd) begin
			if (edr_addr_rd <= 32'h0000FFFF) edr_data_rd <= idr_data_meml[edr_addr_rd[15:0]];
			else if (edr_addr_rd >= 32'hFFFF0000) begin 
				edr_data_rd <= idr_data_memu[edr_addr_rd[15:0]];
				//$display("edr_data_rd=%h", edr_data_rd); // TEMP
			end
			else ies_addr_rerr <= 1;
		end
	end
endmodule

/*	Module controls memory enable signals for memory operations
	Two possible states, LOAD:8'h00 and STORE:8'h01
*/
module dut_memcont (
	input wire			clk,			// Clock
	input wire	[7:0]	ecr_mem_op,		// Memory opcode
	input wire	[31:0]	edr_addr_wr,	// Memory write address
	input wire	[31:0]	edr_addr_rd,	// Memory read address
	input wire			ecs_en_mem,		// Memory operation enable
	output reg			ecs_en_wr,		// Memory write enable
	output reg			ecs_en_rd,		// Memory read enable
	output reg			ics_memc_err	// Memory controller error; asserted on invalid opcode
);
	always @(posedge clk) begin
//$display("#####MEM Access edr_addr_rd=%h %t.",edr_addr_rd,$time);	// TEMP
		ics_memc_err <= 0;
		if (ecs_en_mem) begin
//$display("#####MEM OP %h %t.",ecr_mem_op,$time);	// TEMP
			if (ecr_mem_op == 8'h00) begin		// Memory read (public)
				if (edr_addr_rd <= 32'h0000FFFF) begin
					ecs_en_wr <= 0;
					ecs_en_rd <= 1;
				end
				else begin
//$display("#####MEM Error A%t.",$time);	// TEMP
					ics_memc_err <= 1;
				end
			end
			else if (ecr_mem_op == 8'h01) begin	// Memory write (public)
				if (edr_addr_wr <= 32'h0000FFFF) begin
					ecs_en_wr <= 1;
					ecs_en_rd <= 0;
				end
				else begin
//$display("#####MEM Error B%t.",$time);	// TEMP
					ics_memc_err <= 1;
				end
			end
			else if (ecr_mem_op == 8'h06) begin	// Memory read (private)
//$display("#####MEM Access edr_addr_rd=%h %t.",edr_addr_rd,$time);	// TEMP
				if (edr_addr_rd >= 32'hFFFF0000) begin
					ecs_en_wr <= 0;
					ecs_en_rd <= 1;
				end
				else begin
//$display("#####MEM Error C%t.",$time);	// TEMP
					ics_memc_err <= 1;
				end
			end
			else if (ecr_mem_op == 8'h07) begin	// Memory write (private)
				if (edr_addr_wr >= 32'hFFFF0000) begin
					ecs_en_wr <= 1;
					ecs_en_rd <= 0;
				end
				else begin
//$display("#####MEM Error D%t.",$time);	// TEMP
					ics_memc_err <= 1;
				end
			end
			else begin							// Exception; controller should not reach this state
//$display("#####MEM Error%t.",$time);	// TEMP
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
	end
endmodule


