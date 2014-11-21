class memory_model extends uvm_subscriber #(memory_transaction);
   `uvm_object_utils(memory_model)
   uvm_tlm_analysis_fifo #(result_transaction) mem_f;
   uvm_tlm_analysis_fifo #(memory_transaction) mem_mon_f;
   
   class new(string name);
      super.new(name);
   endclass // new

   function void build_phase(uvm_phase phase);
      mem_mon_f = new("mem_mon_f", this);
   endfunction // build_phase

   function void connect_phase(uvm_phase phase);
      /*if(!uvm_config_db::get("","mem_mon_f",this)
           uvm_error("mem_mon_f not found");
       */
   endfunction // connect_phase
   
   function void write(memory_transaction mem_xact);
      result_transaction predicted;
      uvm_info("got mem_xact = ");
      mem_f.write(predicted);
      
   endtask // run_phase
   
   
      
endclass // memory_model
