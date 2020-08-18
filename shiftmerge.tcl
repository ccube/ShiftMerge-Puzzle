#!/usr/bin/wish

package require Tk

#================================================================
# Procedure definitions

# True if there are no empty cells
proc full {{gridname cell}} {
    upvar 1 $gridname cell
    set ckeys [array names cell]
    set emptycnt 0
    
    foreach k $ckeys {
	if {$cell($k) eq {}} {incr emptycnt}
    }

    return [expr {! $emptycnt}]
}

# insert 2 or 4 randomly into cells
proc insert {} {
    global cell
    global prob4
    
    set empty {}
    foreach {k v} [array get cell] {
	if {$v eq {}} {
	    lappend empty $k
	}
    }

    set cnt [llength $empty]

    if {! $cnt} {error "Attempt to insert into a full grid"}

    set newnum [if {rand() > $prob4} {expr 2} {expr 4}]
    set empndx [expr {int(rand()*$cnt)}]
    set cellndx [lindex $empty $empndx]
    
    set cell($cellndx) $newnum
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
	bind . <<Arrows>>   {set msg "Click Start New Game"}
	bind . <<CellUndo>> {set msg "Can't Undo after Game Over"}
    } else {
	bind . <<Arrows>>   {move %K}
	bind . <<CellUndo>> {undo}
    }
}


proc shift {d {gridname cell}} {
    upvar 1 $gridname cell
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
	    set v $cell($k)
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

	
	set csetlist {}

	for {set k 0} {$k < 4} {incr k} {
	    set nv [expr {$k < $vcnt ? [lindex $vals $k] : {}}]
	    set ndx [lindex $ckeys $k]
	    if {$nv ne $cell($ndx)} {
		lappend csetlist $ndx $nv
	    }
	}

	if {[llength $csetlist] == 0} {continue}
	incr changes
	array set cell $csetlist
    }

    return $changes
}

proc move {d} {
    global msg
    global cell
    global undostack

    set state [array get cell]
    
    if {[shift $d] == 0} {set msg "Can't shift $d"; return}

    set msg {}
    
    if {! [full]} {insert}

    if {! [playable]} {
	set msg "Game Over"
	.f.tab4 configure -bg black
	bindkeys 1
    } else {
	lappend undostack $state
    }
}

proc undo {} {
    global msg
    global cell
    global undostack

    if {[llength $undostack] == 0} {
	set msg "Can't Undo any further"
    } else {
	set prevstate [lindex $undostack end]
	set undostack [lreplace $undostack end end]
	array set cell $prevstate
    }
}

proc restart {} {
    global msg
    global cell
    global undostack

    set undostack {}
    set msg {}
    .f.tab4 configure -bg gray80
    clear
    insert; insert
    bindkeys
}

proc changebg {n1 n2 notused} {
    global cell
    global cbgpall

    if {$n1 eq "cell" \
	    && [regexp {([0-3]),([0-3])} $n2 mv row col]} {
	set nv $cell($n2)
	if {! [info exists cbgpall($nv)]} {
	    set newbg PaleTurquoise
	} else {
	    set newbg $cbgpall($nv)
	}

	".f.tab4.cell$row$col" configure -bg $newbg
    }
}

proc resetprob4 {} {
    global prob4Default
    global prob4

    set prob4 $prob4Default
}
#================================================================
# Layout

array set cbgpall {
    {}      #FFFFFF
    2       #FFFFF5
    4       #FFFDE0
    8       #FFF8CC
    16      #FFF3C2
    32      #FFE9AD
    64      #FFDD99
    128     #FFCE85
    256     #FFBC70
    512     #FFA85C
    1024    #FF9147
    2048    #A0FF94
    4096    #7CFF6B
    8192    #61FF4C
}

tk_setPalette seashell

wm title . "Shift-Merge"
pack [frame .f -padx 5 -pady 5]
pack [label .f.inst  \
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

pack [frame .f.prob4] -pady 10
pack [scale .f.prob4.sc -orient horizontal \
	  -from 0.0 -to 1.0 -tickinterval 0 \
	  -length 200 -resolution -1 \
	  -variable prob4 -showvalue 1 \
	  -label "Probability of 4 insertion"] \
    -side left -padx 10
pack [button .f.prob4.reset -text "Set to Default" \
	  -command resetprob4] -side right -padx 10

pack [label .f.msg -textvariable msg -width 30 -font MsgFont \
	  -fg red] -side left -padx 5 -pady 10 
pack [button .f.but -text "Start New Game" -command restart] \
    -side right -padx 5 -pady 10

event add <<Arrows>> <Up> <Down> <Left> <Right>
event add <<CellUndo>> <BackSpace> <Control-z>

set undostack {}

restart
