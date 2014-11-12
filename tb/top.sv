module top;
   import uvm_pkg::*;
   import   dut_pkg::*;
`include "uvm_macros.svh"
   
   dut_bfm       bfm();
   dut DUT (.A(bfm.A), .B(bfm.B), .op_pf(bfm.op_prefix), .op(bfm.op), 
                .clk(bfm.clk), .reset_n(bfm.reset_n), 
                .start(bfm.start), .sv(bfm.sv), .gp(bfm.gp), 
								.done(bfm.done), .err(bfm.err), .result(bfm.result));


initial begin
   uvm_config_db #(virtual dut_bfm)::set(null, "*", "bfm", bfm);
   run_test();
end

endmodule : top

     
   
