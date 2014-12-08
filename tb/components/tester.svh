class tester extends uvm_component;
   `uvm_component_utils (tester)

   uvm_put_port #(command_transaction) command_port;

   function new (string name, uvm_component parent);
      super.new(name, parent);
   endfunction : new

   function void build_phase(uvm_phase phase);
      command_port = new("command_port", this);
   endfunction : build_phase

   task run_phase(uvm_phase phase);
      command_transaction  command;

      phase.raise_objection(this);

      command = new("command");
      command.reset_n = 0;
      command_port.put(command);

      repeat (100) begin
         command = command_transaction::type_id::create("command");
         assert(command.randomize());
         $display("TESTER: putting command: %s\n", command.convert2string());
				 command_port.put(command);
      end
/*
      command = new("command");
      command.op = _mul;
      command.A = 32'hFFFFFFFF;
      command.B = 32'hFFFFFFFF;
      command_port.put(command);
*/
//      #500;
      phase.drop_objection(this);
   endtask : run_phase
endclass : tester






