class illegalop_transactionn extends command_transaction;
   `uvm_object_utils(illegalop_transaction)

	 constraint ill_op {
	 		op {32'hB : 32'hFFFFFFFF };
		}
//   constraint data { A dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};
//                     B dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};} 
   

   function new (string name = "");
      super.new(name);
   endfunction : new

endclass : illegalop_transaction
        
