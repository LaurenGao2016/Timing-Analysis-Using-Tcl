#########################################################################################
## Author  : Lauren Gao
## File    : timing_analysis_pkg_v7.tcl
## Company : Xilinx
## Description : sub procs for timing analysis
## Please do not make any changes to this file.
#########################################################################################
namespace eval timing_analysis {
  proc check_array {array_name} {
    upvar 1 $array_name myarray
    if {[info exists myarray]} {
      unset myarray
      array set myarray {}
      puts "The array myarray has already existed, and now it weill be set empty."
    } else {
      array set myarray {}
      puts "The array myarray does not exist, and then it will be created."
    }
  }

  proc copy_array {orig_array new_array} {
    upvar 1 $orig_array orig_a
    upvar 1 $new_array new_a
    foreach {addr val} [array get orig_a] {
      set new_a($addr) $val
    }
  }

  proc double_digits {section_index} {
    if {$section_index < 10 } {
      set true_section S0$section_index
    } else {
      set true_section S$section_index
    }
    return $true_section
  }

  proc print_successful_message {mesg} {
    set mesg_len [string length $mesg]
    for {set i 1} {$i <= $mesg_len} {incr i} {
      if {$i == $mesg_len} {
        puts "#"
      } else {
        puts -nonewline "#"
      }
    }
    puts $mesg
    for {set i 1} {$i <= $mesg_len} {incr i} {
      if {$i == $mesg_len} {
        puts "#"
      } else {
        puts -nonewline "#"
      }
    }
  }

  proc get_max_logic_level {family clk_freq} {
    set max_logic_level [list]
    set 7_series [list aartix7 artix7 artix7l kintex7 kintex7l azynq qartix7 qkintex7 \
                       qkintex7l qvirtex7 qzynq virtex7 zynq]
    set ultrascale [list kintexu virtexu qkintexu]
    set ultrascale_plus [list virtexuplus kintexuplus zynquplus azynquplus]
    set spartan7 [list spartan7 aspartan7]
    if {[lsearch $7_series $family] != -1} {
      if {$clk_freq <= 125} {
        set max_logic_level 15
      } elseif {$clk_freq > 125 && $clk_freq <= 250} {
        set max_logic_level 7
      } elseif {$clk_freq > 250 && $clk_freq <= 350} {
        set max_logic_level 5
      } elseif {$clk_freq > 350 && $clk_freq <= 400} {
        set max_logic_level 4
      } elseif {$clk_freq > 400 && $clk_freq <= 500} {
        set max_logic_level 3
      } else {
        set max_logic_level 2
     }
    } elseif {[lsearch $ultrascale $family] != -1} {
      if {$clk_freq <= 125} {
        set max_logic_level 18
      } elseif {$clk_freq > 125 && $clk_freq <= 250} {
        set max_logic_level 9
      } elseif {$clk_freq > 250 && $clk_freq <= 350} {
        set max_logic_level 6
      } elseif {$clk_freq > 350 && $clk_freq <= 400} {
        set max_logic_level 5
      } elseif {$clk_freq > 400 && $clk_freq <= 500} {
        set max_logic_level 4
      } else {
        set max_logic_level 3
      }
    } elseif {[lsearch $ultrascale_plus $family] != -1} {
      if {$clk_freq <= 125} {
        set max_logic_level 25
      } elseif {$clk_freq > 125 && $clk_freq <= 250} {
        set max_logic_level 12
      } elseif {$clk_freq > 250 && $clk_freq <= 350} {
        set max_logic_level 8
      } elseif {$clk_freq > 350 && $clk_freq <= 400} {
        set max_logic_level 7
      } elseif {$clk_freq > 400 && $clk_freq <= 500} {
        set max_logic_level 5
      } else {
        set max_logic_level 4
      }
    } else {
      set max_logic_level "NaN"
    }
    return $max_logic_level
  }

  proc get_max_min {listin} {
    if {[lsearch -regexp $listin {\D}] == 1} {
      puts "The list contains non-numbers"
      return -code 1
    } else {
      set list_sort [lsort -real -decreasing $listin]
      set list_max [lindex $list_sort 0]
      set list_min [lindex $list_sort end]
    }
    return [concat $list_max $list_min]
  }

  proc get_ff2block_paths {clk target_fanout used_ffs used_blocks max_paths} {
    set ff2block_ctrl_path_LL_0 [list]
    set ff2block_ctrl_path_LL_g_0 [list]
    set ff2block_ctrl_path [get_timing_paths -from $used_ffs -to $used_blocks -max $max_paths\
                           -nworst 1 -unique_pins \
                           -filter "GROUP == $clk" -quiet]
    if {[llength $ff2block_ctrl_path] > 0} {
      foreach ff2block_ctrl_path_i $ff2block_ctrl_path {
        set end_pin [get_property ENDPOINT_PIN $ff2block_ctrl_path_i]
        set end_pin_hier [split $end_pin /]
        set end_pin_last_part [lindex $end_pin_hier end]
        if {[regexp {^CE|[ABEOWR]|CA} $end_pin_last_part]} {
          set logic_level [get_property LOGIC_LEVELS $ff2block_ctrl_path_i]
          if {$logic_level == 0} {
            set net_of_path [get_nets -of $ff2block_ctrl_path_i]
            set net_fanout [get_property PIN_COUNT $net_of_path]
            set net_fanout_max [lindex [timing_analysis::get_max_min $net_fanout] 0]
            if {$net_fanout > $target_fanout} {
              lappend ff2block_ctrl_path_LL_0 $ff2block_ctrl_path_i
            }
          } else {
            lappend ff2block_ctrl_path_LL_g_0 $ff2block_ctrl_path_i
          }
        }
      }
    }
    return [list $ff2block_ctrl_path_LL_0 $ff2block_ctrl_path_LL_g_0]
  }

  proc report_critical_path {file_name critical_path} {
    set fid [open ${file_name}.csv w]
    puts $fid "#\n# File created on [clock format [clock seconds]] \n#\n"
    puts $fid "Startpoint, Endpoint, Slack, LogicLevel, #Lut, Requirement, PathDelay, LogicDelay, NetDelay, Skew, StartClk, EndClk"
    set myf "%.2f"
    set i 0
    foreach critical_path_i $critical_path {
      set start_point [get_property STARTPOINT_PIN $critical_path_i]
      set end_point [get_property ENDPOINT_PIN $critical_path_i]
      set req [get_property REQUIREMENT $critical_path_i]
      if {[llength $req] == 0} {
        set req inf
        set slack inf
      } else {
        set req [format $myf $req]
        set slack [get_property SLACK $critical_path_i]
        if {[llength $slack] > 0} {
          set slack [format $myf $slack]
        }
      }
      set logic_level [get_property LOGIC_LEVELS $critical_path_i]
      set num_luts [llength [get_cells -filter {REF_NAME =~ LUT*} -of $critical_path_i -quiet]]
      set path_delay [format $myf [get_property DATAPATH_DELAY $critical_path_i]]
      set logic_delay [format $myf [get_property DATAPATH_LOGIC_DELAY $critical_path_i]]
      set net_delay [format $myf [get_property DATAPATH_NET_DELAY $critical_path_i]]
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
      set logic_delay $logic_delay\($logic_delay_percent\)
      set net_delay $net_delay\($net_delay_percent\)
      set skew [get_property SKEW $critical_path_i]
      if {[llength $skew] == 0} {
        set skew inf
      } else {
        set skew [format $myf $skew]
      }
      set start_clk [get_property STARTPOINT_CLOCK $critical_path_i]
      if {[llength $start_clk] == 0} {
        set start_clk No
      }
      set end_clk [get_property ENDPOINT_CLOCK $critical_path_i]
      if {[llength $end_clk] == 0} {
        set end_clk No
      }
      puts $fid "$start_point, $end_point, $slack, $logic_level, $num_luts, $req, $path_delay,\
      $logic_delay, $net_delay, $skew, $start_clk, $end_clk"
      incr i
    }
    close $fid
    puts "CSV file $file_name has been created."
  }

  proc report_target_cell {file_name target_cell} {
    set fid [open ${file_name}.csv w]
    puts $fid "#\n# File created on [clock format [clock seconds]] \n#\n"
    puts $fid "ClkName, ClkFreq, Cell"
    foreach target_cell_i $target_cell {
      set clk_pin [get_pins -of $target_cell_i -filter "NAME =~ *CLK"]
      set clk_name [get_clocks -of $clk_pin]
      set clk_period [get_property PERIOD $clk_name]
      set clk_freq [format %.2f [expr 1 / $clk_period * 1000]]
      puts $fid "$clk_name, $clk_freq, $target_cell_i"
    }
    close $fid
  }
}

