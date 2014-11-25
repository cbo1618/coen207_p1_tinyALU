// Decoded opcode operations
`define DECODE_ARITH3'b000// Arithmetic operationop: 8'h05:8'h00oppf: 0sv: 0
`define DECODE_ILLEGAL3'b001// Illegal operationop: 8'h0B:8'hFFoppf: 0,1sv: 0,1
`define DECODE_MEMORY3'b010// Memory operationop: 8'h01:8'h00oppf: 1sv: 0
`define DECODE_PRIVATE3'b011// Private operationop: 8'h09:8'h06oppf: 1sv: 1
`define DECODE_PMEMORY3'b100// Protected operationop: 8'h07:8'h06oppf: 1sv: 0
`define DECODE_SV3'b101// Restricted operationop: 8'h0Aoppf: 0sv: 1

module dut (
	    // Port declarations
	    input wireclk,
	    input wirereset_n,
	    input wire[31:0]A,
	    input wire[31:0]B,
	    input wire[7:0]op,
	    input wireop_pf,
	    input wiresv,
	    input wirestart,
	    output regdone,
	    output reg[63:0]result,
	    output reg[7:0]err,
	    output bitgp
	    );


   // Device internal signals
   // Device FSM signals
   reg [2:0] 	   icr_dut_fsm;
   // Device FSM state
   // Control signals
   regics_en_alu;
   // ALU compute enable
   regics_en_wr;
   // Memory write enable
   regics_en_rd;
   // Memory read enable
   reg [3:0] 	   ics_dec_op;
   // Decoded opcode
   regics_en_mem;
   // Memory operation enable
   reg [7:0] 	   idr_data_OP;
   // Register to hold opcode
   // Data registers
   reg [63:0] 	   edr_alu_res;
   // Result from ALU operation
   reg [31:0] 	   idr_addr_wr;
   // Memory write address
   reg [31:0] 	   idr_addr_rd;
   // Memory read address
   reg [31:0] 	   idr_data_wr;
   // Memory write
   wire [31:0] 	   idr_data_rd;
   // Memory read
   //reg[31:0]idr_addr_
   reg [31:0] 	   idr_data_A;
   // Register to hold input A
   reg [31:0] 	   idr_data_B;
   // Register to hold input B
   // Error signals
   reg 		   ees_addr_werr;
   // Memory write error
   reg 		   ees_addr_rerr;
   // Memory read error
   reg 		   ies_dut_derr;
   // Device decode error
   regees_alu_err;
   // ALU opcode error
   regees_dut_memc;
   // Memory controller error
   regies_dut_iop;
   // Device illegal opcode error

   // Internal modules
   // Device opcode decoder
   dut_decode i_mod_decode(
			   .clk(clk),
			   .ecr_alu_op(op),// ALU opcode
			   .ecs_alu_oppf(op_pf),// ALU opcode prefix
			   .ecs_alu_sv(sv),// ALU restricted operating mode
			   .icr_dut_dop(ics_dec_op)// Device decoded opcode
			   );

   // Device memory controller
   dut_memcont i_mod_memcont(
			     .clk(clk),// Clock
			     .ecr_mem_op(idr_data_OP),// Memory opcode
			     .edr_addr_wr(idr_addr_wr),// Memory write address
			     .edr_addr_rd(idr_addr_rd),// Memory read address
			     .ecs_en_mem(ics_en_mem),// Memory operation enable
			     .ecs_en_wr(ics_en_wr),// Memory write enable
			     .ecs_en_rd(ics_en_rd),// Memory read enable
			     .ics_memc_err(ees_dut_memc)// Memory controller error
			     );

   // Device memory module
   dut_memory i_mod_mem(
			.clk(clk),// Clock
			.ecs_en_wr(ics_en_wr),// Write-enable signal
			.ecs_en_rd(ics_en_rd),// Read-enable signal
			.edr_addr_wr(idr_addr_wr),// Write address
			.edr_addr_rd(idr_addr_rd),// Read address
			.edr_data_wr(idr_data_wr),// Data in (for writing to memory)
			.edr_data_rd(idr_data_rd),// Data out (for reading from memory)
			.ies_addr_werr(ees_addr_werr),// Memory write error signal
			.ies_addr_rerr(ees_addr_rerr)// Memory read error signal
			);

   // Device ALU module
   dut_alu i_mod_alu(
		     // Port declarations
		     .clk(clk),// Clock
		     .reset_n(reset_n),// Reset
		     .edr_alu_in0(idr_data_A),// ALU input operand A
		     .edr_alu_in1(idr_data_B),// ALU input operand B
		     .ecs_alu_op(op),// ALU opcode
		     .op_pf(op_pf),// XXXXX: Needs implementation
		     .ecs_alu_sv(sv),// ALU extra opcode control signal
		     .ecs_alu_comp(ics_en_alu),// ALU compute control signalXXXXX: Probably unnecessary
		     //.ics_alu_val(),// ALU result valid signalXXXXX: Should be handled by device
		     //.idr_alu_maddr(),// ALU memory address out register for memory operationsXXXXX: Possibly move to main module
		     .idr_alu_res(edr_alu_res),// ALU operation result registerXXXXX: Probably move to temporary register
		     .ies_alu_err(ees_alu_err)// ALU error signal; asserted high for one clock cycle when an invalid opcode is passed
		     );


   // Device Controller States
   parameter FSM_DUT_IDLE= 3'b000;
   // During this state, the device is inactive aP == 8'h07) result <= {32'h00000000, idr_data_wr};
else result <= {32'h00000000, idr_data_rd};

   `DECODE_SV:result <= {32'h00000000, idr_data_rd};

   default: ies_dut_derr <= 1;
   // Signal indicates an error in decoding the opcode
endcase // UNMATCHED!!
icr_dut_fsm <= FSM_DUT_DONE;

end // UNMATCHED !!
FSM_DUT_DONE: begin
   //$display("#####Done.");// TEMP
   ics_en_alu <= 1'b0;

   ics_en_mem <= 1'b0;

   icr_dut_fsm <= FSM_DUT_IDLE;

end // UNMATCHED !!
default: begin
   icr_dut_fsm <= FSM_DUT_IDLE;
   // Reset to idle state if FSM enters  OP_ALU_GTE= 8'h0;// Boolean Greater Than Or Equal
   // Memory Operations XXXXX: Possibly move to DUT control rather than ALU
   //parameter OP_ALU_STORE= 8'h0;// Store data in operand B in memo