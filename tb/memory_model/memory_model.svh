class memory_model extends uvm_subscriber #(memory_transaction);
   `uvm_component_utils(memory_model)
   uvm_analysis_port #(result_transaction) ap;
   uvm_tlm_analysis_fifo #(memory_transaction) mem_mon_f;
   int mem_arr[4294967296]; //internal memory array
   
   function new(string name, uvm_component parent);
      super.new(name, parent);
   endfunction // new 

   function void build_phase(uvm_phase phase);
      ap = new("ap", this);
      mem_mon_f = new("mem_mon_f", this);
   endfunction // build_phase

   function void connect_phase(uvm_phase phase);
      /*if(!uvm_config_db::get("","mem_mon_f",this)
           uvm_error("mem_mon_f not found");
       */
   endfunction // connect_phase

   function void update_memory(command_transaction cmd);
      case(cmd.op)
	_nop:begin
	   if(cmd.op_pf)
	     mem_arr[cmd.A] = cmd.B;
	end
	_add: begin
	   if(cmd.op_pf)
	     mem_arr[cmd.A] = cmd.B;
	end
	_and:;
	_xor:;
	_mul:;
	_div:;
	_lda : begin
	   if(cmd.op_pf && !cmd.sv && (cmd.A >= 32'hFFFF0000))
	     mem_arr[cmd.A] = cmd.B;
	   else if(cmd.op_pf && !cmd.sv && (cmd.A <= 32'h0000FFFF))
	     mem_arr[cmd.A] = cmd.B;
	end
	_wmr: begin
	   if(cmd.op_pf && !cmd.sv && (cmd.A >= 32'hFFFF0000))
	     mem_arr[cmd.A] = cmd.B;
	   else if(cmd.op_pf && !cmd.sv && (cmd.A >= 32'h0000FFFF))
	     mem_arr[cmd.A] = cmd.B;
	end
	_mov: begin
	   if(cmd.op_pf && cmd.sv && (cmd.A <= 32'h0000FFFF))
	     mem_arr[cmd.A] = cmd.B;
	end
p	_swp: begin
	   if(cmd.op_pf && cmd.sv && (cmd.A <= 32'h0000FFFF))
	     mem_arr[cmd.A] = cmd.B;
	end
	_wmr:;
      endcase // case (cmd.op)
      
   endfunction // update_memory
   
   function void write(memory_transaction mem_xact);
      result_transaction predicted;
      `uvm_info(get_full_name(), $sformatf("got mem_xact = %s", mem_xact.convert2string()), UVM_LOW);
      predicted = new("predicted");
      
      mem_f.write(predicted);
      
   endfunction // write
      
endclass // memory_model
