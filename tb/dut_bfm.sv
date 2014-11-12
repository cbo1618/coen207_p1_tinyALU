interface dut_bfm;
   import dut_pkg::*;

   bit  clk;
   bit  reset_n;
   bit  start;
	 bit 	sv;
	 bit op_prefix;
   byte unsigned op;
	 int A;
	 int B;
   
	 wire   done;
	 wire 	gp;
	 longint result;
   byte unsigned err;
	 operation_t  op_set;

	 assign op = op_set;

/*
   task reset_alu();
      reset_n = 1'b0;
      @(negedge clk);
      @(negedge clk);
      reset_n = 1'b1;
      start = 1'b0;
   endtask : reset_alu
   
*/

   task send_op(input byte iA, input byte iB, input bit op_pf, input operation_t iop, output shortint dut_result, output byte dut_err, output bit dut_gp);
      begin
         @(negedge clk);
         op_set = iop;
         A = iA;
         B = iB;
				 op_prefix = op_pf;
         start = 1'b1;
         do
           @(negedge clk);
         while (done == 0);
         //start = 1'b0;
         dut_result = result;
				 dut_err = err;
				 dut_gp = gp;
        
      end 
      
   endtask : send_op
   
   command_monitor command_monitor_h;

   function operation_t op2enum();
      case(op)
        0: return _nop;
        1: return _add;
        2: return _and;
        3: return _xor;
        4: return _mul;
        5: return _div;
        4: return _lda;
        4: return _sta;
        4: return _mov;
        4: return _swp;
        4: return _wmr;
        default : $fatal("Illegal operation on op bus");
      endcase // case (op)
   endfunction : op2enum


   always @(posedge clk) begin : op_monitor
      static bit in_command = 0;
      command_transaction command;
      if (start) begin : start_high
        if (!in_command) begin : new_command
           command_monitor_h.write_to_monitor(A, B, op_prefix, op2enum());
           in_command = (op2enum());
        end : new_command
      end : start_high
      else // start low
        in_command = 0;
   end : op_monitor

/*
   always @(negedge reset_n) begin : rst_monitor
      command_transaction command;
      command_monitor_h.write_to_monitor($random,0,rst_op);
   end : rst_monitor
*/ 
   result_monitor  result_monitor_h;

   initial begin : result_monitor_thread
      forever begin : result_monitor
         @(posedge clk) ;
         if (done) 
           result_monitor_h.write_to_monitor(result);
      end : result_monitor
   end : result_monitor_thread
   
	 /*

	 memory_monitor memory_monitor_h;
	 initial begin : memory_monitor_thread
	 	  forever begin : memory_monitor
			  @(posedge clk);
				if (done)
					memory_monitor_h.write_to_monitor(A, B, op2enum());
			end : memory_monitor
		end : memory_monitor_thread

		*/

   initial begin
      clk = 0;
      forever begin
         #10;
         clk = ~clk;
      end
   end


endinterface: dut_bfm
