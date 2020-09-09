#!/usr/bin/wish

package require Tcl 8.6
package require Tk 8.6

set ::smdir [file dirname [file normalize $argv0]]

source [file join $::smdir sourced.tcl]
namespace path {::src}
source [file join $::smdir util.tcl]

source [file join $::smdir puzzle.tcl]
source [file join $::smdir undo.tcl]
source [file join $::smdir display.tcl]
source [file join $::smdir double.tcl]

#================================================================
# Procedure definitions

proc bindkeys {{gameover 0}} {
  if {$gameover} {
    bind . <<Arrows>>   {set ::msg "Click Start New Game"}
    bind . <<CellUndo>> {set ::msg "Can't Undo after Game Over"}
    } else {
      bind . <<Arrows>>   {move %K}
      bind . <<CellUndo>> {$::game undo}
    }
}

proc chgprob4 {p} {
  $::game setprob4 $p
}
proc resetprob4 {} {
  $::game setprob4 [$::game dfltprob4]
}

proc move {d} {
  set ans [$::game move $d]
  if {$ans == 1} {
    set ::msg "Can't shift $d"
    return
  } elseif {$ans == 2} {
    set ::msg "Game Over"
    bindkeys 1
  } else {
    set ::msg {}
  }
}

proc restart {} {
  $::game start
  bindkeys
}
#================================================================
# Layout

tk_setPalette seashell

wm title . "Shift-Merge"
pack [frame .f -padx 5 -pady 5]
pack [label .f.inst]
pack [frame .f.pf]

pack [canvas .f.pf.pzl -bd 2 -relief solid]

set args_to_double {}
if {[set ndx [lsearch $argv -size]] >= 0} {
  lappend args_to_double -size [lindex $argv [incr $ndx]]
}
set game [double new {*}$args_to_double]
oo::objdefine $game mixin display undo
$game mixconf -canvas .f.pf.pzl

.f.inst configure -text [$game instructions]

set prob4 [$game dfltprob4]

pack [scale .f.pf.sc -orient horizontal \
	  -from 0.0 -to 1.0 -tickinterval 0 \
	  -length 200 -resolution -1 \
	  -variable prob4 -showvalue 1 \
    -command chgprob4 \
	  -label "Probability of 4 insertion"] \
    -side left -padx 10
pack [button .f.pf.reset -text "Set to Default" \
	  -command resetprob4] -side right -padx 10

font create MsgFont -family Arial -size 14

pack [label .f.msg -textvariable msg -width 30 -font MsgFont \
	  -fg red] -side left -padx 5 -pady 10
pack [button .f.but -text "Start New Game" -command restart] \
    -side right -padx 5 -pady 10

event add <<Arrows>> <Up> <Down> <Left> <Right>
event add <<CellUndo>> <BackSpace> <Control-z>

restart
