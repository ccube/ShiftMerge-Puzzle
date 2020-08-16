#!/usr/bin/wish

package require Tk

#================================================================
# Procedure definitions

# True if there are no empty cells
proc full {{gridname cell}} {
    upvar 1 $gridname c
    set ckeys [array names c]
    set emptycnt 0
    
    foreach k $ckeys {
	if {$c($k) eq {}} {incr emptycnt}
    }

    return [expr {! $emptycnt}]
}

# insert 2 or 4 randomly into cells
proc insert {{gridname cell}} {
    upvar 1 $gridname c
    set empty {}
    foreach {k v} [array get c] {
	if {$v eq {}} {
	    lappend empty $k
	}
    }

    set cnt [llength $empty]

    if {! $cnt} {error "Attempt to insert into a full grid"}

    set newnum [if {int(rand()*10)} {expr 2} {expr 4}]
    set empndx [expr {int(rand()*$cnt)}]
    set cellndx [lindex $empty $empndx]
    
    set c($cellndx) $newnum
    return [expr $cnt - 1]
}

proc clear {} {
    global cell
    foreach k [array names cell] {
	set cell($k) {}
    }
}

# Return a true value if grid is not full or if some shift will
# cause 1 or more merges so that the grid would no longer be full
proc playable {} {
    global cell
    if {! [full]} {
	return 1
    } else {
	array set tstcell [array get cell]

	#note that for a non-playable grid NOTHING changes under shift
	foreach d {Up Down Left Right} {
	    shift $d tstcell
	    if {! [full tstcell]} {return 1}
	}

	return 0
    }
}

proc bindkeys {{gameover 0}} {
    global msg
    
    if {$gameover} {
	bind . <<arrows>>   {set msg "Click Start New Game"}
    } else {
	bind . <<arrows>> {move %K}
    }
    bind . <BackSpace> {set msg "Undo is not yet implemented"}
}


proc shift {d {gridname cell}} {
    upvar 1 $gridname c
    switch $d {
	Up {
	    set cktemplate {0,$i 1,$i 2,$i 3,$i}
	}

	Down {
	    set cktemplate {3,$i 2,$i 1,$i 0,$i}
	}

	Left {
	    set cktemplate {$i,0 $i,1 $i,2 $i,3}
	}

	Right {
	    set cktemplate {$i,3 $i,2 $i,1 $i,0}
	}
    }

    # number of changed rows or columns
    set changes 0

    for {set i 0} {$i < 4} {incr i} {
	set ckeys [subst $cktemplate]

	set vals {}
	set merge 0
	
	
	foreach k $ckeys {
	    set v $c($k)
	    if {$v eq {}} {continue}
	    if {$v eq [lindex $vals end]
	        && ! $merge} {
		lset vals end [expr 2*$v]
		set merge 1
	    } else {
		lappend vals $v
		set merge 0
	    }
	}

	set vcnt [llength $vals]
	
	# if vals is empty or full, there's nothing to change for this row/col
	if {$vcnt == 0 || $vcnt == 4} {continue}

	
	set cdiff 0

	for {set k 0} {$k < $vcnt} {incr k} {
	    if {[lindex $vals $k] ne $c([lindex $ckeys $k])} {
		set cdiff 1;
		break
	    }
	}

	if {! $cdiff} {continue}

	incr changes

	# pad to 4
	while {[llength $vals] < 4} {
	    lappend vals {}
	}

	set csetlist {}
	
	for {set j 0} {$j < 4} {incr j} {
	    lappend csetlist [lindex $ckeys $j] [lindex $vals $j]
	}

	array set c $csetlist
    }

    return $changes
}

proc move {d} {
    global msg
    global cell

    if {[shift $d] == 0} {set msg "Can't shift $d"; return}

    set msg {}
    
    if {! [full]} {insert}

    if {! [playable]} {
	set msg "Game Over"
	.f.tab4 configure -bg black
	bindkeys 1
    }
}

proc restart {} {
    global msg
    global cell

    set msg {}
    .f.tab4 configure -bg gray80
    clear
    insert; insert
    bindkeys
}

#================================================================
# Layout

wm title . "Shift-Merge"
pack [frame .f -padx 5 -pady 5]
pack [label .f.inst -text "Use arrow keys to shift"]

pack [frame .f.tab4 -bg gray80 -bd 2 -relief solid]

font create CellFont -family "Comic Sans MS" -size 20
font create MsgFont  -family Arial -size 14

for {set i 0} {$i < 4} {incr i} {
    for {set j 0} {$j < 4} {incr j} {
	set ndx "$i,$j"
	set cname ".f.tab4.cell$i$j"
	set cell($ndx) ""
	label $cname -textvariable cell($ndx) -bg LightYellow -font CellFont \
	    -width 5 -height 2 -anchor center
	grid $cname -row $i -column $j
    }
}

grid rowconfigure .f.tab4 all -minsize 100
grid columnconfigure .f.tab4  all -minsize 100

pack [label .f.msg -textvariable msg -width 60 -font MsgFont -bg white -fg red] \
    -side left -padx 5 -pady 10
pack [button .f.but -text "Start New Game" -command restart] \
    -side right -padx 5 -pady 10

event add <<arrows>> <Up> <Down> <Left> <Right>

restart
