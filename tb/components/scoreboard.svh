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
   uvm_tlm_analysis_fifo #(result_transaction) mem_f;
   longint mem_arr[ integer ]; //associative array for storing memory
   
   function new (string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      cmd_f = new ("cmd_f", this);
      mem_f = new ("mem_f", this);
   endfunction : build_phase

   function void update_memory(command_transaction cmd);
      case(cmd.op)
	8'h00 :;
	8'h01 : begin
	   if(cmd.op_pf)
	     mem_arr[cmd.A] = cmd.B;
	end
	8'h02:;
	8'h03:;
	8'h04:;
	8'h05:;
	8'h06 :;
	8'h07 : begin
	   if(cmd.op_pf && !cmd.sv && (cmd.A >= 32'hFFFF0000))
	     mem_arr[cmd.A] = cmd.B;
	end
	8'h08 :;
	8'h09 :;
	8'h0a :;
      endcase // case (cmd.op)
      
   endfunction // update_memory

function result_transaction predict_result(command_transaction cmd);
   result_transaction predicted;
    
   predicted = new("predicted");
   
   
      /* if (cmd.op_pf == 1 && operation is read)
    
        if (!mem_f.try_get(predicted)) //try and get the stuff pushed into memory
          $fatal(1, "Missing command in self checker");
    */
   case (cmd.op)
     8'h00 : begin 
	predicted.result = cmd.A + cmd.B;
     end
     8'h01 : begin
	if(cmd.op_pf && !cmd.sv)
	  predicted.result = mem_arr[cmd.A] & cmd.B;
	else
	  predicted.result = cmd.A + cmd.B;
     end
     8'h02 : predicted.result = cmd.A ^ cmd.B;
     8'h03 : predicted.result = cmd.A * cmd.B;
     8'h04 : predicted.result = cmd.A / cmd.B;
     8'h05 :;
     8'h06 : begin
		   if(cmd.op_pf && !cmd.sv && (cmd.A >= 32'hFFFF0000))
	     predicted.result = mem_arr[cmd.A];
	   else if(cmd.op_pf && !cmd.sv && (cmd.A <= 32'h0000FFFF))
	     predicted.result = !mem_arr[cmd.A];
     end
     8'h07 : begin
	   if(cmd.op_pf && !cmd.sv && (cmd.A >= 32'h0000FFFF))
	     predicted.result = mem_arr[cmd.A] / cmd.B;
     end
     8'h08 : begin
	if(cmd.op_pf && cmd.sv && (cmd.A >= 32'h0000FFFF))
	     predicted.result = !(mem_arr[cmd.A] | cmd.B);
     end
     8'h09 : begin
	if(cmd.op_pf && cmd.sv && (cmd.A >= 32'h0000FFFF))
	     predicted.result = !(mem_arr[cmd.A] & cmd.B);
     end
     8'h0a : begin
     end
     default : begin
	`uvm_info("scoreboard",$sformatf("invalid opcode %d", cmd.op), UVM_LOW)
     end
     
   endcase // case (op_set)

   return predicted;

endfunction : predict_result
   

   function void write(result_transaction t);
      string data_str;
      command_transaction cmd;
      result_transaction predicted;
	

//      do
        if (!cmd_f.try_get(cmd))
          $fatal(1, "Missing command in self checker");
//      while ((cmd.op < 1) && (cmd.op > 5));
//      while ((cmd.op == no_op) || (cmd.op == rst_op));

      update_memory(cmd);
      
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






