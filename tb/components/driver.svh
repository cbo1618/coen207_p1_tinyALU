class driver extends uvm_component;
   `uvm_component_utils(driver)

   virtual dut_bfm bfm;

   uvm_get_port #(command_transaction) command_port;

   function new (string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new
   
   function void build_phase(uvm_phase phase);
      if(!uvm_config_db #(virtual dut_bfm)::get(null, "*","bfm", bfm))
        `uvm_fatal("DRIVER", "Failed to get BFM")
      command_port = new("command_port",this);
   endfunction : build_phase

   task run_phase(uvm_phase phase);
//    byte         unsigned        iA;
//    byte         unsigned        iB;
//      operation_t                  op_set;
      shortint     result;
			byte 	dut_err;
			bit dut_gp;
      bit 		    done = 1;
      command_transaction    command;
      forever begin : command_loop
	 if(done) begin
	   command_port.get(command);
	 end
//	 if(bfm.done && command_port.try_get(command)) begin
	    if(!command.reset_n) begin
	       `uvm_info("driver", "reset command", UVM_LOW)
		 bfm.trig_reset();
	       `uvm_info("driver", $sformatf("bfm.done = %d", bfm.done), UVM_LOW)
	    end
	    else if(done)
              bfm.send_op(command.A, command.B, command.sv, command.op_pf, command.op, result, dut_err, dut_gp);
	    else
	      done = bfm.done;
	 
//	 end
      end : command_loop
   endtask : run_phase
   
   
endclass : driver
