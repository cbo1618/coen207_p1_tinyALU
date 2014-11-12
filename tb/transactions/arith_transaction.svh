class arith_transaction extends command_transaction;
   `uvm_object_utils(arith_transaction)

   constraint arith_only {
	 		op [8'h0 : 8'h5];
			}

   function new(string name="");super.new(name);endfunction
endclass : arith_transaction

      
        
