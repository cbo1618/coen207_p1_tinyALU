/*
	memory_monitor not sure if this is needed since it would caputre same inputs??
*/

class memory_monitor extends uvm_component;
   `uvm_component_utils(memory_monitor);

   virtual dut_bfm bfm;

   uvm_analysis_port #(memory_transaction) ap;

   function new (string name, uvm_component parent);
      super.new(name,parent);
   endfunction

   function void build_phase(uvm_phase phase);
      if(!uvm_config_db #(virtual dut_bfm)::get(null, "*","bfm", bfm))
	`uvm_fatal("COMMAND MONITOR", "Failed to get BFM")
      bfm.memory_monitor_h = this;
      ap  = new("ap",this);
   endfunction : build_phase

   function void write_to_monitor(byte A, byte B, bit op_pf,  operation_t op);
     memory_transaction cmd;
     `uvm_info("COMMAND MONITOR",$sformatf("MONITOR: A: %2h  B: %2h  op_pf: %d  op: %s",
                A, B, op_pf, op.name()), UVM_HIGH);
     cmd = new("cmd");
     cmd.A = A;
     cmd.B = B;
		 cmd.op_pf = op_pf;
     cmd.op = op;
     ap.write(cmd);
   endfunction : write_to_monitor
endclass : memory_monitor

