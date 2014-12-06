class arith_transaction extends command_transaction;
   `uvm_object_utils(arith_transaction)

   constraint arith_only {
	 		op dist {[8'h0 : 8'h5]:=1};
			sv == 0;
			op_pf == 0;
			}

   function new(string name="");super.new(name);endfunction
endclass : arith_transaction

      
        
