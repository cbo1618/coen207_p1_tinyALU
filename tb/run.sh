vcs -ntb_opts uvm +vcs+lic+wait -debug_pp +define+COVER_ON -cm line -sverilog -assert dve -R -l vcs.log \
../rtl/single_cycle.sv											\
../rtl/three_cycle.sv 											\
../rtl/tinyalu.sv 												\
./tinyalu_pkg.sv				\
./tinyalu_bfm.sv	\
./top.sv		\
+incdir+./tb_classes

