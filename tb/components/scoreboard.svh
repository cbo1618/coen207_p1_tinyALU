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
class scoreboard extends uvm_subscriber #(result_transaction);
   `uvm_component_utils(scoreboard);


   uvm_tlm_analysis_fifo #(command_transaction) cmd_f;
   uvm_tlm_analysis_fifo #(command_transaction) mem_f;
   
   function new (string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      cmd_f = new ("cmd_f", this);
   endfunction : build_phase

function result_transaction predict_result(command_transaction cmd);
   result_transaction predicted;
    
   predicted = new("predicted");
   /* if (cmd.op_pf == 1 && operation is read)
    
        if (!mem_f.try_get(predicted)) //try and get the stuff pushed into memory
          $fatal(1, "Missing command in self checker");
    */
   case (cmd.op)
     _add: predicted.result = cmd.A + cmd.B;
     _and: predicted.result = cmd.A & cmd.B;
     _xor: predicted.result = cmd.A ^ cmd.B;
     _mul: predicted.result = cmd.A * cmd.B;
     _div: predicted.result = cmd.A / cmd.B;
   endcase // case (op_set)

   return predicted;

endfunction : predict_result
   

   function void write(result_transaction t);
      string data_str;
      command_transaction cmd;
      result_transaction predicted;
	

      do
        if (!cmd_f.try_get(cmd))
          $fatal(1, "Missing command in self checker");
      while ((cmd.op < 1) && (cmd.op > 5));
//      while ((cmd.op == no_op) || (cmd.op == rst_op));

      predicted = predict_result(cmd);
      
      data_str = {                    cmd.convert2string(), 
                  " ==>  Actual "  ,    t.convert2string(), 
                  "/Predicted ",predicted.convert2string()};
                  
      if (!predicted.compare(t))
        `uvm_error("SELF CHECKER", {"FAIL: ",data_str})
      else
        `uvm_info ("SELF CHECKER", {"PASS: ", data_str}, UVM_HIGH)

   endfunction : write
endclass : scoreboard






