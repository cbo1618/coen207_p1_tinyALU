class coverage extends uvm_subscriber #(command_transaction);
   `uvm_component_utils(coverage)
   longint       A;
   longint       B;
	 bit 					sv;
	 bit          op_pf;
   operation_t  op_set;

   covergroup op_cov;

      coverpoint op_set {
         bins arith_ops[] = {[_nop : _div]};
         bins mem_ops[] = {[_sta : _swp]};

         bins r0_op = {_wmr};
//         bins rst_opn[] = (rst_op => [_add:_mul]);

//         bins sngl_mul[] = ([_add:_xor],_nop => _mul);
//         bins mul_sngl[] = (_mul => [_add:_xor], _nop);

//         bins twoops[] = ([_add:_mul] [* 2]);
//         bins manymult = (_mul [* 3:5]);

//         bins rstmulrst   = (rst_op => _mul [=  2] => rst_op);
//         bins rstmulrstim = (rst_op => _mul [-> 2] => rst_op);

      }

   endgroup

   covergroup zeros_or_ones_on_ops;

      all_ops : coverpoint op_set {
         ignore_bins null_ops = {[_lda : _wmr]};}

      a_leg: coverpoint A {
         bins zeros = {'h00};
         bins others= {['h01:'hFE]};
         bins ones  = {'hFF};
      }

      b_leg: coverpoint B {
         bins zeros = {'h00};
         bins others= {['h01:'hFE]};
         bins ones  = {'hFF};
      }

      op_00_FF:  cross a_leg, b_leg, all_ops {
         bins add_00 = binsof (all_ops) intersect {_add} &&
                       (binsof (a_leg.zeros) || binsof (b_leg.zeros));

         bins add_FF = binsof (all_ops) intersect {_add} &&
                       (binsof (a_leg.ones) || binsof (b_leg.ones));

         bins and_00 = binsof (all_ops) intersect {_and} &&
                       (binsof (a_leg.zeros) || binsof (b_leg.zeros));

         bins and_FF = binsof (all_ops) intersect {_and} &&
                       (binsof (a_leg.ones) || binsof (b_leg.ones));

         bins xor_00 = binsof (all_ops) intersect {_xor} &&
                       (binsof (a_leg.zeros) || binsof (b_leg.zeros));

         bins xor_FF = binsof (all_ops) intersect {_xor} &&
                       (binsof (a_leg.ones) || binsof (b_leg.ones));

         bins mul_00 = binsof (all_ops) intersect {_mul} &&
                       (binsof (a_leg.zeros) || binsof (b_leg.zeros));

         bins mul_FF = binsof (all_ops) intersect {_mul} &&
                       (binsof (a_leg.ones) || binsof (b_leg.ones));

         bins mul_max = binsof (all_ops) intersect {_mul} &&
                        (binsof (a_leg.ones) && binsof (b_leg.ones));

         ignore_bins others_only =
                                  binsof(a_leg.others) && binsof(b_leg.others);

      }

endgroup


   function new (string name, uvm_component parent);
      super.new(name, parent);
      op_cov = new();
      zeros_or_ones_on_ops = new();
   endfunction : new



   function void write(command_transaction t);
         A = t.A;
         B = t.B;
				 sv = t.sv;
				 op_pf = t.op_pf;
         op_set = t.op;
         op_cov.sample();
         zeros_or_ones_on_ops.sample();
   endfunction : write

endclass : coverage






