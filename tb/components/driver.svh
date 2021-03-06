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
      command_transaction    command;
      forever begin : command_loop
         command_port.get(command);
				 $display("DRIVER: getting command: %s", command.convert2string());
         bfm.send_op(command.A, command.B, command.sv, command.op_pf, command.op, result, dut_err, dut_gp);
      end : command_loop
   endtask : run_phase
   
   
endclass : driver
