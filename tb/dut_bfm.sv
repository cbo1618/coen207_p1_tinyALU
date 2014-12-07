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
//	 operation_t  op_set;

//	 assign op = op_set;

/*
   task reset_alu();
      reset_n = 1'b0;
      @(negedge clk);
      @(negedge clk);
      reset_n = 1'b1;
      start = 1'b0;
   endtask : reset_alu
   
*/
   clocking cb @(posedge clk);
      output clk, reset_n, start, sv, op_prefix, op, A, B;
      input done, gp, result, err;
   endclocking // cb

   clocking moncb @(posedge clk);
      input clk, reset_n, start, sv, op_prefix, op, A, B;
      output done, gp, result, err;
   endclocking // cb

   clocking ncb @(negedge clk);
      output clk, reset_n, start, sv, op_prefix, op, A, B;
      input done, gp, result, err;
   endclocking // cb

   task trig_reset();
      @(ncb) reset_n = 1'b1;
      @(ncb) reset_n = 1'b0;
      @(ncb) reset_n = 1'b1;
   endtask // trig_reset
   
   
   task send_op(input int iA, input int iB, input bit isv, input bit op_pf, input byte iop, output longint dut_result, output byte dut_err, output bit dut_gp);
      begin
         @(ncb);
//         op_set = iop;
					op = iop;
         A = iA;
         B = iB;
				 sv = isv;
				 op_prefix = op_pf;
         start = 1'b1;
	 @(ncb);
	 start = 1'b0;
         do begin
         $display("waiting for done signale from DUT");
         @(ncb);
         end while (done == 0);
         $display("DUT signaled DONE!");
				 start = 1'b0;
	 $display($sformatf("result = %d", result));
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
        6: return _lda;
        7: return _sta;
        8: return _mov;
        9: return _swp;
        10: return _wmr;
//        default : $fatal("Illegal operation on op bus");
        default : return -1;
      endcase // case (op)
   endfunction : op2enum

   
/*   always @(posedge clk) begin : op_monitor
      static bit in_command = 0;
      command_transaction command;
      if (start) begin : start_high
        if (!in_command) begin : new_command
           command_monitor_h.write_to_monitor(A, B, sv, op_prefix, op);
           //in_command = (op2enum());
           in_command = 1;
        end : new_command
      end : start_high
      else // start low
        in_command = 0;
   end : op_monitor */

/*
   always @(negedge reset_n) begin : rst_monitor
      command_transaction command;
      command_monitor_h.write_to_monitor($random,0,rst_op);
   end : rst_monitor
*/ 
/*   result_monitor  result_monitor_h;

   initial begin : result_monitor_thread
      forever begin : result_monitor
         @(posedge clk) ;
         if (done) 
           result_monitor_h.write_to_monitor(result);
      end : result_monitor
   end : result_monitor_thread */
   
	 /*

	 memory_monitor memory_monitor_h;
	 initial begin : memory_monitor_thread
	 	  forever begin : memory_monitor
			  @(posedge clk);
				if (done)
					memory_monitor_h.write_to_monitor(A, B, op);
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
