##########################################################################################
#Author  : Lauren Gao
#Date    : 2017/11/13
#Company : Xilinx
#Description: Quickly position the potential risks in the design
##########################################################################################
#Version 2.0 -- Update logic level computing methods
#-------------- Add the option -fanout_greater_than for report_high_fanout_nets
#Version 3.0 -- Incorporate the logic level analysis for 7 series FPGAs
#---------------Optimize the scripts to reduce running time
#Version 4.0 -- Add option -timing to report_high_fanout_nets
#---------------Create clock utiliztion report
#Version 5.0 -- Find uram without opening OREG
#Version 6.0 -- Add index for each report
#---------------Add severity for each report: violated and analysis
#------------------violated: must be optimized; analysis: futher analysis is needed
#Version 7.0 -- Add the check of laguna registers utilization in each SLR
#---------------report_utilization -slr cannot report laguna regisers for each SLR
##########################################################################################
#Setcion 01:| Check timing and create timing summary report
#           | Resource utilization analysis
#           | Clock utilization analysis
#           | UFDM analysis
#Section 02:| Report QoR suggestions
#Section 03:| Logic level analysis
#Section 04:| Paths start at ff and end at the control pins of blocks (BRAM/UREAM/DSP)
#Section 05:| Paths start at Blocks like BRAM, URAM and DSP48 and end at FFs
#Section 06:| Paths ends at shift register
#Section 07:| Paths with Dedicated Blocks and Macro Primitives
#Section 08:| Clock skew analysis
#Section 09:| CDC analysis
#Section 10:| Control Set analysis
#Section 11:| Congestion level analysis
#Section 12:| Complexity analysis
#Section 13:|
#        13.1: DSP48 is used as multiplier without using MREG
#        13.2: DSP48 is used as MAC or Adder without using PREG
#Section 14:| BRAM is used without opening output register
#Section 15:| URAM is used without opening output register
#Section 16:| SRLs with lower depth
#Section 17:| LUT6 (combined LUT) utilization analysis
#Section 18:| MUXF utilization analysis
#Section 19:| Latch analysis
#Section 20:| Paths crossing SLR analysis(only for post-route dcp based on SSI device)
#Section 21:| High fanout nets analysis (ug949 table 3-1)
#Section 22:| Gated clocks analysis
#Section 23:| Constraints analysis
#Section 24:| Report laguna register utilization in each SLR
##########################################################################################
#When operated at VCCINT = 0.85V, using -2LE devices,
#the speed specification for the L devices is the same as the -2I speed grade.
#When operated at VCCINT = 0.72V, the -2LE performance and static and dynamic power is reduced.
##########################################################################################
#Sub procs
##########################################################################################
#The lowest power -1L and -2L devices, where VCCINT = 0.72V, are listed in the Vivado Design Suite as -1LV and -2LV
#respectively (DS922, page 17)

##########################################################################################
source timing_analysis_pkg_v7.tcl
##########################################################################################
# Modify parameters below according to your requirements
##########################################################################################
## mode : 0 : default -- baselining
##        1 : user_defined
##        2 : full (all items listed above will be done)
set mode 2
array set baseline {}
array set user_defined {}
array set full {}
array set really_done {}

timing_analysis::check_array baseline
timing_analysis::check_array user_defined
timing_analysis::check_array full
timing_analysis::check_array really_done

array set baseline {
  s01_check_timing         0
  s02_qor_sugest           0
  s03_logic_level          0
  s04_ff2block_ctrl        0
  s05_paths_start_blocks   0
  s06_paths_end_srl        0
  s07_paths_between_blocks 0
  s08_clock_skew           0
  s09_cdc                  1
  s10_ctrl_set             1
  s11_cong_level           0
  s12_complexity           0
  s13_dsp_reg              1
  s14_bram_reg             1
  s15_uram_reg             1
  s16_lower_srl            0
  s17_combined_lut         0
  s18_muxf                 0
  s19_latch                0
  s20_paths_crossing_slr   1
  s21_high_fanout_nets     1
  s22_gated_clock          0
  s23_constraints          0
  s24_laguna_reg_util      0
}

array set user_defined {
  s01_check_timing         0
  s02_qor_sugest           0
  s03_logic_level          0
  s04_ff2block_ctrl        0
  s05_paths_start_blocks   0
  s06_paths_end_srl        0
  s07_paths_between_blocks 0
  s08_clock_skew           0
  s09_cdc                  0
  s10_ctrl_set             0
  s11_cong_level           0
  s12_complexity           0
  s13_dsp_reg              0
  s14_bram_reg             1
  s15_uram_reg             0
  s16_lower_srl            0
  s17_combined_lut         0
  s18_muxf                 0
  s19_latch                0
  s20_paths_crossing_slr   0
  s21_high_fanout_nets     0
  s22_gated_clock          0
  s23_constraints          0
  s24_laguna_reg_util      0
}

array set full {
  s01_check_timing         1
  s02_qor_sugest           1
  s03_logic_level          1
  s04_ff2block_ctrl        1
  s05_paths_start_blocks   1
  s06_paths_end_srl        1
  s07_paths_between_blocks 1
  s08_clock_skew           1
  s09_cdc                  1
  s10_ctrl_set             1
  s11_cong_level           1
  s12_complexity           1
  s13_dsp_reg              1
  s14_bram_reg             1
  s15_uram_reg             1
  s16_lower_srl            1
  s17_combined_lut         1
  s18_muxf                 1
  s19_latch                1
  s20_paths_crossing_slr   1
  s21_high_fanout_nets     1
  s22_gated_clock          1
  s23_constraints          1
  s24_laguna_reg_util      1
}

switch -exact -- $mode {
  0 { timing_analysis::copy_array baseline really_done }
  1 { timing_analysis::copy_array user_defined really_done }
  2 { timing_analysis::copy_array full really_done }
  default { timing_analysis::copy_array baseline really_done }
}
##########################################################################################
set dcp_is_open 0
## if dcp is open, it is unnecessary to set the dcp_name
set dcp_name top_opt.dcp
## opt_design 1, otherwise 0
set is_opt_design 1
##########################################################################################
set max_paths_neg_slack     100
set max_paths_logic_level   100
set max_paths_ff2block      100
set ff2block_target_fanout  8
set ff2block_freq           300
set logic_level_clk_freq    125
set max_paths_bram2ff       100
set max_paths_uram2ff       100
set max_paths_dsp2ff        100
set max_paths_end_srl       100
set max_paths_block2block   100
set max_paths_mmcmi2o       100
set max_paths_mmcmo2i       100
set combined_lut6_util      0.20
set used_muxfs_util         0.15
set high_fanout_num         100
set fanout_greater_than     200
set max_paths_crossing_slrs 10000
##########################################################################################
# Please DO NOT change the code below
##########################################################################################
if {$dcp_is_open == 0} {
  set target_dcp [glob $dcp_name]
  set is_target_dcp [file exists $target_dcp]
  if {$is_target_dcp == 0} {
    puts "File does not exist!"
    return -code 1
  } else {
    puts "The target dcp is $dcp_name: continue..."
  }
} else {
  puts "The dcp has been open: continue..."
}
#Open DCP
##########################################################################################
if {$dcp_is_open == 0} {
  set start_open_dcp [clock format [clock seconds] -format "%s"]
  open_checkpoint [glob $dcp_name]
  set end_open_dcp [clock format [clock seconds] -format "%s"]
  set open_dcp_elapse [clock format [expr $end_open_dcp - $start_open_dcp] -format "%H:%M:%S" -gmt true]
} else {
  set end_open_dcp [clock format [clock seconds] -format "%s"]
  set open_dcp_elapse 0
}
##########################################################################################
#Basic information about target part
##########################################################################################
set part   [get_property PART         [current_design]]
set family [get_property FAMILY       [get_parts $part]]
set speed  [get_property SPEED        [get_parts $part]]
set slrs   [get_property SLRS         [get_parts $part]]
set brams  [get_property BLOCK_RAMS   [get_parts $part]]
set dsps   [get_property DSP          [get_parts $part]]
set ffs    [get_property FLIPFLOPS    [get_parts $part]]
set luts   [get_property LUT_ELEMENTS [get_parts $part]]
set slices [get_property SLICES       [get_parts $part]]
set urams  [get_property ULTRA_RAMS   [get_parts $part]]

file mkdir rpt
cd ./rpt
##########################################################################################
#Resources used in current design
##########################################################################################
#set bram_ref_name [list RAMB36E2 RAMB18E2 FIFO36E2 FIFO18E2]
set used_bram36 [get_cells -hier -filter "REF_NAME == RAMB36E2"]
set used_bram18 [get_cells -hier -filter "REF_NAME == RAMB18E2"]
set used_fifo36 [get_cells -hier -filter "REF_NAME == FIFO36E2"]
set used_fifo18 [get_cells -hier -filter "REF_NAME == FIFO18E2"]
set used_bramx  [concat $used_bram36 $used_bram18]
set used_fifox  [concat $used_fifo36 $used_fifo18]
set used_brams  [concat $used_bramx  $used_fifox ]
set used_dsps [get_cells -hier -filter "REF_NAME =~ DSP48*" -quiet]
set used_gts  [get_cells -hier -filter "REF_NAME =~ GT*_CHANNEL" -quiet]
set used_ffs  [get_cells -hier -filter "PRIMITIVE_SUBGROUP == SDR" -quiet]
##########################################################################################
#Section 01:
## 1.1 check timing                  -- violated
## 1.2 get paths with negative slack -- violated
## 1.3 report utilization            -- analysis
## 1.4 report clock utilization      -- analysis
## 1.5 report ufdm                   -- analysis
##----------------------------------------------------------------------------------------
## 1.1 check timing-- violated
##----------------------------------------------------------------------------------------
set section_index 1
set sub_section_index 1
set severity "violated"
if { $really_done(s01_check_timing) == 1 } {
  set check_table [list \
    "constant_clock" \
    "generated_clocks" \
    "latch_loops" \
    "loops" \
    "multiple_clock" \
    "no_clock"
    ]
  set check_rpt [list]
  set critical_info [list]
  set true_section [timing_analysis::double_digits $section_index]
  set child_index 1
  foreach i_check_table $check_table {
    set check_rpt [split [check_timing -no_header -override_defaults \
    $i_check_table -return_string] \n]
    set check_key_word_index [lsearch -regexp -all $check_rpt {There are *}]
    foreach i_check_key_word_index $check_key_word_index {
      set target_sentence [lindex $check_rpt $i_check_key_word_index]
      set target_num [lindex $target_sentence 2]
      if {$target_num > 0} {
        lappend critical_info $target_sentence
      }
    }
    if {[llength $critical_info] > 0} {
      set fn ${true_section}.${sub_section_index}.${child_index}_${i_check_table}_${severity}
      set fid [open $fn.rpt w]
      foreach i_critical_info $critical_info {
        puts $fid $i_critical_info
      }
      close $fid
      set critical_info [list]
    }
    incr child_index
    set mesg "${true_section}.${sub_section_index}.${child_index} : the check of $i_check_table is done!"
    timing_analysis::print_successful_message $mesg
  }
  incr sub_section_index
  unset severity
  ##----------------------------------------------------------------------------------------
  ## 1.2 get paths with negative slack -- violated
  ##----------------------------------------------------------------------------------------
  #report_clock_networks -name clk_networks -file clk_networks.rpt
  #report_timing_summary -name timing_summary -file timing_summary.rpt
  set severity "violated"
  set neg_slack_paths [get_timing_paths -max $max_paths_neg_slack \
      -slack_lesser_than 0 -unique_pins]
  if {[llength $neg_slack_paths] > 0} {
    set fn ${true_section}.${sub_section_index}_neg_slack_paths_${severity}
    timing_analysis::report_critical_path $fn $neg_slack_paths
    report_timing -of $neg_slack_paths -name neg_slack_paths
  }
  set mesg "${true_section}.${sub_section_index} : Getting paths with negative slack is done!"
  timing_analysis::print_successful_message $mesg
  incr sub_section_index
  unset severity
  ##----------------------------------------------------------------------------------------
  ## 1.3 report utilization -- analysis
  ##----------------------------------------------------------------------------------------
  set severity "analysis"
  set fn ${true_section}.${sub_section_index}_util_${severity}.rpt
  if {$slrs > 1} {
    report_utilization -slr -file $fn
  } else {
    report_utilization -name util -file $fn
  }
  set mesg "${true_section}.${sub_section_index} : report_utilization is done!"
  timing_analysis::print_successful_message $mesg
  incr sub_section_index
  unset severity
  ##----------------------------------------------------------------------------------------
  ## 1.4 report clock utilization -- analysis
  ##----------------------------------------------------------------------------------------
  set severity "analysis"
  set fn ${true_section}.${sub_section_index}_clk_util_${severity}.rpt
  report_clock_utilization -name clkutil -file $fn
  set mesg "${true_section}.${sub_section_index} : report_clock_utilization is done!"
  timing_analysis::print_successful_message $mesg
  incr sub_section_index
  unset severity
  ##----------------------------------------------------------------------------------------
  ## 1.5 report ufdm -- analysis
  ##----------------------------------------------------------------------------------------
  set severity "analysis"
  set fn ${true_section}.${sub_section_index}_ufdm_${severity}.rpt
  report_methodology -name ufdm -file $fn
  set mesg "${true_section}.${sub_section_index} : UFDM check is done!"
  timing_analysis::print_successful_message $mesg
  set mesg "$true_section : checking timing is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 02: Report QoR suggestions -- analysis
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s02_qor_sugest) == 1 } {
  set folder ${true_section}_qor_${severity}
  file mkdir $folder
  report_qor_suggestions -output_dir ./$folder
  set mesg "$true_section : report_qor_suggestions is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 03: Logic level analysis -- violated
##########################################################################################
set severity "violated"
set sub_section_index 1
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s03_logic_level) == 1 } {
  set target_clk_period [expr 1.0 / $logic_level_clk_freq * 1000.0]
  set current_clk [get_clocks -filter "PERIOD <= $target_clk_period"]
  foreach current_clk_i $current_clk {
    set period [get_property PERIOD [get_clocks $current_clk_i]]
    set freq [format "%.3f" [expr 1.0/$period*1000]]
    set max_logic_level [timing_analysis::get_max_logic_level $family $freq]
    if {[string equal $max_logic_level "NaN"] != 1} {
      set paths [get_timing_paths -max_paths $max_paths_logic_level \
                 -filter "LOGIC_LEVELS > $max_logic_level && GROUP == $current_clk_i" -quiet]
      if {[llength $paths] > 0} {
        set timing_rpt_name ${true_section}_${current_clk_i}_${freq}MHz_LL_g_${max_logic_level}_${severity}
        report_timing -of $paths -name $timing_rpt_name
        timing_analysis::report_critical_path $timing_rpt_name $paths
        incr sub_section_index
      }
    }
  }
  set mesg "$true_section : Logic level check is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 04: Paths start at ff and end at the control pins of blocks (BRAM/UREAM/DSP)
#Control pins: addr, ce, en, byte_enable, rst, cas
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s04_ff2block_ctrl) == 1 } {
  set sub_section_index 1
  set ff2block_ctrl_path         [list]
  set ff2block_ctrl_path_LL_0    [list]
  set ff2block_ctrl_path_LL_g_0  [list]
  set ultrascale_plus [list virtexuplus kintexuplus zynquplus azynquplus]
  if {[lsearch $ultrascale_plus $family] != -1} {
    set used_urams [get_cells -hier -filter "PRIMITIVE_SUBGROUP == URAM" -quiet]
    set used_urams_num [llength $used_urams]
  } else {
    set used_urams [list]
    set used_urams_num 0
  }
  set used_blocks [list]
  set used_brams_num [llength $used_brams]
  set used_dsps_num [llength $used_dsps]
  set block_type [list]
  if {$used_brams_num > 0} {
    lappend used_blocks $used_brams
    lappend block_type bram
  } elseif {$used_dsps_num > 0} {
    lappend used_blocks $used_dsps
    lappend block_type dsp
  } elseif {$used_urams_num > 0} {
    lappend used_blocks $used_urams
    lappend block_type uram
  }
  #set target_clk_period [expr 1.0 / $ff2ctrl_block_clk_freq * 1000.0]
  #set current_clk [get_clocks -filter "PERIOD <= $target_clk_period"]
  if {[llength $used_blocks] > 0} {
    foreach current_clk_i $current_clk {
      set period [get_property PERIOD [get_clocks $current_clk_i]]
      set freq [format "%.2f" [expr 1.0/$period*1000]]
      if {$freq >= $ff2block_freq} {
        foreach used_blocks_i $used_blocks block_type_i $block_type {
          set ff2block_ctrl_path \
          [timing_analysis::get_ff2block_paths $current_clk_i $ff2block_target_fanout $used_ffs $used_blocks_i $max_paths_ff2block]
          set ff2block_ctrl_path_LL_0   [lindex $ff2block_ctrl_path 0]
          set ff2block_ctrl_path_LL_g_0 [lindex $ff2block_ctrl_path 1]
          if {[llength $ff2block_ctrl_path_LL_0] > 0} {
            set ff2block_ctrl_path_name ${current_clk_i}_${freq}MHz_ff2${block_type_i}_ctrl_path_LL_0
            report_design_analysis -of_timing_paths $ff2block_ctrl_path_LL_0 -name $ff2block_ctrl_path_name
            set fn ${true_section}.1_${ff2block_ctrl_path_name}_${severity}
            timing_analysis::report_critical_path $fn $ff2block_ctrl_path_LL_0
            incr sub_section_index
          }
          if {[llength $ff2block_ctrl_path_LL_g_0] > 0} {
            set ff2block_ctrl_path_LL_g_name ${current_clk_i}_${freq}MHz_ff2${block_type_i}_ctrl_path_LL_g_0
            report_design_analysis -of_timing_paths $ff2block_ctrl_path_LL_g_0 -name $ff2block_ctrl_path_LL_g_name
            set fn ${true_section}.2_${ff2block_ctrl_path_LL_g_name}_${severity}
            timing_analysis::report_critical_path $fn $ff2block_ctrl_path_LL_g_0
            incr sub_section_index
          }
        }
      }
    }
  }
  set mesg "$true_section : the check of paths from FF to the control pins of Blocks is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 05: Paths start at Blocks like BRAM, URAM and DSP48 and end at FFs -- analysis
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s05_paths_start_blocks) == 1 } {
  set sub_section_index 1
  if {[llength $used_brams] > 0} {
    set bram2ff_path [get_timing_paths -from $used_brams -max $max_paths_bram2ff -nworst 1 -unique_pins -quiet]
    if {[llength $bram2ff_path] > 0} {
      report_design_analysis -of_timing_paths $bram2ff_path -name bram2ff_paths
      set fn ${true_section}.${sub_section_index}_bram2ff_${severity}
      timing_analysis::report_critical_path $fn $bram2ff_path
    }
  }
  set mesg "${true_section}.${sub_section_index} : the check of paths from BRAMs to FF is done!"
  timing_analysis::print_successful_message $mesg
  incr sub_section_index

  if {[llength $used_dsps] > 0} {
    set dsp2ff_path [get_timing_paths -from $used_dsps -max $max_paths_dsp2ff -nworst 1 -unique_pins -quiet]
    if {[llength $dsp2ff_path] > 0} {
      report_design_analysis -of_timing_paths $dsp2ff_path -name dsp2ff_paths
      set fn ${true_section}.${sub_section_index}_dsp2ff_${severity}
      timing_analysis::report_critical_path $fn $dsp2ff_path
    }
  }
  set mesg "${true_section}.${sub_section_index} : the check of paths from DSP48s to FF is done!"
  timing_analysis::print_successful_message $mesg
  incr sub_section_index

  if {[lsearch $ultrascale_plus $family] != -1} {
    if {$used_urams_num > 0} {
      set uram2ff_path [get_timing_paths -from $used_urams -max $max_paths_uram2ff -nworst 1 -unique_pins -quiet]
      if {[llength $uram2ff_path] > 0} {
        report_design_analysis -of_timing_paths $uram2ff_path -name uram2ff_paths
        set fn ${true_section}.${sub_section_index}_uram2ff_${severity}
        timing_analysis::report_critical_path $fn $uram2ff_path
      }
    }
  }
  set mesg "${true_section}.${sub_section_index} : the check of paths from URAMs to FF is done!"
  timing_analysis::print_successful_message $mesg

  set mesg "$true_section : the check of paths from Blocks to FF is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 06: Paths ends at shift register -- analysis
#ug949 -> C5 -> Analyzing and Resolving -> Reducing logic delay | page 207
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s06_paths_end_srl) == 1 } {
  set srl [get_cells -hier -filter {IS_PRIMITIVE && REF_NAME =~ SRL*} -quiet]
  if {[llength $srl] > 0} {
    set paths_end_srl [get_timing_paths -to $srl -max_paths $max_paths_end_srl -quiet]
  } else {
    set paths_end_srl [list]
  }

  if {[llength $paths_end_srl] > 0} {
    report_timing -of $paths_end_srl -name paths_end_srl
    set fn ${true_section}_paths_end_srl_${severity}
    timing_analysis::report_critical_path $fn $paths_end_srl
  }

  set mesg "$true_section : the check of paths ending at SRL is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 07: Paths with Dedicated Blocks and Macro Primitives -- violated
#ug949 -> C5 -> Analyzing and Resolving -> Reducing logic delay | page 208
##########################################################################################
set severity "violated"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s07_paths_between_blocks) == 1 } {
  set used_gts_num [llength $used_gts]
  if {$used_gts_num > 0} {lappend used_blocks $used_gts}
  set paths_block2block [get_timing_paths -from $used_blocks -to $used_blocks -max_paths $max_paths_block2block -quiet]
  if {[llength $paths_block2block] > 0} {
    report_timing -of $paths_block2block -name paths_block2block
    set fn ${true_section}_paths_block2block_${severity}
    timing_analysis::report_critical_path $fn $paths_block2block
  }

  set mesg "$true_section : the check of paths between dedicated blocks is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 08: Clock skew analysis -- analysis
#Ug949 -> C5 -> Analyzing and Resolving -> Reducing Clock Skew | page 218
#Scenario 1:
#Synchronous CDC Paths with Common Nodes on Input and Output of a MMCM
#clkin ---> BUFGCE --Disable LUT Combining and MUXF Inference--------> FF | Synchronous Elements
#                   |                                          ^   .
#                   |                                          |   |
#                   |                                          .   ^
#                   |-> CLKIN1 --> MMCM --> BUFGCE --> FF | Synchronous Elements
#Solution:
#(1) Xilinx recommends limiting the number of synchronous clock domain crossing paths even
#    when clock skew is acceptable
#(2) Also, when skew is abnormally high and cannot be reduced, Xilinx recommends treating
#    these paths as asynchronous by implementing asynchronous clock domain crossing
#    circuitry and adding timing exceptions
##########################################################################################
set severity "violated"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s08_clock_skew) == 1 } {
  set sub_section 1
  set used_clk_module [get_cells -hier -filter "PRIMITIVE_SUBGROUP == PLL" -quiet]
  if {[llength $used_clk_module] > 0} {
    foreach used_clk_module_i $used_clk_module {
      set clkin_pin [get_pins -of $used_clk_module_i -filter "REF_PIN_NAME == CLKIN1"]
      set clkin [get_clocks -of $clkin_pin]
      set clkout_pin [get_pins -of $used_clk_module_i -filter "IS_CONNECTED == 1 && REF_PIN_NAME =~ CLKOUT*"]
      foreach clkout_pin_i $clkout_pin {
        set clkout [get_clocks -of $clkout_pin_i]
        set path_mmcmi2o [get_timing_paths -from $clkin -to $clkout -max_paths $max_paths_mmcmi2o -quiet]
        set path_mmcmo2i [get_timing_paths -from $clkout -to $clkin -max_paths $max_paths_mmcmo2i -quiet]
        set path_mmcmio [concat $path_mmcmi2o $path_mmcmo2i]
        if {[llength $path_mmcmio] > 0} {
          report_timing -of $path_mmcmio -name paths_${clkin}_Between_${clkout}
          set fn ${true_section}_paths_${clkin}_between_${clkout}
          timing_analysis::report_critical_path $fn $path_mmcmio
        }
      }
    }
  }

  set mesg "$true_section : clock skew analysis is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 09: CDC analysis
##########################################################################################
#report_clock_interaction -name clk_inter -file clk_inter.rpt
set severity "violated"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s09_cdc) == 1 } {
  set fn ${true_section}_cdc_${severity}
  report_cdc -no_header -severity {Critical} -name cdc -file ${fn}.rpt

  set mesg "$true_section : the check of CDC paths is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 10: Control Set analysis
#Guidelines: ug949 Table 5-9
#Solution:
#(1) Remove the MAX_FANOUT attributes that are set on control signals in the HDL sources
#or constraint files. Replication on control signals will dramatically increase the number
#of unique control sets. Xilinx recommends manual replication based on hierarchy in the
#RTL, where replicated drivers are preserved with a KEEP attribute.
#(2) Increase the control set threshold of Vivado synthesis (or other FPGA synthesis tool).
#For example: synth_design -control_set_opt_threshold 16
#(3) Avoid low fanout asynchronous set/reset (preset/clear), as they can only be connected
#to dedicated asynchronous pins and cannot be moved to the datapath by synthesis. For
#this reason, the synthesis control set threshold option does not apply to asynchronous
#set/reset.
#(4) Avoid using both active high and low of a control signal for different sequential cells.
#(5) Only use clock enable and set/reset when necessary.
##########################################################################################
set severity ""
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s10_ctrl_set) == 1 } {
  set ctrl_set_rpt [report_control_sets -return_string]
  puts $ctrl_set_rpt
  set ctrl_set_rpt_new  [split $ctrl_set_rpt \n]
  set target [lsearch -all -regexp $ctrl_set_rpt_new {Number of unique control sets}]
  puts [lindex $ctrl_set_rpt_new $target]
  set target_line [lindex $ctrl_set_rpt_new $target]
  set uni_ctrl_sets [regexp -inline -all {[0-9]+} $target_line]
  set uni_percentage [expr double($uni_ctrl_sets) / double($slices)]
  set uni_pf [format "%.3f" $uni_percentage]
  set uni_ph [format "%.1f" [expr $uni_pf*100]]%
  if {$uni_pf <= 0.075} {
    puts "Number of unique control sets: $uni_ctrl_sets --> $uni_ph --> Acceptable"
  } elseif {$uni_pf > 0.075 && $uni_pf < 0.15} {
    #set ctrl_set_fid [open ./ctrl_set.rpt w]
    #puts $ctrl_set_fid \
    #"Number of unique control sets: $uni_ctrl_sets --> $uni_ph --> Noted"
    puts "Number of unique control sets: $uni_ctrl_sets --> $uni_ph --> Noted"
  } elseif {$uni_pf >= 0.15 && $uni_pf < 0.25} {
    puts "Number of unique control sets: $uni_ctrl_sets --> $uni_ph --> Analysis Required"
    set fn ${true_section}_ctrl_set_analysis
    set ctrl_set_fid [open ./${fn}.rpt w]
    puts $ctrl_set_fid \
    "Number of unique control sets: $uni_ctrl_sets --> $uni_ph --> Analysis Required"
    close $ctrl_set_fid
  } else {
    puts "Number of unique control sets: $uni_ctrl_sets --> $uni_ph --> Recommended Design Change"
    set fn ${true_section}_ctrl_set_violated
    set ctrl_set_fid [open ./${fn}.rpt w]
    puts $ctrl_set_fid "Number of unique control sets: $uni_ctrl_sets --> $uni_ph --> Recommended Design Change"
    close $ctrl_set_fid
  }
  set mesg "$true_section : the check of control set is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 11: Congestion level analysis
#ug949 -> C5 -> Analyzing and Resolving -> Reducing Net delay | page 209
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s11_cong_level) == 1 } {
  set fn ${true_section}_congestion_${severity}
  report_design_analysis -congestion -name cong_level -file ${fn}.rpt

  set mesg "$true_section : the check of congestion level is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 12: Complexity analysis
#ug949 -> C5 -> Analyzing and Resolving -> Reducing Net delay | page 214
#The Complexity Report shows the Rent Exponent, Average Fanout, and distribution per type
#of leaf cells for the top-level and/or for hierarchical cells. The Rent exponent is the
#relationship between the number of ports and the number of cells of a netlist partition
#when recursively partitioning the design with a min-cut algorithm
#Use the -hierarchical_depth option to refine the analysis to include the lower-level modules
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s12_complexity) == 1 } {
  set fn ${true_section}_complexity_${severity}
  report_design_analysis -complexity -name complexity_rpt -file ${fn}.rpt

  set mesg "$true_section : the check of complexity is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 13.1: DSP48 is used as multiplier without using MREG
#Section 13.2: DSP48 is used as MAC or Adder without using PREG
##########################################################################################
set severity "violated"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s13_dsp_reg) == 1 } {
  set sub_section 1
  set dsp48_no_mreg [filter $used_dsps {USE_MULT != NONE && MREG == 0}]
  set dsp48_no_mreg_num [llength $dsp48_no_mreg]
  if {$dsp48_no_mreg_num > 0} {
    show_objects -name dsp48_no_mreg -object $dsp48_no_mreg
    set fn ${true_section}.${sub_section}_dsp48_no_mreg_${severity}
    timing_analysis::report_target_cell $fn $dsp48_no_mreg
  }
  incr sub_section

  set mesg "$true_section.$sub_section : the check of DSP48 without MREG is done!"
  timing_analysis::print_successful_message $mesg
  ##---------------------------------------------------------------------------------------
  set dsp48_no_preg [filter $used_dsps "PREG == 0"]
  set dsp48_no_preg_num [llength $dsp48_no_preg]
  if {$dsp48_no_preg_num > 0} {
    show_objects -name dsp48_no_preg -object $dsp48_no_preg
    set fn ${true_section}.${sub_section}_dsp48_no_preg_${severity}
    timing_analysis::report_target_cell $fn $dsp48_no_preg
  }

  set mesg "$true_section.$sub_section : the check of DSP48 without PREG is done!"
  timing_analysis::print_successful_message $mesg

  set mesg "$true_section : the check of DSP48 is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 14.1: BRAM is used without opening output register
#Section 14.2: FIFO is used without opening output register
##########################################################################################
set severity "violated"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s14_bram_reg) == 1 } {
  set sub_section 1
  if {[llength $used_bramx] > 0} {
    set bram_no_reg [list]
    set fn ${true_section}.${sub_section}_bram_no_reg_${severity}
    set fid [open ${fn}.csv w]
    puts $fid "#\n# File created on [clock format [clock seconds]] \n#\n"
    puts $fid "BRAM, CLKA, CLKA_FREQ, CLKB, CLKB_FREQ, DOA_REG, DOA_CONNECTED, DOB_REG, DOB_CONNECTED"
    foreach used_bram_i $used_bramx {
      set douta_pin [get_pins -of [get_cells $used_bram_i] -filter "NAME =~ *DOUTADOUT* || NAME =~ *DOADO*"]
      set doutb_pin [get_pins -of [get_cells $used_bram_i] -filter "NAME =~ *DOUTBDOUT* || NAME =~ *DOBDO*"]
      set clka_pin  [get_pins -of [get_cells $used_bram_i] -filter "NAME =~ *CLKARDCLK*"]
      set clkb_pin  [get_pins -of [get_cells $used_bram_i] -filter "NAME =~ *CLKBWRCLK*"]
      set clka_net  [get_nets -of $clka_pin]
      set clkb_net  [get_nets -of $clkb_pin]
      if {[get_property TYPE $clka_net] == "GLOBAL_CLOCK"} {
        set clka [get_clocks -of $clka_pin]
        if {[llength $clka] == 1} {
          set clka_period [get_property PERIOD $clka]
          set clka_period [lindex [timing_analysis::get_max_min $clka_period] end]
          set clka_freq [format "%.2f" [expr 1.0/$clka_period*1000]]
        } else {
          set clka_period "NaN"
          set clka_freq "NaN"
        }
      } else {
        set clka_freq 0
      }
      if {[get_property TYPE $clkb_net] == "GLOBAL_CLOCK"} {
        set clkb [get_clocks -of $clkb_pin]
        if {[llength $clkb] == 1} {
          set clkb_period [get_property PERIOD $clkb]
          set clkb_period [lindex [timing_analysis::get_max_min $clkb_period] end]
          set clkb_freq [format "%.2f" [expr 1.0/$clkb_period*1000]]
        } else {
          set clkb_period "NaN"
          set clkb_freq "NaN"
        }
      } else {
        set clkb_freq 0
      }
      set doa_reg [get_property DOA_REG $used_bram_i]
      set dob_reg [get_property DOB_REG $used_bram_i]
      set douta_pin_status [timing_analysis::get_max_min [get_property IS_CONNECTED $douta_pin]]
      set douta_pin_connect [lindex $douta_pin_status 0]
      set doutb_pin_status [timing_analysis::get_max_min [get_property IS_CONNECTED $doutb_pin]]
      set doutb_pin_connect [lindex $doutb_pin_status 0]
      if {($douta_pin_connect == 1 && $doa_reg == 0) || ($doutb_pin_connect == 1 && $dob_reg == 0)} {
        puts $fid "$used_bram_i, $clka, $clka_freq, $clkb, $clkb_freq, $doa_reg, $douta_pin_connect, \
        $dob_reg, $doutb_pin_connect"
        lappend bram_no_reg $used_bram_i
      }
    }
    close $fid
    if {[llength $bram_no_reg] > 0} {
      show_objects -name bram_no_reg -object $bram_no_reg
    }
  }

  set mesg "$true_section.$sub_section : the check of BRAM without output registers is done!"
  timing_analysis::print_successful_message $mesg
  incr sub_section

  if {[llength $used_fifox] > 0} {
    set fifo_no_reg [filter $used_fifox "REGISTER_MODE == UNREGISTERED"]
    if {[llength $fifo_no_reg] > 0} {
      set fn ${true_section}.${sub_section}_fifo_no_reg_${severity}
      set fid [open ${fn}.rpt w]
      foreach i_fifo_no_reg $fifo_no_reg {
        puts $fid $i_fifo_no_reg
      }
      close $fid
    }
  }

  set mesg "$true_section.$sub_section : the check of FIFO without output registers is done!"
  timing_analysis::print_successful_message $mesg

  set mesg "$true_section : the check of BRAM/FIFO is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index

##########################################################################################
#Section 15:URAMs without OREG
##########################################################################################
set severity "violated"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s15_uram_reg) == 1 } {
  if {[lsearch $ultrascale_plus $family] != -1} {
    set cas_urams [get_cells -hier -filter {PRIMITIVE_SUBGROUP == URAM && \
      NUM_URAM_IN_MATRIX > 1 && (CASCADE_ORDER_A == "LAST" || CASCADE_ORDER__B == "LAST")} -quiet]
    set single_urams [get_cells -hier -filter "PRIMITIVE_SUBGROUP == URAM && NUM_URAM_IN_MATRIX == 1" -quiet]
    set cas_urams_num [llength $cas_urams]
    set single_urams_num [llength $single_urams]
    if {$cas_urams_num > 0 && $single_urams_num > 0} {
      set used_urams [concat $cas_urams $single_urams]
    } elseif {$cas_urams_num > 0} {
      set used_urams $cas_urams
    } elseif {$single_urams_num > 0} {
      set used_urams $single_urams
    } else {
      set used_urams [list]
    }
  }
  if {[llength $used_urams] > 0} {
    set fn ${true_section}_uram_no_reg_${severity}
    set fid [open $fn.csv w]
    puts $fid "#\n# File created on [clock format [clock seconds]] \n#\n"
    puts $fid "URAM, CLK, CLK_FREQ, DOUT_A_REG, DOUT_A_CONNECTED, DOUT_B_REG, DOUT_B_CONNECTED"
    set uram_no_reg [list]
    set uram_dout_a_connect [list]
    set uram_dout_a_no_reg [list]
    set uram_dout_b_connect [list]
    set uram_dout_b_no_reg [list]
    set uram_freq [list]
    foreach i_used_urams $used_urams {
      set uram_clk_pin [get_pins -of [get_cells $i_used_urams] -filter "NAME =~ */CLK"]
      set uram_clk_period [get_property PERIOD [get_clocks -of $uram_clk_pin]]
      set uram_clk_freq [format "%.2f" [expr 1.0/$uram_clk_period*1000]]
      set dout_a [get_pins -of $i_used_urams -filter "NAME =~ */DOUT_A[*]"]
      set dout_a_connect [get_property IS_CONNECTED $dout_a]
      set is_dout_a_connect [lsearch $dout_a_connect 1]
      set oreg_a [get_property OREG_A $i_used_urams]
      set dout_b [get_pins -of $i_used_urams -filter "NAME =~ */DOUT_B[*]"]
      set dout_b_connect [get_property IS_CONNECTED $dout_b]
      set is_dout_b_connect [lsearch $dout_b_connect 1]
      set oreg_b [get_property OREG_B $i_used_urams]
      set oreg_a_f [string equal $oreg_a "FALSE"]
      set oreg_b_f [string equal $oreg_b "FALSE"]
      if {($is_dout_a_connect != -1 && $oreg_a_f == 1) || ($is_dout_b_connect != -1 && $oreg_b_f == 1)} {
        puts $fid "$i_used_urams, $uram_clk_pin, $uram_clk_freq, $oreg_a, $is_dout_a_connect,\
        $oreg_b, $is_dout_b_connect"
        lappend uram_no_reg $i_used_urams
      }
    }
    close $fid
    if {[llength $uram_no_reg] > 0} {
      show_objects -name uram_no_reg -object $uram_no_reg
    }
  }

  set mesg "$true_section : the check of URAM is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 16: SRLs with lower depth
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]
if { $really_done(s16_lower_srl) == 1 } {
  set sub_section_index 1

  set srl1 [get_cells -hier -filter {IS_PRIMITIVE && REF_NAME =~ SRL* && (NAME =~ *_srl1)}]
  set srl2 [get_cells -hier -filter {IS_PRIMITIVE && REF_NAME =~ SRL* && (NAME =~ *_srl2)}]
  set srl3 [get_cells -hier -filter {IS_PRIMITIVE && REF_NAME =~ SRL* && (NAME =~ *_srl3)}]
  set srl1_len [llength $srl1]
  set srl2_len [llength $srl2]
  set srl3_len [llength $srl3]
  if {$srl1_len > 1} {
    show_objects -name SRL1_${srl1_len} -object $srl1
    set fn ${true_section}.${sub_section_index}_SRL1_${severity}
    set fid [open $fn.rpt w]
    foreach i_srl1 $srl1 {
      puts $fid $i_srl1
    }
    close $fid
  }
  set mesg "$true_section.${sub_section_index} : the check of SRL1 is done!"
  timing_analysis::print_successful_message $mesg
  incr sub_section_index

  if {$srl2_len > 1} {
    show_objects -name SRL2_${srl2_len} -object $srl2
    set fn ${true_section}.${sub_section_index}_SRL2_${severity}
    set fid [open $fn.rpt w]
    foreach i_srl2 $srl2 {
      puts $fid $i_srl2
    }
    close $fid
  }
  set mesg "$true_section.${sub_section_index} : the check of SRL2 is done!"
  timing_analysis::print_successful_message $mesg
  incr sub_section_index

  if {$srl3_len > 1} {
    show_objects -name SRL3_${srl3_len} -object $srl3
    set fn ${true_section}.${sub_section_index}_SRL3_${severity}
    set fid [open $fn.rpt w]
    foreach i_srl3 $srl3 {
      puts $fid $i_srl3
    }
    close $fid
  }
  set mesg "$true_section.${sub_section_index} : the check of SRL3 is done!"
  timing_analysis::print_successful_message $mesg

  set mesg "$true_section.${sub_section_index} : the check of SRL is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 17: LUT6 (combined LUT) utilization analysis
#Disable LUT Combining and MUXF Inference: page 233 ug949
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]

if { $really_done(s17_combined_lut) == 1 } {

  set lut6 [get_cells -hier -filter {REF_NAME =~ LUT* && SOFT_HLUTNM != ""}]
  set used_lut6 [llength $lut6]
  if {$used_lut6 > 0} {
    set used_lut6_percent [expr double($used_lut6)/double($luts)]
    if {$used_lut6_percent > $combined_lut6_util} {
      show_objects $lut6 -name lut6_${used_lut6}
      set fn ${true_section}_combined_lut6_${severity}
      set fid [open $fn.rpt w]
      foreach i_lut6 $lut6 {
        puts $fid $i_lut6
      }
      close $fid
    }
    set used_lut6_percent [expr round($used_lut6_percent*100)]%
  }

  set mesg "$true_section : the check of combined LUT6 is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 18: MUXF utilization analysis
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]

if { $really_done(s18_muxf) == 1 } {

  set used_muxfs [get_cells -hier -filter "PRIMITIVE_SUBGROUP == MUXF" -quiet]
  set num_used_muxfs [llength $used_muxfs]
  set num_muxfs [expr $slices * 7]
  if {$num_used_muxfs > 0} {
    set used_muxfs_util_actual [expr double($num_used_muxfs)/double($num_muxfs)]
    set used_muxfs_percent [expr round($used_muxfs_util*100)]%
    if {$used_muxfs_util_actual > $used_muxfs_util} {
      show_objects $used_muxfs -name used_muxf_${num_used_muxfs}
      set fn ${true_section}_muxf_${severity}
      set fid [open $fn.rpt w]
      foreach i_used_muxfs $used_muxfs {
        puts $fid $i_used_muxfs
      }
      close $fid
    }
  } else {
    set used_muxfs_percent 0.0%
  }

  set mesg "$true_section : the check of MUXF is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 19: Latch analysis
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]

if { $really_done(s19_latch) == 1 } {
  set used_latch [get_cells -hierarchical -filter { REF_NAME == LDCE || REF_NAME == LDPE } -quiet]
  set used_latch_num [llength $used_latch]
  if {$used_latch_num > 1} {
    show_objects -name latch_${used_latch_num} -object $used_latch
    set fn ${true_section}_Latch_${severity}
    set fid [open $fn.rpt w]
    foreach i_used_latch $used_latch {
      puts $fid $i_used_latch
    }
    close $fid
  }

  set mesg "$true_section : the check of Latch is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 20: Paths crossing SLR analysis
##########################################################################################
set severity "violated"
set true_section [timing_analysis::double_digits $section_index]

if { $really_done(s20_paths_crossing_slr) == 1 } {
  if {$is_opt_design == 0 && $slrs > 1} {
    set slr_list [get_timing_paths -max $max_paths_crossing_slrs -filter \
    {INTER_SLR_COMPENSATION != "" && LOGIC_LEVELS > 0}]
  } else {
    set slr_list [list]
  }
  if {[llength $slr_list] > 0} {
    set fn ${true_section}_paths_crossing_slrs_${severity}
    report_timing -of $slr_list -name $fn
    timing_analysis::report_critical_path $fn $slr_list
  }

  set mesg "$true_section : the check of paths crossing SLRs is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 21: High fanout nets analysis (ug949 table 3-1)
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]

if { $really_done(s21_high_fanout_nets) == 1 } {
  set fn ${true_section}_high_fanout_nets_${severity}
  report_high_fanout_nets -timing -max 100 -name fanout_nets \
  -fanout_greater_than $fanout_greater_than -file $fn.rpt

  set mesg "$true_section : the check of high fanout nets is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 22: Gated clocks analysis
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]

if { $really_done(s22_gated_clock) == 1 } {
  set fn ${true_section}_gated_clocks_${severity}
  report_drc -check PLHOLDVIO-2 -name gated_clk -file $fn.rpt

  set mesg "$true_section : the check of gated clocks is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 23: Constraints analysis
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]

if { $really_done(s23_constraints) == 1 } {
  set sub_section_index 1

  set fn ${true_section}.${sub_section_index}_invalid_constraints_${severity}
  write_xdc -force -constraints invalid ./$fn.xdc
  incr sub_section_index

  set fn ${true_section}.${sub_section_index}_ignored_exceptions_${severity}
  report_exceptions -ignored -file ./$fn.xdc
  incr sub_section_index

  set fn ${true_section}.${sub_section_index}_ignored_objects_exceptions_${severity}
  report_exceptions -ignored_objects -file ./$fn.xdc
  incr sub_section_index

  set fn ${true_section}.${sub_section_index}_merged_exceptions_${severity}
  report_exceptions -write_merged_exceptions -file ./$fn.xdc

  set mesg "$true_section : the check of constraints is done!"
  timing_analysis::print_successful_message $mesg
}
unset severity
incr section_index
##########################################################################################
#Section 24: Report laguna register utilization in each SLR
##########################################################################################
set severity "analysis"
set true_section [timing_analysis::double_digits $section_index]

if {$slrs > 1} {
  if { $really_done(s24_laguna_reg_util) == 1 } {
    set slr [get_slrs]
    set reg_type [list "TX_REG" "RX_REG"]
    timing_analysis::check_array laguna_array
    foreach i_slr $slr {
      foreach i_reg_type $reg_type {
        set laguna_array(${i_slr}_${i_reg_type},type) ${i_slr}_${i_reg_type}
        set laguna_reg [get_bels -regexp -filter "TYPE =~ LAGUNA_${i_reg_type}[0-5]" -of $i_slr]
        set laguna_reg_num [llength $laguna_reg]
        set laguna_array(${i_slr}_${i_reg_type},avlb) $laguna_reg_num
        set laguna_reg_used_num [llength [filter $laguna_reg "IS_USED == 1"]]
        set laguna_array(${i_slr}_${i_reg_type},used) $laguna_reg_used_num
        set temp [expr double($laguna_reg_used_num)/double($laguna_reg_num)]
        set laguna_array(${i_slr}_${i_reg_type},pcet) [format %.2f [expr $temp * 100]]%
      }
    }

    set slr_num [llength $slr]
    set row [expr $slr_num * 2 + 1]
    set fn ${true_section}_laguna_rpt
    set fid [open ${fn}.csv w]
    puts $fid "#\n# File created on [clock format [clock seconds]] \n#\n"
    puts $fid "items,avlb,used,percent"
    set i 0

    set sub_addr [list "type" "avlb" "used" "pcet"]

    foreach i_slr $slr {
      foreach i_reg_type $reg_type {
        foreach i_sub_addr $sub_addr {
          if {$i == 3} {
            puts $fid $laguna_array(${i_slr}_${i_reg_type},$i_sub_addr)
            set i 0
          } else {
            puts -nonewline $fid $laguna_array(${i_slr}_${i_reg_type},$i_sub_addr),
            incr i
          }
        }
      }
    }

    close $fid
    set mesg "$true_section : The check of laguna registers utilization is done!"
    timing_analysis::print_successful_message $mesg
  }
}




