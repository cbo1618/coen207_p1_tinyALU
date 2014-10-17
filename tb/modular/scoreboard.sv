module scoreboard(tinyalu_bfm bfm);
   import tinyalu_pkg::*;

   always @(posedge bfm.done) begin 
      shortint predicted_result;
      #1;
      case (bfm.op_set)
        add_op: predicted_result = bfm.A + bfm.B;
        and_op: predicted_result = bfm.A & bfm.B;
        xor_op: predicted_result = bfm.A ^ bfm.B;
        mul_op: predicted_result = bfm.A * bfm.B;
      endcase // case (op_set)

      if ((bfm.op_set != no_op) && (bfm.op_set != rst_op)) begin
				assert (predicted_result == bfm.result);
				if (predicted_result != bfm.result)
					$error ("FAIL: %0h %s %0h expected: %0h actual: %0h", bfm.A, bfm.op_set.name(), bfm.B, predicted_result, bfm.result);
				else
					$display ("OK  : %0h %s %0h expected: %0h actual: %0h", bfm.A, bfm.op_set.name(), bfm.B, predicted_result, bfm.result);
			end

   end 
endmodule : scoreboard

