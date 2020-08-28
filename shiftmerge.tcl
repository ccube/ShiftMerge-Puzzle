#!/usr/bin/wish

package require Tcl 8.6
package require Tk 8.6

source puzzle.tcl

#================================================================
# Procedure definitions

proc bindkeys {{gameover 0}} {
    global msg

    if {$gameover} {
	bind . <<Arrows>>   {set msg "Click Start New Game"}
	bind . <<CellUndo>> {set msg "Can't Undo after Game Over"}
    } else {
	bind . <<Arrows>>   {move %K}
	bind . <<CellUndo>> {undo}
    }
}

#================================================================
# Layout

set bgDefault seashell

. configure -bg $bgDefault

wm title . "Shift-Merge"
pack [frame .f -padx 5 -pady 5 -bg $bgDefault]
pack [label .f.inst -bg $bgDefault \
	  -text "Use arrow keys to shift, BackSpace or Control-z to Undo"]

pack [frame .f.tab4 -bg gray80 -bd 2 -relief solid]

font create CellFont -family "Comic Sans MS" -size 20
font create MsgFont  -family Arial -size 14

for {set i 0} {$i < 4} {incr i} {
    for {set j 0} {$j < 4} {incr j} {
	set ndx "$i,$j"
	set cname ".f.tab4.cell$i$j"
	set cell($ndx) {}
	label $cname -textvariable cell($ndx) -bg $cbgpall() -font CellFont \
	    -width 5 -height 2 -anchor center
	grid $cname -row $i -column $j
    }
}

trace add variable cell write changebg

grid rowconfigure .f.tab4 all -minsize 100
grid columnconfigure .f.tab4  all -minsize 100

set prob4Default 0.2
set prob4 $prob4Default

pack [frame .f.prob4 -bg $bgDefault] -pady 10
pack [scale .f.prob4.sc -orient horizontal -bg $bgDefault \
	  -from 0.0 -to 1.0 -tickinterval 0 \
	  -length 200 -resolution -1 \
	  -variable prob4 -showvalue 1 \
	  -label "Probability of 4 insertion"] \
    -side left -padx 10
pack [button .f.prob4.reset -text "Set to Default" -bg $bgDefault \
	  -command resetprob4] -side right -padx 10

pack [label .f.msg -textvariable msg -width 30 -font MsgFont \
	  -fg red -bg $bgDefault] -side left -padx 5 -pady 10
pack [button .f.but -text "Start New Game" -command restart -bg $bgDefault] \
    -side right -padx 5 -pady 10

event add <<Arrows>> <Up> <Down> <Left> <Right>
event add <<CellUndo>> <BackSpace> <Control-z>

set undostack {}

restart
