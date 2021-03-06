/*
	command_monitor class
		this class will be used to monitor all the funtcional inputs of the dut, this includes:
		sv, op_pf, op, A, B
*/

class command_monitor extends uvm_component;
   `uvm_component_utils(command_monitor);

   virtual dut_bfm bfm;

   uvm_analysis_port #(command_transaction) ap;

   function new (string name, uvm_component parent);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      if(!uvm_config_db #(virtual dut_bfm)::get(null, "*","bfm", bfm))
	`uvm_fatal("COMMAND MONITOR", "Failed to get BFM")
      bfm.command_monitor_h = this;
      ap  = new("ap",this);
   endfunction : build_phase

   function void write_to_monitor(longint A, longint B, bit sv, bit op_pf,  byte op);
     command_transaction cmd;
     `uvm_info("COMMAND MONITOR",$sformatf("MONITOR: A: %8h  B: %8h sv: %d op_pf: %d  op: %2h",
                A, B, sv, op_pf, op), UVM_HIGH);
     cmd = new("cmd");
     cmd.A = A;
     cmd.B = B;
		 cmd.sv = sv;
		 cmd.op_pf = op_pf;
     cmd.op = op;
     ap.write(cmd);
   endfunction : write_to_monitor
endclass : command_monitor

