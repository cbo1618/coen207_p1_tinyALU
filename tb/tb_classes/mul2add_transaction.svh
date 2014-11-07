class mul2add_transaction extends command_transaction;
   `uvm_object_utils(mul2add_transaction)

   constraint mul2add_only {(op == mul_op) || (op == add_op);}

   function new(string name="");super.new(name);endfunction
endclass : mul2add_transaction

      
        