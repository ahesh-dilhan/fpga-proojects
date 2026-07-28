# =========================================================================
# build.tcl - Recreates the Vivado project from source files
#
# Usage:
#   vivado -mode batch -source scripts/build.tcl
# =========================================================================

set project_name   "uart_loopback"
set project_dir    "./build"

# ---------- CONFIRM THIS MATCHES YOUR BOARD ----------
#   Zybo Z7-20 -> xc7z020clg400-1
#   Zybo Z7-10 -> xc7z010clg400-1
set part_name       "xc7z020clg400-1"
# -------------------------------------------------------

create_project $project_name $project_dir -part $part_name -force

add_files -norecurse [glob -nocomplain ./src/*.v ./src/*.sv ./src/*.vhd]
add_files -fileset sim_1 -norecurse [glob -nocomplain ./sim/*.v ./sim/*.sv ./sim/*.vhd]
add_files -fileset constrs_1 -norecurse [glob -nocomplain ./constraints/*.xdc]

set_property top uart_loopback_top [current_fileset]
set_property top tb_uart_loopback [get_filesets sim_1]

update_compile_order -fileset sources_1
update_compile_order -fileset sim_1

puts "\n---------------------------------------------"
puts " Project '$project_name' created in $project_dir"
puts " Part: $part_name - confirm this matches your board!"
puts "---------------------------------------------\n"
