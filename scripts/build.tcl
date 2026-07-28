# =========================================================================
# build.tcl - Recreates the Vivado project from source files
#
# Usage (from Vivado Tcl console, or from a terminal):
#   vivado -mode batch -source scripts/build.tcl
#
# This script does NOT get committed as a project (.xpr) - it recreates
# the project every time from the RTL/constraints in src/ and constraints/.
# That's what keeps the git repo small and clean.
# =========================================================================

# ---------- EDIT THESE FOR YOUR BOARD ----------
set project_name   "my_fpga_project"
set project_dir    "./build"
;# Common Zynq-7000 parts (uncomment the one matching your board):
;# ZedBoard        -> xc7z020clg484-1
;# Zybo Z7-20      -> xc7z020clg400-1
;# Zybo Z7-10      -> xc7z010clg400-1
;# PYNQ-Z2         -> xc7z020clg400-1
;# PYNQ-Z1         -> xc7z020clg400-1
set part_name       "xc7z020clg400-1"
# ------------------------------------------------

# Create (or overwrite) the project in a build/ dir that's gitignored
create_project $project_name $project_dir -part $part_name -force

# Add all RTL sources from src/
add_files -norecurse [glob -nocomplain ./src/*.v ./src/*.sv ./src/*.vhd]

# Add all simulation-only sources from sim/ (testbenches)
add_files -fileset sim_1 -norecurse [glob -nocomplain ./sim/*.v ./sim/*.sv ./sim/*.vhd]

# Add constraints
add_files -fileset constrs_1 -norecurse [glob -nocomplain ./constraints/*.xdc]

# Set the top module for synthesis (change this per project)
# set_property top my_top_module [current_fileset]

# Set the top module for simulation (change this per project)
# set_property top my_top_module_tb [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "\n---------------------------------------------"
puts " Project '$project_name' created in $project_dir"
puts " Remember to set 'top' properties above once"
puts " you know your module/testbench names."
puts "---------------------------------------------\n"
