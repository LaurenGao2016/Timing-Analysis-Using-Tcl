#########################################################################################
## Author  : Lauren Gao
## File    : timing_analysis_pkg_v2019.1.tcl
## Company : Xilinx
## Description : sub procs for timing analysis
## Please do not make any changes to this file.
#########################################################################################
namespace eval timing_analysis {
  proc get_sn {index} {
    if {$index<10} {
      set sn "S0$index"
    } else {
      set sn "S$index"
    }
    return $sn
  }

  proc report_critical_cells {fn mycells} {
    set fid [open ${fn}.csv w]
    puts $fid "#\n# File created on [clock format [clock seconds]] \n#\n"
    puts $fid "CellName, RefName, ClockName, ClockRate"
    set myf "%.2f"
    foreach i_mycells $mycells {
      set ref_name [get_property REF_NAME [get_cells $i_mycells]]
      set clk_pin  [get_pins -of [get_cells $i_mycells] -filter "NAME =~ *CLK"]
      set clk_name [get_clocks -of $clk_pin -quiet]
      if {[llength $clk_name]==0} {
        set myclk "Review"
        set clk_rate "Review"
      } else {
        set myclk    [lindex $clk_name 0]
        set clk_rate [format $myf [expr 1.0/[get_property PERIOD $myclk]*1000]]
      }
      puts $fid "$i_mycells, $ref_name, $myclk, $clk_rate"
    }
    close $fid
    puts "CSV file $fn has been created."
  }

  proc report_cells {fn mycells} {
    set fid [open ${fn}.csv w]
    puts $fid "#\n# File created on [clock format [clock seconds]] \n#\n"
    puts $fid "CellName, RefName, Parent"
    foreach i_mycells $mycells {
      set ref_name [get_property REF_NAME [get_cells $i_mycells]]
      set parent   [get_property PARENT   [get_cells $i_mycells]]
      if {[llength $parent]==0} {set parent "TOP"}
      puts $fid "$i_mycells, $ref_name, $parent"
    }
    close $fid
    puts "CSV file $fn has been created."
  }

  proc create_timing_report {fn paths} {
    set fid [open ${fn}.csv w]
    puts $fid "#\n# File created on [clock format [clock seconds]] \n#\n"
    puts $fid "Startpoint, Endpoint, StartClock, EndClock, Requirement, Slack, LogicLevel,\
    #Lut, PathDelay, LogicDelay, LogicDelay%, NetDelay, NetDelay%, Skew, Uncertainty, Inter-SLRCompensation"
    set myf "%.2f"
    foreach paths_i $paths {
      set start_point [get_property STARTPOINT_PIN   $paths_i]
      set end_point   [get_property ENDPOINT_PIN     $paths_i]
      set start_clk   [get_property STARTPOINT_CLOCK $paths_i]
      if {[llength $start_clk] == 0} {set start_clk No}
      set end_clk [get_property ENDPOINT_CLOCK $paths_i]
      if {[llength $end_clk] == 0} {set end_clk No}
      set req [get_property REQUIREMENT $paths_i]
      if {[llength $req] == 0} {
        set req inf
        set slack inf
      } else {
        set req [format $myf $req]
        set slack [get_property SLACK $paths_i]
        if {[llength $slack] > 0} {set slack [format $myf $slack]}
      }
      set logic_level [get_property LOGIC_LEVELS $paths_i]
      set num_luts    [llength [get_cells -filter {REF_NAME =~ LUT*} -of $paths_i -quiet]]
      set path_delay  [format $myf [get_property DATAPATH_DELAY $paths_i]]
      set logic_delay [format $myf [get_property DATAPATH_LOGIC_DELAY $paths_i]]
      set net_delay   [format $myf [get_property DATAPATH_NET_DELAY $paths_i]]
      if {$path_delay == 0 || $logic_delay == 0} {
        set logic_delay_percent 0.0%
      } else {
        set logic_delay_percent [expr round($logic_delay/$path_delay*100)]%
      }
      if {$path_delay == 0 || $net_delay == 0} {
        set net_delay_percent 0.0%
      } else {
        set net_delay_percent [expr round($net_delay/$path_delay*100)]%
      }
      #set logic_delay $logic_delay\($logic_delay_percent\)
      #set net_delay $net_delay\($net_delay_percent\)
      set skew [get_property SKEW $paths_i]
      if {[llength $skew] == 0} {
        set skew inf
      } else {
        set skew [format $myf $skew]
      }
      set uncertainty [get_property UNCERTAINTY $paths_i]
      if {[llength $uncertainty] == 0} {
        set uncertainty inf
      } else {
        set skew [format $myf $uncertainty]
      }
      set compensation [get_property INTER_SLR_COMPENSATION $paths_i]
      if {[llength $compensation]==0} {set compensation "Empty"}
      puts $fid "$start_point, $end_point, $start_clk, $end_clk, $req, $slack, $logic_level,\
      $num_luts, $path_delay, $logic_delay, $logic_delay_percent, $net_delay, $net_delay_percent,\
      $skew, $uncertainty, $compensation"
    }
    close $fid
    puts "CSV file $fn has been created."
  }


  proc my_check_timing {sn {en 1}} {
    if {$en==1} {
      puts "Start section $sn: check_timing"
      check_timing -name ${sn}_check_timing_analysis \
      -file ${sn}_check_timing_analysis.rpt -verbose
      puts "Complete section $sn: check_timing"
    }
  }

  proc my_timing_summary {sn dcp_type {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_timing_summary"
      if {$dcp_type==1} {
        report_timing_summary -no_check_timing -no_header -setup -max 50 -nworst 1 -unique_pins \
        -name ${sn}_timing_summary_analysis -file ${sn}_timing_summary_analysis.rpt
      } else {
        report_timing_summary -no_check_timing -no_header -max 50 -nworst 1 -unique_pins \
        -name ${sn}_timing_summary_analysis -file ${sn}_timing_summary_analysis.rpt
      }
      puts "Complete section $sn: report_timing_summary"
    }
  }

  proc my_neg_slack_timing_report {sn dcp_type {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_timing: 100 negative slack paths"
      if {$dcp_type==1} {
        set paths [get_timing_paths -setup -max_paths 100 -nworst 1 -unique_pins \
        -slack_lesser_than 0 -quiet]
      } else {
        set paths [get_timing_paths -delay_type min_max -max_paths 100 -nworst 1 \
        -unique_pins -slack_lesser_than 0 -quiet]
      }
      if {[llength $paths]>0} {
        set fn ${sn}_neg_slack_path_violation
        report_timing -of $paths -name $fn
        create_timing_report $fn $paths
        puts "Complete section $sn: report_timing: 100 negative slack paths"
      } else {
        puts "There is no any paths with negative slack"
      }
    }
  }

  proc report_block2block {sn block {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_block2block: 100 paths from blocks to blocks"
      set fn ${sn}_b2b_violation
      set paths_block2block [get_timing_paths -from $block -to $block -max_paths 100 -quiet]
      if {[llength $paths_block2block]>0} {
        report_timing -of $paths_block2block -name $fn
        create_timing_report $fn $paths_block2block
        puts "Complete section $sn: report_block2block: 100 paths from blocks to blocks"
      } else {
        puts "There is not any path from blocks to blocks"
      }
    }
  }

  proc get_timing_base {index is_accurate} {
    set timing_table(1,-1) 0.575
    set timing_table(1,-2) 0.500
    set timing_table(1,-3) 0.425
    set timing_table(2,-1) 0.490
    set timing_table(2,-2) 0.425
    set timing_table(2,-3) 0.360
    set timing_table(3,-1) 0.350
    set timing_table(3,-2) 0.300
    set timing_table(3,-3) 0.250
    set timing_table(3,-1LV) 0.490
    set timing_table(3,-2LV) 0.425
    set timing_table(3,-3LV) 0.360
    if {[info exists timing_table($index)]} {
      set delay_i $timing_table($index)
    } else {
      set delay_i 0.5
    }
    if {$is_accurate==1} {
      set delay $delay_i
    } else {
      set delay 0.5
    }
    return $delay
  }

  proc report_high_logic_level {sn clock_name delay {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_high_logic_level: 10 paths with higher logic level under given clock"
      set clock_period [get_property PERIOD $clock_name]
      set clock_freq   [format "%.2f" [expr 1.0/$clock_period*1000]]
      set max_ll [expr int(floor(double($clock_period)/double($delay)))]
      set paths [get_timing_paths -max_paths 10 -filter "GROUP==$clock_name && LOGIC_LEVELS>$max_ll" -quiet]
      if {[llength $paths]>0} {
        set fn ${sn}_${clock_name}_${clock_freq}_LL_${max_ll}
        report_timing -of $paths -name $fn
        create_timing_report $fn $paths
      }
      puts "Complete section $sn: report_high_logic_level: $clock_name $clock_freq $max_ll 10 paths"
    }
  }

  proc report_cell_bel {fn cell bel} {
    set fid [open ${fn}.csv w]
    puts $fid "#\n# File created on [clock format [clock seconds]] \n#\n"
    puts $fid "CellName, BelName"
    foreach i_cell $cell i_bel $bel {
      puts $fid "$i_cell, $i_bel"
    }
    close $fid
    puts "Cells and their bels are recorded"
  }

  proc get_cells_not_use_laguna {sn xnets {en}} {
    if {$en==1} {
      puts "Get cells without using laguna registers"
      set tx_cells [get_cells -of [get_pins -of [get_nets $xnets] -leaf -filter "DIRECTION==OUT"]]
      set rx_cells [get_cells -of [get_pins -of [get_nets $xnets] -leaf -filter "DIRECTION==IN"]]
      set tx_bels  [get_bels -of $tx_cells]
      set rx_bels  [get_bels -of $rx_cells]
      set tx_nlaguna_bels [filter $tx_bels "NAME !~ LAGUNA*"]
      set tx_laguna_bels  [filter $tx_bels "NAME =~ LAGUNA*"]
      set rx_nlaguna_bels [filter $rx_bels "NAME !~ LAGUNA*"]
      set rx_laguna_bels  [filter $rx_bels "NAME =~ LAGUNA*"]
      if {[llength $tx_cells]>0} {
        set fn ${sn}_tx_crossing_slr_analysis
        show_objects $tx_cells -name $fn
        report_cell_bel $fn $tx_cells $tx_bels
      }
      if {[llength $rx_cells]>0} {
        set fn ${sn}_rx_crossing_slr_analysis
        show_objects $rx_cells -name $fn
        report_cell_bel $fn $rx_cells $rx_bels
      }
      puts "Complete: get cells and their bels crossing SLRs"
    }
  }


  proc report_paths_crossing_slrs {sn dcp_type en_get_cells_crossing_slrs {en}} {
    if {$en==1} {
      if {$dcp_type==2} {
        set xneta [xilinx::designutils::get_inter_slr_nets]
        set xnets [filter $xneta "TYPE != GLOBAL_CLOCK"]
      } elseif {$dcp_type==3} {
        set xnets [xilinx::designutils::get_sll_nets]
      } else {
        puts "The nets crossing SLRs cannot be obtained under this DCP"
        return
      }
      set xnets_len [llength $xnets]
      if {$xnets_len>0} {
        set paths [get_timing_paths -nworst 1 -max $xnets_len -through $xnets \
        -filter {INTER_SLR_COMPENSATION != ""}]
        get_cells_not_use_laguna $sn $xnets $en_get_cells_crossing_slrs
      }
      if {[llength $paths]>0} {
        set paths_ll_1 [filter $paths "LOGIC_LEVELS > 0"]
        set paths_fo_1 [filter $paths "MAX_FANOUT > 1"]
        if {[llength $paths_ll_1]} {
          set fn ${sn}_paths_crossing_slr_LL_violation
          report_timing -of $paths_ll_1 -name $fn
          create_timing_report $fn $paths_ll_1
        }
        if {[llength $paths_fo_1]} {
          set fn ${sn}_paths_crossing_slr_FO_violation
          report_timing -of $paths_fo_1 -name $fn
          create_timing_report $fn $paths_fo_1
        }
      }
      puts "Complete section $sn: report_paths_crossing_slrs"
    }
  }


  proc get_no_reg_bram {sn used_bram {en}} {
    if {$en==1} {
      puts "Start section $sn: get_no_reg_bram get bram without using embedded registers"
      set used_bram_a [filter $used_bram "CASCADE_ORDER_A==NONE && CASCADE_ORDER_B==NONE"]
      set used_bram_a_violated {}
      if {[llength $used_bram_a]>0} {
        foreach i_used_bram_a $used_bram_a {
          set douta [get_pins -of $i_used_bram_a -filter "REF_PIN_NAME=~DOUTADOUT[*]"]
          if {"1" in [get_property IS_CONNECTED $douta]} {
            if {[get_property DOA_REG $i_used_bram_a]==0} {
              lappend used_bram_a_violated $i_used_bram_a
            }
          }
          set doutb [get_pins -of $i_used_bram_a -filter "REF_PIN_NAME=~DOUTBDOUT[*]"]
          if {"1" in [get_property IS_CONNECTED $doutb]} {
            if {[get_property DOB_REG $i_used_bram_a]==0} {
              lappend used_bram_a_violated $i_used_bram_a
            }
          }
        }
        set used_bram_a_violated [lsort -unique $used_bram_a_violated]
      }
      set used_fifo_violated [filter $used_bram "CASCADE_ORDER==NONE && REGISTER_MODE==UNREGISTERED"]
      set used_cas_bram_a_violated  [filter $used_bram "CASCADE_ORDER_A==LAST && CASCADE_ORDER_B==NONE && DOA_REG==0"]
      set used_cas_bram_b_violated  [filter $used_bram "CASCADE_ORDER_B==LAST && CASCADE_ORDER_A==NONE && DOB_REG==0"]
      set used_cas_bram_ab_violated [filter $used_bram "CASCADE_ORDER_B==LAST && CASCADE_ORDER_A==LAST && (DOB_REG==0 || DOA_REG==0)"]
      set used_cas_fifo_violated    [filter $used_bram "CASCADE_ORDER==LAST && REGISTER_MODE==UNREGISTERED"]
      set used_bram_violated {}
      set used_bram_violated [concat $used_bram_a_violated $used_fifo_violated $used_cas_bram_a_violated \
      $used_cas_bram_b_violated $used_cas_bram_ab_violated $used_cas_fifo_violated]
      set used_bram_violated [lsort -unique $used_bram_violated]
      if {[llength $used_bram_violated]>0} {
        show_objects $used_bram_violated -name ${sn}_bram_violated
        set fn ${sn}_bram_violated
        report_critical_cells $fn $used_bram_violated
      }
      puts "Complete section $sn: get_no_reg_bram"
    }
  }

  proc get_no_reg_uram {sn used_uram {en}} {
    if {$en==1} {
      puts "Start section $sn: get_no_reg_uram get uram without using embedded registers"
      set used_uram_a [filter $used_uram "CASCADE_ORDER_A==NONE"]
      set used_uram_a_violated {}
      if {[llength $used_uram_a]>0} {
        foreach i_used_uram_a $used_uram_a {
          set douta [get_pins -of $i_used_uram_a -filter "REF_PIN_NAME=~DOUT_A[*]"]
          if {"1" in [get_property IS_CONNECTED $douta]} {
            if {[get_property OREG_A $i_used_uram_a]==0} {
              lappend used_uram_a_violated $i_used_uram_a
            }
          }
          set doutb [get_pins -of $i_used_uram_a -filter "REF_PIN_NAME=~DOUT_B[*]"]
          if {"1" in [get_property IS_CONNECTED $doutb]} {
            if {[get_property OREG_B $i_used_uram_a]==0} {
              lappend used_uram_a_violated $i_used_uram_a
            }
          }
        }
      }
      set used_cas_uram [filter $used_uram "CASCADE_ORDER_A==LAST"]
      set used_cas_uram_violated {}
      if {[llength $used_cas_uram]>0} {
        foreach i_used_cas_uram $used_cas_uram {
          set douta [get_pins -of $i_used_cas_uram -filter "REF_PIN_NAME=~DOUT_A[*]"]
          if {"1" in [get_property IS_CONNECTED $douta]} {
            if {[get_property OREG_A $i_used_cas_uram]==0} {
              lappend used_cas_uram_violated $i_used_cas_uram
            }
          }
          set doutb [get_pins -of $i_used_cas_uram -filter "REF_PIN_NAME=~DOUT_B[*]"]
          if {"1" in [get_property IS_CONNECTED $doutb]} {
            if {[get_property OREG_B $i_used_cas_uram]==0} {
              lappend used_cas_uram_violated $i_used_cas_uram
            }
          }
        }
      }
      set used_uram_violated [concat $used_uram_a_violated $used_cas_uram_violated]
      if {[llength $used_uram_violated]>0} {
        show_objects $used_uram_violated -name ${sn}_uram_violated
        set fn ${sn}_uram_violated
        report_critical_cells $fn $used_uram_violated
      }
      puts "Complete section $sn: get_no_reg_uram"
    }
  }

  proc get_no_mreg_dsp {sn used_dsp {en 1}} {
    if {$en==1} {
      puts "Start section $sn: get_no_mreg_dsp get DSP without using MREG"
      set dsp_mreg_violated [filter $used_dsp "MREG==0"]
      if {[llength $dsp_mreg_violated]>0} {
        show_objects $dsp_mreg_violated -name ${sn}_dsp_mreg_violated
        set fn ${sn}_dsp_mreg_violated
        report_critical_cells $fn $dsp_mreg_violated
      }
      puts "Complete section $sn: get_no_mreg_dsp"
    }
  }

  proc get_no_preg_dsp {sn used_dsp {en 1}} {
    if {$en==1} {
      puts "Start section $sn: get_no_preg_dsp get DSP without using PREG"
      set dsp_preg_violated [filter $used_dsp "PREG==0"]
      if {[llength $dsp_preg_violated]>0} {
        show_objects $dsp_preg_violated -name ${sn}_dsp_preg_violated
        set fn ${sn}_dsp_preg_violated
        report_critical_cells $fn $dsp_preg_violated
      }
      puts "Complete section $sn: get_no_preg_dsp"
    }
  }

  proc get_lower_depth_srl {sn {en 1}} {
    if {$en==1} {
      puts "Start section $sn: get_lower_depth_srl get SRLs with lower depth"
      set srl1 [get_cells -hier -filter {IS_PRIMITIVE && REF_NAME =~ SRL* && (NAME =~ *_srl1)} -quiet]
      set srl2 [get_cells -hier -filter {IS_PRIMITIVE && REF_NAME =~ SRL* && (NAME =~ *_srl2)} -quiet]
      set srl3 [get_cells -hier -filter {IS_PRIMITIVE && REF_NAME =~ SRL* && (NAME =~ *_srl3)} -quiet]
      if {[llength $srl1]>0} {
        set fn ${sn}_srl1_analysis
        show_objects $srl1 -name ${sn}_srl1_analysis
        report_critical_cells $fn $srl1
      }
      if {[llength $srl2]>0} {
        set fn ${sn}_srl2_analysis
        show_objects $srl2 -name ${sn}_srl2_analysis
        report_critical_cells $fn $srl2
      }
      if {[llength $srl3]>0} {
        set fn ${sn}_srl3_analysis
        show_objects $srl3 -name ${sn}_srl3_analysis
        report_critical_cells $fn $srl3
      }
      puts "Complete section $sn: get_lower_depth_srl"
    }
  }

  proc get_combined_lut {sn {en 1}} {
    if {$en==1} {
      puts "Start section $sn: get_combined_lut get combined lut"
      set used_combined_lut [get_cells -hier -filter {REF_NAME =~ LUT* && SOFT_HLUTNM != ""} -quiet]
      if {[llength $used_combined_lut]>0} {
        set fn ${sn}_combined_lut_analysis
        show_objects $used_combined_lut -name $fn
        report_cells $fn $used_combined_lut
      }
      puts "Complete section $sn: get_combined_lut"
    }
  }

  proc get_muxfx {sn {en 1}} {
    if {$en==1} {
      puts "Start section $sn: get_muxf get MUXF7 MUXF8 MUXF9"
      set muxfx [get_cells -hier -regexp -filter {REF_NAME =~ MUXF[7-9]} -quiet]
      if {[llength $muxfx]>0} {
        set fn ${sn}_muxfx_analysis
        show_objects $muxfx -name $fn
        report_cells $fn $muxfx
      }
      puts "Complete section $sn: get_combined_lut"
    }
  }

  proc get_latch {sn {en}} {
    if {$en==1} {
      puts "Start section $sn: get_latch LDCE LDPE"
      set mylatch [get_cells -hier -regexp -filter {REF_NAME =~ LD[CP]E} -quiet]
      if {[llength $mylatch]>0} {
        set fn ${sn}_latch_analysis
        show_objects $mylatch -name $fn
        report_cells $fn $mylatch
      }
      puts "Complete section $sn: get_latch"
    }
  }

  proc report_clock_characteristics {sn max_paths {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_clock_characteristics"
      set myf "%.2f"
      set fn ${sn}_clock_characteristics_analysis
      set myclk [get_clocks]
      set fid [open ${fn}.csv w]
      puts $fid "#\n# File created on [clock format [clock seconds]] \n#\n"
      puts $fid "Name, Driver, Freq, Period, Skew(Setup), Skew(Hold), ClockRoot, CrossingSLRs, \
                 FlatPinCnt, HighPriority, UserClkRoot"
      set gclk_net [get_nets -hier -filter "TYPE==GLOBAL_CLOCK" -top_net_of_hierarchical_group]
      if {[llength $gclk_net]>0} {
        foreach i_gclk_net $gclk_net {
          set i_gclk [get_clocks -of $i_gclk_net -quiet]
          if {[llength $i_gclk]>0} {
            set i_period [get_property PERIOD $i_gclk]
            set i_freq [format $myf [expr 1.0/$i_period*1000]]
            set i_clock_root [get_property CLOCK_ROOT $i_gclk_net]
            if {[llength $i_clock_root]==0} {set i_clock_root "Unknown"}
            set i_crossing_slrs [get_property CROSSING_SLRS $i_gclk_net]
            if {[llength $i_crossing_slrs]==0} {set i_crossing_slrs "Unknown"}
            set i_flat_pin_cnt [get_property FLAT_PIN_COUNT $i_gclk_net]
            if {[llength $i_flat_pin_cnt]==0} {set i_flat_pin_cnt "Unknown"}
            set i_cell [get_cells -of [get_pins -of $i_gclk_net -leaf -filter "DIRECTION==OUT"]]
            set i_driver [get_property REF_NAME $i_cell]
            set i_high_priority [get_property HIGH_PRIORITY $i_gclk_net]
            if {[llength $i_high_priority]==0} {set i_high_priority "Unknown"}
            set i_user_clock_root [get_property USER_CLOCK_ROOT $i_gclk_net]
            if {[llength $i_user_clock_root]==0} {set i_user_clock_root "Unknown"}
            set i_paths_setup [get_timing_paths -from $i_gclk -to $i_gclk -setup -max_paths $max_paths -nworst 1]
            set setup_skew_abs [list]
            if {[llength $i_paths_setup]>0} {
              set setup_skew_val [get_property SKEW $i_paths_setup]
              foreach i_setup_skew_val $setup_skew_val {
                lappend setup_skew_abs [expr abs($i_setup_skew_val)]
              }
              set max_setup_skew [lindex [lsort -decreasing $setup_skew_abs] 0]
              set i_paths_hold [get_timing_paths -from $i_gclk -to $i_gclk -hold -max_paths $max_paths -nworst 1]
              set hold_skew_abs [list]
              set hold_skew_val [get_property SKEW $i_paths_hold]
              foreach i_hold_skew_val $hold_skew_val {
                lappend hold_skew_abs [expr abs($i_hold_skew_val)]
              }
              set max_hold_skew [lindex [lsort -decreasing $hold_skew_abs] 0]
              puts $fid "$i_gclk, $i_driver, $i_freq, $i_period, $max_setup_skew, $max_hold_skew, \
              $i_clock_root, $i_crossing_slrs, $i_flat_pin_cnt, $i_high_priority, $i_user_clock_root"
            }
          }
        }
        close $fid
      }
      puts "Complete section $sn: report_clock_characteristics"
    }
  }

  proc report_congestion_level {sn dcp_type {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_congestion_level"
      if {$dcp_type==1} {
        puts "Congestion level is not available under current stage of DCP"
        return
      } else {
        set fn ${sn}_congestion_analysis
        report_design_analysis -congestion -complexity -name $fn -file ${fn}.rpt
      }
      puts "Complete section $sn: report_congestion_level"
    }
  }

  proc report_qor {sn vivado_version {en 1} } {
    if {$en==1} {
      puts "Start section $sn: report_qor"
      set fn ${sn}_qor_suggestions_analysis
      file mkdir $fn
      if {$vivado_version<2018.3} {
        report_qor_suggestions -report_all_paths -evaluate_pipelining -output_dir ./$fn
      } elseif {$vivado_version==2018.3} {
        report_qor_suggestions -report_all_paths -evaluate_pipelining -output_dir ./$fn -name $fn
      } else {
        report_qor_suggestions -report_all_paths -evaluate_pipelining -name $fn
        write_qor_suggestion -all ${fn}.rqs
        write_qor_suggestions -tcl_output_dir $fn ./  
      }
      puts "Complete section $sn: report_qor"
    }
  }

  proc my_report_methodology {sn {en 1} } {
    if {$en==1} {
      puts "Start section $sn: report_methodology"
      set fn ${sn}_methodology_analysis
      report_methodology -file ${fn}.rpt -name $fn
      puts "Complete section $sn: report_methodology"
    }
  }

  proc report_failfast {sn slrs dcp_type {en 1} } {
    if {$en==1} {
      puts "Start section $sn: report_failfast"
      set fn ${sn}_failfast_analysis
      if {$slrs==1} {
        xilinx::designutils::report_failfast -detailed_reports impl -file ${fn}.rpt
      } else {
        if {$dcp_type==1} {
          xilinx::designutils::report_failfast -detailed_reports impl -file ${fn}.rpt
        } else {
          xilinx::designutils::report_failfast -by_slr -detailed_reports impl -file ${fn}.rpt
        }
      }
      puts "Complete section $sn: report_failfast"
    }
  }

  proc my_report_utilization {sn {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_utilization"
      set fn ${sn}_util_analysis
      report_utilization -name $fn -file ${fn}.rpt
      puts "Complete section $sn: report_utilization"
    }
  }

  proc my_report_cdc {sn {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_cdc"
      set fn ${sn}_cdc_analysis
      report_cdc -no_header -severity {Critical} -name $fn -file ${fn}.rpt
      puts "Complete section $sn: report_cdc"
    }
  }

  proc my_report_exceptions {sn {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_exceptions"
      set fn ${sn}_exceptions_analysis
      report_exceptions -summary -name ${fn} -file ${fn}.rpt
      puts "Complete section $sn: report_exceptions"
    }
  }

  proc my_clock_networks {sn {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_clock_networks"
      set fn ${sn}_clock_networks_analysis
      report_clock_networks -name $fn -file ${fn}.rpt
      puts "Complete section $sn: report_clock_networks"
    }
  }

  proc my_clock_interaction {sn {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_clock_interaction"
      set fn ${sn}_clock_interaction_analysis
      report_clock_interaction -name $fn -file ${fn}.rpt
      puts "Complete section $sn: report_clock_interaction"
    }
  }

  proc high_fanout_nets {sn slrs dcp_type {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_high_fanout_nets"
      set fn ${sn}_high_fanout_nets_analysis
      if {$slrs==1} {
        report_high_fanout_nets -name ${fn} -file ${fn}.rpt
      } else {
        if {$dcp_type==1} {
          report_high_fanout_nets -name ${fn} -file ${fn}.rpt
        } else {
          report_high_fanout_nets -slr -name ${fn} -file ${fn}.rpt
        }
      }
      puts "Complete section $sn: report_high_fanout_nets"
    }
  }

  proc my_ram_util {sn {en 1}} {
    if {$en==1} {
      puts "Start section $sn: report_ram_utilization"
      set fn ${sn}_ram_util
      report_ram_utilization -file ${fn}.rpt
    }
  }
}
