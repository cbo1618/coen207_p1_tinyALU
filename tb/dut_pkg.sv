package dut_pkg;
   import uvm_pkg::*;
`include "uvm_macros.svh"
   
      typedef enum bit[7:0] {
                             _nop,
                             _add, 
                             _and,
                             _xor,
                             _mul,
														 _div,
														 _lda,
														 _sta,
														 _mov,
														 _swp,
														 _wmr} operation_t;
   
   
`include "command_transaction.svh"
`include "arith_transaction.svh"
`include "memory_transaction.svh"
//`include "mul_transaction.svh"
//`include "mul2add_transaction.svh"
`include "add_transaction.svh"
`include "result_transaction.svh"
`include "coverage.svh"
`include "tester.svh"
`include "scoreboard.svh"
`include "driver.svh"
`include "command_monitor.svh"
`include "result_monitor.svh"
//`include "memory_monitor.svh"
//`include "memory_model.svh"
   
`include "env.svh"

`include "random_test.svh"
`include "arith_test.svh"
`include "add_test.svh"
`include "memory_test.svh"
//`include "mul_test.svh"
//`include "mul2add_test.svh"   
   
endpackage : dut_pkg
   
