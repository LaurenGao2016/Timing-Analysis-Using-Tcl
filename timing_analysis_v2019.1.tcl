#########################################################################################
## Author  : Lauren Gao
## File    : timing_analysis_v2019.1.tcl
## Company : Xilinx
## Description : timing analysis by tcl scripts
## Please follow the steps below
#########################################################################################
# Step 1: Install Design Utilities
#-------> Tools -> Xilinx Tcl Store -> Design Utilities
########################################################
# Step 2: Set parameters
#-------> vivado_version
# the version should be dddd.d like 2018.2
# Note: 2018.2.1 is not accpetable
#-------> dcp_type
# the value can be:
# 1 => post_synth, post_opt
# 2 => post_place, post_phys_opt (after place_design)
# 3 => post_route, post_phys_opt (after route_design)
#-------> mode
# 1 => user defined mode
# 2 => default mode
# 3 => full mode
#-------> dcp_is_open
# 1 => dcp has been opend
# 0 => dcp is closed, and Open dcp first
########################################################
#########################################################################################
set total_start_time [clock format [clock seconds] -format "%s"]
source timing_analysis_pkg_v2019.1.tcl
#########################################################################################
#set parameters
#########################################################################################
set vivado_version 2019.1
set dcp_type       3
set dcp_is_open    0
set dcp_name       *routed.dcp
set mode           3
set is_accurate    1
set max_paths      10
#########################################################################################
# check vivado version
if {[regexp {20[12][0-9][.][1-4]$} $vivado_version]==0} {
  puts "Vivado version is not correct"
  return -code 1
}
#########################################################################################
set user_check_timing                   1
set user_timing_summary                 1
set user_neg_slack_timing               1
set user_block2block                    1
set user_high_logic_level               1
set user_crossing_slrs                  1
set user_get_cells_crossing_slrs        1
set user_check_bram                     1
set user_check_uram                     1
set user_check_dsp_mreg                 1
set user_check_dsp_preg                 1
set user_check_lower_srl                1
set user_check_combined_lut             1
set user_check_muxfx                    1
set user_check_latch                    1
set user_clock_characteristics          1
set user_clock_networks                 1
set user_cdc                            1
set user_clock_interaction              1
set user_congestion                     1
set user_exceptions                     1
set user_util                           1
set user_methodology                    1
set user_qor                            1
set user_failfast                       1
set user_high_fanout_nets               1
set user_ram_util                       1
set default_check_timing                1
set default_timing_summary              1
set default_neg_slack_timing            1
set default_block2block                 1
set default_high_logic_level            0
set default_crossing_slrs               1
set default_get_cells_crossing_slrs     0
set default_check_bram                  1
set default_check_uram                  1
set default_check_dsp_mreg              1
set default_check_dsp_preg              1
set default_check_lower_srl             0
set default_check_combined_lut          0
set default_check_muxfx                 0
set default_check_latch                 0
set default_clock_characteristics       0
set default_clock_networks              1
set default_cdc                         0
set default_clock_interaction           1
set default_congestion                  0
set default_exceptions                  0
set default_util                        0
set default_methodology                 1
set default_qor                         0
set default_failfast                    1
set default_high_fanout_nets            0
set default_ram_util                    1
#########################################################################################
# open dcp
if {$dcp_is_open==0} {
  set target_dcp [glob -nocomplain $dcp_name]
  set dcp_num [llength $target_dcp]
  if {$dcp_num==0} {
    puts "There is no DCP in current work directory"
    return -code 1
  } elseif {$dcp_num>1} {
    puts "Too many DCP files are found"
    return -code 1
  } else {
    set open_dcp_start_time [clock format [clock seconds] -format "%s"]
    open_checkpoint $target_dcp
    set open_dcp_end_time [clock format [clock seconds] -format "%s"]
  }
}
#########################################################################################
file mkdir Report
cd ./Report
#########################################################################################
# check whether dcp_type is reasonable
# check whether mode is reasonable
#########################################################################################
if {[regexp {[1-3]} $dcp_type] == 0} {
  puts "The range of dcp_type should be from 1 to 3."
  return -code 1
} else {
  puts "The variable dcp_type is reasonable. Move on."
}
if {[regexp {[1-3]} $mode] == 0} {
  puts "The range of mode should be from 1 to 3."
  return -code 1
} else {
  puts "The variable mode is reasonable. Move on."
}
#########################################################################################
# get exact check items
#########################################################################################
switch -exact $mode {
  1 {
     set en_check_timing            $user_check_timing
     set en_timing_summary          $user_timing_summary
     set en_neg_slack_timing        $user_neg_slack_timing
     set en_block2block             $user_block2block
     set en_high_logic_level        $user_high_logic_level
     set en_crossing_slrs           $user_crossing_slrs
     set en_get_cells_crossing_slrs $user_get_cells_crossing_slrs
     set en_check_bram              $user_check_bram
     set en_check_uram              $user_check_uram
     set en_check_dsp_mreg          $user_check_dsp_mreg
     set en_check_dsp_preg          $user_check_dsp_preg
     set en_check_lower_srl         $user_check_lower_srl
     set en_check_combined_lut      $user_check_combined_lut
     set en_check_muxfx             $user_check_muxfx
     set en_check_latch             $user_check_latch
     set en_clock_characteristics   $user_clock_characteristics
     set en_clock_networks          $user_clock_networks
     set en_cdc                     $user_cdc
     set en_clock_interaction       $user_clock_interaction
     set en_congestion              $user_congestion
     set en_exceptions              $user_exceptions
     set en_util                    $user_util
     set en_methodology             $user_methodology
     set en_qor                     $user_qor
     set en_failfast                $user_failfast
     set en_high_fanout_nets        $user_high_fanout_nets
     set en_ram_util                $user_ram_util
    }
  2 {
     set en_check_timing             $default_check_timing
     set en_timing_summary           $default_timing_summary
     set en_neg_slack_timing         $default_neg_slack_timing
     set en_block2block              $default_block2block
     set en_high_logic_level         $default_high_logic_level
     set en_crossing_slrs            $default_crossing_slrs
     set en_get_cells_crossing_slrs  $default_get_cells_crossing_slrs
     set en_check_bram               $default_check_bram
     set en_check_uram               $default_check_uram
     set en_check_dsp_mreg           $default_check_dsp_mreg
     set en_check_dsp_preg           $default_check_dsp_preg
     set en_check_lower_srl          $default_check_lower_srl
     set en_check_combined_lut       $default_check_combined_lut
     set en_check_muxfx              $default_check_muxfx
     set en_check_latch              $default_check_latch
     set en_clock_characteristics    $default_clock_characteristics
     set en_clock_networks           $default_clock_networks
     set en_cdc                      $default_cdc
     set en_clock_interaction        $default_clock_interaction
     set en_congestion               $default_congestion
     set en_exceptions               $default_exceptions
     set en_util                     $default_util
     set en_methodology              $default_methodology
     set en_qor                      $default_qor
     set en_failfast                 $default_failfast
     set en_high_fanout_nets         $default_high_fanout_nets
     set en_ram_util                 $default_ram_util
    }
  default {
     set en_check_timing            1
     set en_timing_summary          1
     set en_neg_slack_timing        1
     set en_block2block             1
     set en_high_logic_level        1
     set en_crossing_slrs           1
     set en_get_cells_crossing_slrs 1
     set en_check_bram              1
     set en_check_uram              1
     set en_check_dsp_mreg          1
     set en_check_dsp_preg          1
     set en_check_lower_srl         1
     set en_check_combined_lut      1
     set en_check_muxfx             1
     set en_check_latch             1
     set en_clock_characteristics   1
     set en_clock_networks          1
     set en_cdc                     1
     set en_clock_interaction       1
     set en_congestion              1
     set en_exceptions              1
     set en_util                    1
     set en_methodology             1
     set en_qor                     1
     set en_failfast                1
     set en_high_fanout_nets        1
     set en_ram_util                1
    }
}
#########################################################################################
#Get RAMB36E2, RAMB18E2, FIFO18E2, FIFO36E2
#########################################################################################
set 7_family   [list artix7 kintex7 virtex7 zynq]
set us_family  [list kintexu virtexu]
set usp_family [list kintexuplus virtexuplus zynquplus]
set x_part     [get_property PART [current_design]]
set x_family   [get_property C_FAMILY [get_parts $x_part]]
set x_speed    [get_property SPEED    [get_parts $x_part]]
set x_slrs     [get_property SLRS     [get_parts $x_part]]

if {$x_family in $7_family} {
  set bram_prim_type   "BMEM.*.*"
  set fifo_prim_type   "BMEM.*.*"
  set bram36_ref_name  "RAMB36E1"
  set bram18_ref_name  "RAMB18E1"
  set fifo36_ref_name  "FIFO36E1"
  set fifo18_ref_name  "FIFO18E1"
  set uram_ref_name    ""
  set dsp_ref_name     "DSP48E1"
  set ll_f             1
} elseif {$x_family in $us_family} {
  set bram_prim_type   "BLOCKRAM.BRAM.*"
  set fifo_prim_type   "BLOCKRAM.FIFO.*"
  set bram36_ref_name  "RAMB36E2"
  set bram18_ref_name  "RAMB18E2"
  set fifo36_ref_name  "FIFO36E2"
  set fifo18_ref_name  "FIFO18E2"
  set uram_ref_name    "URAM288"
  set dsp_ref_name     "DSP48E2"
  set ll_f             2
} elseif {$x_family in $usp_family} {
  set bram_prim_type   "BLOCKRAM.BRAM.*"
  set fifo_prim_type   "BLOCKRAM.FIFO.*"
  set bram36_ref_name  "RAMB36E2"
  set bram18_ref_name  "RAMB18E2"
  set fifo36_ref_name  "FIFO36E2"
  set fifo18_ref_name  "FIFO18E2"
  set uram_ref_name    "URAM288"
  set dsp_ref_name     "DSP48E2"
  set ll_f             3
} else {
  puts "The part number is not correct"
  return -code 1
}
# Get all clocks in the design
set clocks        [get_clocks]
set clock_num     [llength $clocks]
#Get all BRAM including FIFO
set used_bram [get_cells -hier -filter "PRIMITIVE_TYPE =~ $bram_prim_type || PRIMITIVE_TYPE =~ $fifo_prim_type" -quiet]
#Get all URAM
if {[llength $uram_ref_name]==1} {
  set used_uram [get_cells -hier -filter "REF_NAME == $uram_ref_name" -quiet]
} else {
  set used_uram {}
}
#Get all DSP cells
set used_dsp [get_cells -hier -filter "REF_NAME =~ $dsp_ref_name" -quiet]
#Get all GT cells
set gt_pattern {GT[PXYHM]E[234]_CHANNEL}
set used_gt [get_cells -hier -regexp -filter "REF_NAME =~ $gt_pattern" -quiet]
set used_bram_num [llength $used_bram]
set used_uram_num [llength $used_uram]
set used_dsp_num  [llength $used_dsp ]
set used_gt_num   [llength $used_gt  ]
puts "########################################
\t Part : $x_part \n \
\t BRAM : $used_bram_num \n \
\t URAM : $used_uram_num \n \
\t DSP  : $used_dsp_num \n \
\t GT   : $used_gt_num\n
########################################"

set used_blocks {}
if {$used_bram_num>0} {lappend used_blocks $used_bram}
if {$used_uram_num>0} {lappend used_blocks $used_uram}
if {$used_dsp_num>0 } {lappend used_blocks $used_dsp }
if {$used_gt_num>0  } {lappend used_blocks $used_gt  }

set used_blocks_num [llength $used_blocks]
puts "##################################################################################"
#########################################################################################
#Produce various analysis reports
#########################################################################################
#Section 01: check_timing
set i 1
set sn [timing_analysis::get_sn $i]
timing_analysis::my_check_timing $sn $en_check_timing
puts "##################################################################################"
#########################################################################################
#Section 02: report_timing_summary
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::my_timing_summary $sn $dcp_type $en_timing_summary
puts "##################################################################################"
#########################################################################################
#Section 03: report_timing: 100 negative slack paths
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::my_neg_slack_timing_report $sn $dcp_type $en_neg_slack_timing
puts "##################################################################################"
#########################################################################################
#Section 04: report_block2block: 100 paths from blocks to blocks
incr i
set sn [timing_analysis::get_sn $i]
if {$used_blocks_num>0} {
  timing_analysis::report_block2block $sn $used_blocks $en_block2block
} else {
  puts "There isn't any blocks used in current design"
}
puts "##################################################################################"
#########################################################################################
#Section 05: report_timing: paths with higher logic level
incr i
set sn [timing_analysis::get_sn $i]
set index $ll_f,$x_speed
set delay [timing_analysis::get_timing_base $index $is_accurate]
if {$clock_num>0} {
  foreach i_clocks $clocks {
    timing_analysis::report_high_logic_level $sn $i_clocks $delay $en_high_logic_level
  }
}
puts "##################################################################################"
#########################################################################################
#Section 06: report_paths_crossing_slrs
incr i
set sn [timing_analysis::get_sn $i]
if {$x_slrs>1} {
  timing_analysis::report_paths_crossing_slrs $sn $dcp_type $en_get_cells_crossing_slrs $en_crossing_slrs
}
puts "##################################################################################"
#########################################################################################
#Section 07: get_no_reg_bram
incr i
set sn [timing_analysis::get_sn $i]
if {$used_bram_num>1} {
  timing_analysis::get_no_reg_bram $sn $used_bram $en_check_bram
}
puts "##################################################################################"
#########################################################################################
#Section 08: get_no_reg_uram
incr i
set sn [timing_analysis::get_sn $i]
if {$used_uram_num>1} {
  timing_analysis::get_no_reg_uram $sn $used_uram $en_check_uram
}
puts "##################################################################################"
#########################################################################################
#Section 09: get_no_mreg_dsp
incr i
set sn [timing_analysis::get_sn $i]
if {$used_dsp_num>1} {
  timing_analysis::get_no_mreg_dsp $sn $used_dsp $en_check_dsp_mreg
}
puts "##################################################################################"
#########################################################################################
#Section 10: get_no_preg_dsp
incr i
set sn [timing_analysis::get_sn $i]
if {$used_dsp_num>1} {
  timing_analysis::get_no_preg_dsp $sn $used_dsp $en_check_dsp_preg
}
puts "##################################################################################"
#########################################################################################
#Section 11: get_lower_depth_srl
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::get_lower_depth_srl $sn $en_check_lower_srl
puts "##################################################################################"
#########################################################################################
#Section 12: get_combined_lut
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::get_combined_lut $sn $en_check_combined_lut
puts "##################################################################################"
#########################################################################################
#Section 13: get_muxfx
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::get_muxfx $sn $en_check_muxfx
puts "##################################################################################"
#########################################################################################
#Section 14: get_latch
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::get_latch $sn $en_check_latch
puts "##################################################################################"
#########################################################################################
#Section 15: report_clock_characteristics
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::report_clock_characteristics $sn $max_paths $en_clock_characteristics
puts "##################################################################################"
#########################################################################################
#Section 16: report_clock_networks
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::my_clock_networks $sn $en_clock_networks
puts "##################################################################################"
#########################################################################################
#Section 17: report_cdc
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::my_report_cdc $sn $en_cdc
puts "##################################################################################"
#########################################################################################
#Section 18: report_clock_interaction
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::my_clock_interaction $sn $en_clock_interaction
puts "##################################################################################"
#########################################################################################
#Section 19: report_congestion_level
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::report_congestion_level $sn $dcp_type $en_congestion
puts "##################################################################################"
#########################################################################################
#Section 20: report_exceptions
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::my_report_exceptions $sn $en_exceptions
puts "##################################################################################"
#########################################################################################
#Section 21: report_utilization
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::my_report_utilization $sn $en_util
puts "##################################################################################"
#########################################################################################
#Section 22: report_methodolgy
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::my_report_methodology $sn $en_methodology
puts "##################################################################################"
#########################################################################################
#Section 23: report_qor_suggestions
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::report_qor $sn $vivado_version $en_qor
puts "##################################################################################"
#########################################################################################
#Section 24: report_failfast
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::report_failfast $sn $x_slrs $dcp_type $en_failfast
puts "##################################################################################"
#########################################################################################
#Section 25: report_high_fanout_nets
incr i
set sn [timing_analysis::get_sn $i]
timing_analysis::high_fanout_nets $sn $x_slrs $dcp_type $en_high_fanout_nets
puts "##################################################################################"
#########################################################################################
#Section 26: report_ram_utilization
incr i
set sn [timing_analysis::get_sn $i]
if {$vivado_version>2018.2} {
  timing_analysis::my_ram_util $sn $en_ram_util
}
puts "##################################################################################"
#########################################################################################
set total_end_time [clock format [clock seconds] -format "%s"]
set total_elapse   [clock format [expr $total_end_time - $total_start_time] -format "%H:%M:%S" -gmt true]
#########################################################################################
if {$dcp_is_open==0} {
  set open_dcp_elapse [clock format [expr $open_dcp_end_time - $open_dcp_start_time] -format "%H:%M:%S" -gmt true]
  puts "#####Elapse (Open DCP): $open_dcp_elapse#####"
  puts "#####Total elapse (Open DCP + Analyze): $total_elapse#####"
} else {
  puts "#####Total elapse (Analyze): $total_elapse#####"
}
#########################################################################################


