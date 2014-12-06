/*
   Copyright 2013 Ray Salemi

   Licensed under the Apache License, Version 2.0 (the "License");
   you may not use this file except in compliance with the License.
   You may obtain a copy of the License at

       http://www.apache.org/licenses/LICENSE-2.0

   Unless required by applicable law or agreed to in writing, software
   distributed under the License is distributed on an "AS IS" BASIS,
   WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
   See the License for the specific language governing permissions and
   limitations under the License.
*/
class add_transaction extends command_transaction;
   `uvm_object_utils(add_transaction)

   constraint add_only {
	 	op == _add;
		sv == 0;
		op_pf == 0;
		A dist { [32'h01 : 32'hFF]:=1 };
		B dist { [32'h01 : 32'hFF]:=1 };
	 
	 }

   function new(string name="");super.new(name);endfunction
endclass : add_transaction

      
        
