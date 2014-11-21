class memory_model extends uvm_subscriber #(memory_transaction);
   `uvm_component_utils(memory_model)
   uvm_analysis_port #(result_transaction) ap;
   uvm_tlm_analysis_fifo #(memory_transaction) mem_mon_f;
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction // new 

   function void build_phase(uvm_phase phase);
      ap = new("ap", this);
      mem_mon_f = new("mem_mon_f", this);
   endfunction // build_phase

   function void connect_phase(uvm_phase phase);
      /*if(!uvm_config_db::get("","mem_mon_f",this)
           uvm_error("mem_mon_f not found");
       */
   endfunction // connect_phase
   
   function void write(memory_transaction mem_xact);
      result_transaction predicted;
      `uvm_info(get_full_name(), "got mem_xact = ", UVM_LOW);
//      mem_f.write(predicted);
      
   endfunction // write
      
endclass // memory_model
