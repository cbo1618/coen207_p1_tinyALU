class memory_transaction extends command_transaction;
   `uvm_object_utils(memory_transaction)

	 constraint data {
	 		A dist {[32'h01 : 32'h000000FF]:=1};
			op dist {[8'h6 : 8'h9]:=1};
			op_pf == 0;
			sv == 0;
		}
//   constraint data { A dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};
//                     B dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};} 
   

   function new (string name = "");
      super.new(name);
   endfunction : new

endclass : memory_transaction
        
