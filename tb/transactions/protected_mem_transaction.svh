class protected_mem_transactionn extends command_transaction;
   `uvm_object_utils(protected_mem_transaction)

	 constraint protmem {
	 		A dist { 32'hFFFF0000 : 32'hFFFFFFFF };
			op_pf {1'b1};
	 		op { 8'h6 : 8'h9 };
			sv {1'b0};
		}
//   constraint data { A dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};
//                     B dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};} 
   

   function new (string name = "");
      super.new(name);
   endfunction : new

endclass : protected_mem_transaction
        
