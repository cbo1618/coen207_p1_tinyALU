vcs -ntb_opts uvm +vcs+lic+wait -debug_pp +define+COVER_ON -cm line -sverilog -assert dve -R -l vcs.log \
../rtl/dut_empty.sv 												\
./dut_pkg.sv				\
./dut_bfm.sv	\
./top.sv		\
+incdir+./components \
+incdir+./monitors \
+incdir+./tests \
+incdir+./transactions 

