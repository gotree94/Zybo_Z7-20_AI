
# ============================================================================
# create_alu_project.tcl
# Zybo Z7-20 | Week02: AXI4-Lite Slave (my_axi_alu) project bootstrap
#
# Usage (Vivado Tcl console):
#   source create_alu_project.tcl
#
# Notes:
# - This script creates a project, block design, and wiring for PS7 + AXI infra.
# - It *optionally* adds a packaged IP "my_axi_alu" from ip_repo if available.
#   Expected VLNV: user.org:user:my_axi_alu:1.0
# - If the IP isn't found, the design is left ready; add the IP later and re-run
#   the "Connect/Address" section manually (or re-source this script).
# ============================================================================

# --------------------- User Config ---------------------
set proj_name "Zybo_AXI_Slave"
set proj_dir  "[pwd]/vivado_project"
# Board part may vary depending on installed board files.
# Common ID for Zybo Z7-20:
set board_part "digilentinc.com:zybo-z7-20:part0:1.0"

# Optional local IP repository containing packaged my_axi_alu
# Place your packaged IP at: ./ip_repo/my_axi_alu
set ip_repo   "[pwd]/ip_repo"

# Export (XSA) path after bitstream
set xsa_out   "[pwd]/export/${proj_name}.xsa"

# my_axi_alu VLNV (update if your VLNV differs)
set alu_vlnv "user.org:user:my_axi_alu:1.0"
# -------------------------------------------------------

puts "==> Creating project $proj_name at $proj_dir"
file mkdir $proj_dir
create_project $proj_name $proj_dir -part xc7z020clg400-1

# Try to set board_part (requires Digilent board files installed)
if {[catch {set_property board_part $board_part [current_project]} msg]} {
  puts "WARN: Unable to set board_part '$board_part' ($msg). Proceeding with part only."
}

# Register IP repo if present
if {[file isdirectory $ip_repo]} {
  puts "==> Adding IP repository: $ip_repo"
  set_property ip_repo_paths $ip_repo [current_project]
  update_ip_catalog
} else {
  puts "INFO: IP repo not found at $ip_repo (this is OK if you add later)."
}

# Create Block Design
set bd_name "design_1"
puts "==> Creating block design $bd_name"
create_bd_design $bd_name

# Add PS7
puts "==> Adding ZYNQ7 Processing System"
create_bd_cell -type ip -vlnv xilinx.com:ip:processing_system7:5.5 ps7

# Run block automation for DDR/FIXED_IO
apply_bd_automation -rule xilinx.com:bd_rule:processing_system7 -config { make_external "FIXED_IO, DDR" } [get_bd_cells ps7]

# Create Processor System Reset
puts "==> Adding Processor System Reset"
create_bd_cell -type ip -vlnv xilinx.com:ip:proc_sys_reset:5.0 rst_ps7

# Clocking: tie FCLK_CLK0 to design aclk
puts "==> Creating clocking nets"
# Enable FCLK_CLK0 if not already
set_property -dict [list CONFIG.PCW_USE_FABRIC_CLOCKS {1} CONFIG.PCW_FCLK0_PERIPHERAL_CLKSRC {DDR PLL} CONFIG.PCW_FCLK_CLK0_BUF {TRUE}] [get_bd_cells ps7]

# Connect FCLK_CLK0 to rst_ps7/slowest_sync_clk
connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins rst_ps7/slowest_sync_clk]
# Connect external reset
connect_bd_net [get_bd_pins ps7/FCLK_RESET0_N] [get_bd_pins rst_ps7/ext_reset_in]

# Attempt to add my_axi_alu
set alu_added 0
if {[lsearch -exact [get_ipdefs -all] $alu_vlnv] >= 0} {
  puts "==> Adding IP: $alu_vlnv"
  create_bd_cell -type ip -vlnv $alu_vlnv my_axi_alu_0
  set alu_added 1
} else {
  puts "INFO: IP $alu_vlnv not found in catalog. Skipping for now."
}

# If ALU exists, add AXI interconnect and wire S_AXI to GP0
if {$alu_added} {
  puts "==> Adding AXI Interconnect"
  create_bd_cell -type ip -vlnv xilinx.com:ip:axi_interconnect:2.1 axi_ic_0
  # 1 master (ps7 M_AXI_GP0) -> 1 slave (my_axi_alu_0 S_AXI)
  set_property -dict [list CONFIG.NUM_MI {1} CONFIG.NUM_SI {1}] [get_bd_cells axi_ic_0]

  # Clocking/Reset
  connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins axi_ic_0/ACLK]
  connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins axi_ic_0/M00_ACLK]
  connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins axi_ic_0/S00_ACLK]

  connect_bd_net [get_bd_pins rst_ps7/peripheral_aresetn] [get_bd_pins axi_ic_0/ARESETN]
  connect_bd_net [get_bd_pins rst_ps7/peripheral_aresetn] [get_bd_pins axi_ic_0/M00_ARESETN]
  connect_bd_net [get_bd_pins rst_ps7/peripheral_aresetn] [get_bd_pins my_axi_alu_0/s_axi_aresetn]

  # Connect PS GP0 to Interconnect
  connect_bd_intf_net [get_bd_intf_pins ps7/M_AXI_GP0] [get_bd_intf_pins axi_ic_0/S00_AXI]

  # Connect Interconnect to ALU S_AXI
  connect_bd_intf_net [get_bd_intf_pins axi_ic_0/M00_AXI] [get_bd_intf_pins my_axi_alu_0/S_AXI]

  # Clock to ALU
  connect_bd_net [get_bd_pins ps7/FCLK_CLK0] [get_bd_pins my_axi_alu_0/s_axi_aclk]

  # Address assignment
  puts "==> Assigning addresses"
  assign_bd_address
} else {
  puts "INFO: Skipping AXI wiring (my_axi_alu not present)."
}

# Validate and save BD
puts "==> Validating design"
validate_bd_design

puts "==> Saving design"
save_bd_design

# Generate wrapper & bitstream
puts "==> Creating HDL wrapper"
make_wrapper -files [get_files ${proj_dir}/${proj_name}.srcs/sources_1/bd/${bd_name}/${bd_name}.bd] -top
add_files -norecurse ${proj_dir}/${proj_name}.srcs/sources_1/bd/${bd_name}/hdl/${bd_name}_wrapper.v

puts "==> Launching Synthesis/Implementation/Bitstream"
launch_runs impl_1 -to_step write_bitstream
wait_on_run impl_1

# Export hardware with bit
file mkdir [file dirname $xsa_out]
puts "==> Exporting XSA to $xsa_out"
write_hw_platform -fixed -include_bit -force -file $xsa_out

puts "==> DONE. Project at: $proj_dir"
puts "    XSA at: $xsa_out"
if {!$alu_added} {
  puts "NOTE: my_axi_alu IP was not found. Add your packaged IP at $ip_repo and re-run the wiring section if needed."
}
