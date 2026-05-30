# Xilinx Vivado Gui-less build script
# Based on this tutorial https://www.xilinx.com/video/hardware/using-the-non-project-batch-flow.html
# read_edif and read_ip commands are useful for using other IP.
# Note - you can add `start_gui` between any of these commands to interject into the Vivado environment. This lets you use any tools (and you can open any checkpoint too!).

if {![info exists ::env(SYNTH_HDL_SOURCES)]} {
  puts "Missing env SYNTH_HDL_SOURCES, quitting.";
  exit 1;
}

if {![info exists ::env(FPGA_PART)]} {
  puts "Missing env SYNTH_FPGA_PART, quitting.";
  exit 1;
}

if {![info exists ::env(SYNTH_XDC_FILE)]} {
  puts "Missing env XDC_FILE, quitting.";
  exit 1;
}

if {![info exists ::env(SYNTH_TOP_MODULE)]} {
  puts "Missing env SYNTH_TOP_MODULE, quitting.";
  exit 1;
}

puts "$::env(FPGA_PART)"
puts "$::env(SYNTH_XDC_FILE)"
puts "$::env(SYNTH_HDL_SOURCES)"
puts "$::env(SYNTH_TOP_MODULE)"


puts "################################################################################"
puts "Synthesizing for $::env(FPGA_PART) with xdc $::env(SYNTH_XDC_FILE) and sources $::env(SYNTH_HDL_SOURCES)"
puts "################################################################################"

read_verilog $::env(SYNTH_HDL_SOURCES)

read_xdc $::env(SYNTH_XDC_FILE)

# Sythesis & Optimization
synth_design -top $::env(SYNTH_TOP_MODULE) -part $::env(FPGA_PART) -verilog_define HDL_ROOT="$::env(HDL_ROOT)" -verilog_define TESTBENCH_ROOT="$::env(TESTBENCH_ROOT)"
report_drc -file drc.log -verbose
write_checkpoint -force synthesis.checkpoint
opt_design
# power_opt_design # optional till later.

report_timing_summary -file timing_summary.log
report_timing -sort_by group -max_paths 100 -path_type summary -file timing.log -verbose
report_utilization -file usage.log -verbose
report_utilization -hierarchical -file usage_by_module.log -verbose

place_design
# phys_opt_design # optional till later.
write_checkpoint -force place.checkpoint
route_design
write_checkpoint -force route.checkpoint

report_clocks -file clocks.log

# write bitstream
write_bitstream -force ./$::env(SYNTH_TOP_MODULE).bit
