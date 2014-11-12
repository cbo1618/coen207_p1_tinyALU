class ring0_op_transactionn extends command_transaction;
   `uvm_object_utils(ring0_op_transaction)

	 constraint ring0_op {
	 		op { 8'hA };
			sv {1'b1};
		}
//   constraint data { A dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};
//                     B dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};} 
   

   function new (string name = "");
      super.new(name);
   endfunction : new

endclass : ring0_op_transaction
        
