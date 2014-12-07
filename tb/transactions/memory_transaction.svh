class memory_transaction extends command_transaction;
   `uvm_object_utils(memory_transaction)

	 constraint data {
	 		  A > 32'h01;
			  A < 32'hEEEEFFFF;
			op_pf == 1'b1;
			sv == 1'b0;
	    op < 8'h0b;
		}
//   constraint data { A dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};
//                     B dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};} 
   

   function new (string name = "");
      super.new(name);
   endfunction : new

endclass : memory_transaction
        
