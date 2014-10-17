coen207_p1_tinyALU
==================
I have finished converting the vhdl files to systemverilog and have attached the directory. To run the simulation, give execution permissions to the files in ./tinyalu/scripts.
> chmod 777 runsim
> ./runsim
(run from the tinyalu directory)
The CLEAN command just removes the simulation files from the directory.

There shouldn't be any errors when compiling, and the simulation will print out nothing (no errors). If you want to see what values are being tested, add the following line at the beginning of any initial block:

    $monitor("Time:%d A: %0h  B: %0h  op: %s result: %0h", $time, A, B, op_set.name(), result);

There is an error when compiling the files with the given testbench. It should show the following error:

Error-[SVA-SSTINSC] SVA-system task in non-SVA context.
    Attempt to use a SVA-system task in  non-SVA context.
    "./tinyalu_tb.sv", 176: $error ("FAILED: A: %0h  B: %0h  op: %s result: %0h",
    A, B, op_set.name(), result);

This happens because there is no assertion tied to the use of the task "$error". To correct this, I have changed lines 174-177 to the following:

      if ((op_set != no_op) && (op_set != rst_op))
        assert (predicted_result == result)
      else
        $error ("FAILED: A: %0h  B: %0h  op: %s result: %0h",
                  A, B, op_set.name(), result);

 - Calvin
