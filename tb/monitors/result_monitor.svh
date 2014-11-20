class result_monitor extends uvm_component;
   `uvm_component_utils(result_monitor);

   virtual dut_bfm bfm;
   uvm_analysis_port #(result_transaction) ap;

   function new (string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
    if(!uvm_config_db #(virtual dut_bfm)::get(null, "*","bfm", bfm))
        `uvm_fatal("RESULT MONITOR", "Failed to get BFM")

//      bfm.result_monitor_h = this;
      ap  = new("ap",this);
   endfunction : build_phase

   function void write_to_monitor(shortint r);
      result_transaction result_t;
      result_t = new("result_t");
      result_t.result = r;
      ap.write(result_t);
   endfunction : write_to_monitor

   task run_phase(uvm_phase phase);
      forever begin : result_monitor
         @(posedge clk) ;
         if (done) 
           write_to_monitor(result);
      end : result_monitor

   endtask // run_phase
   
endclass : result_monitor






