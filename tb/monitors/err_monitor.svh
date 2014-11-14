class err_monitor extends uvm_component;
   `uvm_component_utils(err_monitor);

   virtual dut_bfm bfm;
   uvm_analysis_port #(err_transaction) ap;

   function new (string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
    if(!uvm_config_db #(virtual dut_bfm)::get(null, "*","bfm", bfm))
        `uvm_fatal("RESULT MONITOR", "Failed to get BFM")

      bfm.err_monitor_h = this;
      ap  = new("ap",this);
   endfunction : build_phase

   function void write_to_monitor(shortint r);
      err_transaction err_t;
      err_t = new("err_t");
      err_t.result = r;
      ap.write(err_t);
   endfunction : write_to_monitor
   
endclass : err_monitor






