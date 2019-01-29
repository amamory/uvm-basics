#------------------------------------------------
# these are the knobs you might want to change. 
#------------------------------------------------
set SEED      "random"
set VERBOSITY "UVM_LOW"
# set true to enable coverage
set COVERAGE  "false"
# set true to simulate RTL, otherwise, simulates the netlist
set RTL_SIM   "true"
# set true to simulate for debug, otherwise simulate for speed/regression
set DEBUG_SIM "true"      

# lists of tests to be executed
#set TEST_NAMES {parallel_test}
set TEST_NAMES {repeat_test}

set ::env(VIP_LIBRARY_HOME) /home/ale/repos/verif/uvm-basics/noc-router/vips
set ::env(PROJECT_DIR) /home/ale/repos/verif/uvm-basics/noc-router/hermes_noc
#set ::env(VIP_LIBRARY_HOME) /home/ale/repos/study/uvm-basics/noc-router/vips
#set ::env(PROJECT_DIR) /home/ale/repos/study/uvm-basics/noc-router/hermes_noc

file delete -force *~ *.ucdb vsim.dbg *.vstf *.log work *.mem *.transcript.txt certe_dump.xml *.wlf covhtmlreport VRMDATA
file delete -force design.bin qwave.db dpiheader.h visualizer*.ses
file delete -force veloce.med veloce.wave veloce.map tbxbindings.h modelsim.ini edsenv velrunopts.ini
file delete -force sv_connect.*
vlib work 
# interfaces
vlog -sv -suppress 2223 -suppress 2286 +incdir+$env(VIP_LIBRARY_HOME)/hermes_pkg -F $env(VIP_LIBRARY_HOME)/hermes_pkg/hvl.f 
vlog -sv -suppress 2223 -suppress 2286 +incdir+$env(VIP_LIBRARY_HOME)/hermes_pkg -F $env(VIP_LIBRARY_HOME)/hermes_pkg/hdl.f 

# router env
vlog -sv -suppress 2223 -suppress 2286 +incdir+$env(VIP_LIBRARY_HOME)/hermes_router_env_pkg $env(VIP_LIBRARY_HOME)/hermes_router_env_pkg/hermes_router_env_pkg.sv

# noc environment
vlog -sv -suppress 2223 -suppress 2286 +incdir+$env(PROJECT_DIR)/tb/testbench $env(PROJECT_DIR)/tb/testbench/hermes_noc_env_pkg.sv
#vlog -sv -suppress 2223 -suppress 2286 +incdir+$env(VIP_LIBRARY_HOME)/hermes_noc_env_pkg $env(VIP_LIBRARY_HOME)/hermes_noc_env_pkg/hermes_noc_env_pkg.sv

# tests and seqs
vlog -sv -suppress 2223 -suppress 2286 +incdir+$env(PROJECT_DIR)/tb/seqs $env(PROJECT_DIR)/tb/seqs/hermes_noc_seq_pkg.sv
vlog -sv -suppress 2223 -suppress 2286 +incdir+$env(PROJECT_DIR)/tb/tests $env(PROJECT_DIR)/tb/tests/hermes_noc_test_pkg.sv

#dut
if {[string equal $RTL_SIM "true"]} {
	# the part related to the central router, tested in hermes_router
	vcom -suppress 2223 -suppress 2286 -F $env(PROJECT_DIR)/../hermes_router/rtl/hdl_vhd.f
	# the rest of the design of the entire NOC
	vcom -suppress 2223 -suppress 2286 -F $env(PROJECT_DIR)/rtl/hdl_vhd.f
	# the SV wrapper
	vlog -sv -suppress 2223 -suppress 2286 +incdir+$env(PROJECT_DIR)/rtl -F $env(PROJECT_DIR)/rtl/hdl_v.f
} else {
	vlog -sv -suppress 2223 -suppress 2286 +incdir+$env(PROJECT_DIR)/syn -F $env(PROJECT_DIR)/syn/hdl_v.f
}

#testbench
vlog -sv -suppress 2223 -suppress 2286 +incdir+$env(PROJECT_DIR)/tb/testbench $env(PROJECT_DIR)/tb/testbench/top.sv

if {[string equal $DEBUG_SIM "true"]} {
	vopt +acc top  -o optimized_debug_top_tb
	set top optimized_debug_top_tb
} else {
	vopt      top  -o optimized_batch_top_tb
	set top optimized_batch_top_tb
}

#vsim -sv_seed $SEED +UVM_VERBOSITY=$VERBOSITY  $top
#vsim -sv_seed random "+UVM_TESTNAME=repeat_test" "+UVM_VERBOSITY=UVM_LOW" -permit_unmatched_virtual_intf "+notimingchecks" -suppress 8887 -uvmcontrol=all -msgmode both -classdebug -assertdebug "+uvm_set_config_int=*,enable_transaction_viewing,1" optimized_debug_top_tb

# execute all the tests in TEST_NAME 
for {set i 0} {$i<[llength $TEST_NAMES]} {incr i} {
    set test [lindex $TEST_NAMES $i]
    if {[string equal $RTL_SIM "true"]} {
    	if {[string equal $DEBUG_SIM "true"]} {
		vsim -sv_seed $SEED +UVM_TESTNAME=$test +UVM_VERBOSITY=$VERBOSITY -permit_unmatched_virtual_intf +notimingchecks -suppress 8887   -uvmcontrol=all -msgmode both -classdebug -assertdebug  +uvm_set_config_int=*,enable_transaction_viewing,1  $top
	} else {
		vsim -sv_seed $SEED +UVM_TESTNAME=$test +UVM_VERBOSITY=$VERBOSITY  $top
	}
    } else {
      # netlist simulation 
	vsim -sdfmax /top/dut1/CC/=../syn/src/layout/RouterCC.sdf -sv_seed $SEED +UVM_TESTNAME=$test +UVM_VERBOSITY=$VERBOSITY  $top
    }
	#onbreak {resume}
	onfinish stop;
	log /* -r
	do shutup.do
	#do wave_full.do
	run -all
	if {[string equal $COVERAGE "true"]} {
		coverage attribute -name TESTNAME -value $test
		coverage save ${test}.ucdb	
		vcover merge  -out hermes_noc.ucdb ${test}.ucdb
	}
}

if {[string equal $COVERAGE "true"]} {
	vcover report hermes_noc.ucdb -cvg -details
}
