class priv_transactionn extends command_transaction;
   `uvm_object_utils(priv_transaction)

	 constraint priv {
	 		A dist { [32'hFFFF0000 : 32'hFFFFFFFF]:=1, [32'h1 : 32'hEEEEFFFF]:=1 };
			op_pf {1'b1};
	 		op { [8'h6 : 8'h9]:=1, [8'hA]:=1 };
			sv {1'b1};
		}
//   constraint data { A dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};
//                     B dist {8'h00:=1, [8'h01 : 8'hFE]:=1, 8'hFF:=1};} 
   

   function new (string name = "");
      super.new(name);
   endfunction : new

endclass : priv_transaction
        
