package require Tcl 8.6
package require Tk 8.6

if {[sourced_before DOUBLE]} {return}

source [file join $::smdir roundRect.tcl]

oo::class create ::double {
  superclass ::puzzle

  classvar Default_Prob4 0.2
  classvar Instructions {Arrow keys to move, BackSpace or Control-z to Undo}
  classvar CellFont [font create -family "Comic Sans MS" -size 20]

  # Constants used to intialize playing field
  # and manipulate canvas
  # Dimensions in pixels

  classvar CellSize 80
  classvar StartOffset 3
  classvar CellSpacing 16
  classvar CellRadius 14
  classvar NormalCnvBg bisque3
  classvar WarnCnvBg yellow3
  classvar OverCnvBg red3
  classvar CellBg {ARRAY
       {}   #FFFFFF
        2   #FFFFF5
        4   #FFFDE0
        8   #FFF8CC
       16   #FFF3C2
       32   #FFE9AD
       64   #FFDD99
      128   #FFCE85
      256   #FFBC70
      512   #FFA85C
     1024   #FF9147
     2048   #A0FFA0
     4096   #60F060
     8192   #10E010
    16384   #00D000
    32768   #00B000
  }

  # probability of a 4 being inserted
  variable prob4

  constructor args {
    classvar Default_Prob4
    set prob4 $Default_Prob4
    next {*}$args
  } ;# End constructor

  method dfltprob4 {} {
    classvar Default_Prob4
    return $Default_Prob4
  }
  # With no argument returns current value of prob4
  # with a valid value (0 <= $nv <= 1.0), sets prob4
  method setprob4 {nv} {
    if {$nv eq {}} {
      return $prob4
    }

    if {! $nv < 0.0 || $nv > 1.0} {
      error "arg to prob4 not a number >= 0 and <= 1.0"
    }
    return [set prob4 $nv]
  } ;# End method setp4

  method valid_element {el} {
    classvar CellBg
    return [info exists CellBg($el)]
  }

  method insert {} {
    my variable cells
    set empty {}
    foreach {k v} [array get cells] {
      if {$v eq {}} {
        lappend empty $k
      }
    }

    set cnt [llength $empty]

    if {! $cnt} {error "Attempt to insert into a full grid"}

    set newnum [expr {rand() > $prob4 ? 2 : 4}]
    set cellndx [lindex $empty [expr {int(rand()*$cnt)}]]

    my Update_cells [list $cellndx $newnum]

    return [expr $cnt - 1]
  } ;# End method insert

  method shift {direction} {
    my variable size cells
    # For Up or Down we're scanning column $i over $size rows
    # For Left or Right we're scanning row $i over $size columns
    # A given row or column is processed starting at the cell that is
    # furthest in the direction of shift and then working to the other end.

    switch $direction {
      Up {
        for {set j 0} {$j < $size} {incr j} {
          lappend cktemplate "$j\$i"
        }
      }
      Down {
        for {set j [expr {$size - 1}]} {$j >= 0} {incr j -1} {
          lappend cktemplate "$j\$i"
        }
      }
      Left {
        for {set j 0} {$j < $size} {incr j} {
          lappend cktemplate "\$\{i\}$j"
        }
      }
      Right {
        for {set j [expr {$size - 1}]} {$j >= 0} {incr j -1} {
          lappend cktemplate "\$\{i\}$j"
        }
      }
      default {
        error "bad direction $direction"
      }
    }

    set changes 0 ;# number of changed rows or columns
    set csetlist {} ;# an array-set-list of changes

    for {set i 0} {$i < $size} {incr i} {
      set ckeys [subst $cktemplate]
      set vals {}
      set merge 0

      foreach k $ckeys {
        set v $cells($k)
        if {$v eq {}} {continue}
        if {$v eq [lindex $vals end]  && ! $merge} {
          lset vals end [expr 2*$v]
          set merge 1
        } else {
          lappend vals $v
          set merge 0
        }
      }

      set vcnt [llength $vals]
      # if vals is empty or full, there's nothing to change for this row/col
      if {$vcnt == 0 || $vcnt == $size} {continue}

      for {set k 0} {$k < $size} {incr k} {
        set nv [expr {$k < $vcnt ? [lindex $vals $k] : {}}]
        set ndx [lindex $ckeys $k]
        if {$nv ne $cells($ndx)} {
          lappend csetlist $ndx $nv
        }
      }

      if {[llength $csetlist] == 0} {continue}

      incr changes
    } ;# End of looping over rows or cols

    my Update_cells $csetlist
    return $changes
  } ;# End method shift

  # True if a move can be made, false otherwise
  method playable {} {
    classvar NormalCnvBg WarnCnvBg
    my variable cells size

    set room [my room]
    if {$room > 1} {
      my setcnvbg $NormalCnvBg
      return 1
    }

    my setcnvbg $WarnCnvBg

    # Note that methods that implement undo and displaying the puzzle
    # are mixins that are directly applied to objects, which arent't
    # mixed into tst.
    set tst [[self class] new -size $size -cells [array get cells]]

    # note that for non-playable grid nothing changes under shift
    foreach d {Up Down Left Right} {
      if {[$tst shift $d]} {
        return 1
      }
    }

    $tst destroy
    return 0
  } ;# End method playable

  # Returns 0 if successful, 1 if nothing moved, 2 if game over
  method move {direction} {
    classvar OverCnvBg
    set state [array get cells]

    if {[my shift $direction] == 0} {return 1}
    if {[my room]} {my insert}
    if {! [my playable]} {
      my setcnvbg $OverCnvBg
      return 2
    }

    return 0
  } ;# End method move

  method setcnvbg {bg} {
    if {[info object isa mixin [self] ::display]} {
      my variable canvas
      $canvas configure -bg $bg
    }
  } ;# End method setcnvbg

  # Start or restart game
  method start {} {
    classvar NormalCnvBg
    my setcnvbg $NormalCnvBg

    my clear
    my insert; my insert
  } ;# End method start

  # Not exported - meant to be called by the display mixin
  method Canvas_init {} {
    classvar CellSize StartOffset CellSpacing CellRadius
    classvar NormalCnvBg CellBg
    classvar CellFont

    my variable canvas size

    $canvas configure -bg $NormalCnvBg

    set canvsize [expr {$size * $CellSize + ($size + 1) * $CellSpacing}]
    $canvas configure -width $canvsize -height $canvsize

    set celloffset [expr {$CellSize + $CellSpacing}]
    set txtoffset [expr {$CellSize / 2}]
    set startpos [expr {$CellSpacing + $StartOffset}]
    set y $startpos
    for {set i 0} {$i < $size} {incr i} {
      set x $startpos
      for {set j 0} {$j < $size} {incr j} {
        set sfx $i$j
        set lrx [expr {$x + $CellSize}]
        set lry [expr {$y + $CellSize}]
        set tx  [expr {$x + $txtoffset}]
        set ty  [expr {$y + $txtoffset}]

        roundRect $canvas $x $y $lrx $lry $CellRadius \
        -tag r$sfx -fill $CellBg() -outline black -width 2;

        $canvas create text $tx $ty -tag t$sfx -font $CellFont
        incr x $celloffset
      }
      incr y $celloffset
    }
  } ;# End method Canvas_init

  # Not exported - meant to be called by display mixin
  method Canvas_update {kvlist} {
    my variable canvas
    # expect to only be called from Update_cells, so it depends on
    # it to do kvlist validation

    foreach {sfx val} $kvlist {
      classvar CellBg
      $canvas itemconfigure t$sfx -text $val
      $canvas itemconfigure r$sfx -fill $CellBg($val)
    }
  } ;# End method Canvas_update

  method instructions {} {
    classvar Instructions
    return $Instructions
  }

} ;# End class create double
source_done DOUBLE
