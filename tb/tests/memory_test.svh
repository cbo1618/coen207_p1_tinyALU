class memory_test extends random_test;
   `uvm_component_utils(memory_test);

function void build_phase(uvm_phase phase);
 command_transaction::type_id::set_type_override(memory_transaction::get_type());
 super.build_phase(phase);
endfunction : build_phase
   
   function new (string name, uvm_component parent);
      super.new(name,parent);
   endfunction : new

  
endclass
