class mul_transaction extends command_transaction;
   `uvm_object_utils(mul_transaction)

   constraint mul_only {op == mul_op;}

   function new(string name="");super.new(name);endfunction
endclass : mul_transaction

      
        