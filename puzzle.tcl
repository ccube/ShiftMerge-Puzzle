# Define classes for shiftmerge puzzles
package require Tcl 8.6
package require Tk 8.6

source roundRect.tcl

namespace eval pzl {

  namespace export puzzle

  set Default_Prob4 0.2
  set Instructions {Use arrow keys to shift, BackSpace or Control-z to Undo}


  # Constants used to intialize playing field
  # and manipulate canvas
  # Dimensions in pixels

  set CellSize 80
  set StartOffset 3
  set CellSpacing 16
  set CellRadius 14
  set NormalCnvBg bisque3
  set WarnCnvBg yellow3
  set OverCnvBg red3
  array set CellBg {
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
    2048    #A0FFA0
    4096    #60F060
    8192    #10E010
    16384   #00D000
    32768   #00B000
  }

  variable Cell_Keys
  if {! [info exists Cell_Keys] } {
    for {set i 0} {$i < 4} {incr i} {
      for {set j 0} {$j < 4} {incr j} {
         set Cell_Keys(${i}${j}) {}
      }
    }
  }

  font create CellFont -family "Comic Sans MS" -size 20

  # An object of class puzzle contains puzzle state and has
  # methods to manipulate the puzzle, to get information about
  # the state, and to display it (if a canvas is supplied).
  # puzzle objects not connected to a display may be used to analyze
  # the puzzle by exploring potential moves

  oo::class create puzzle {
    # instance variables

    # Hold elements
    variable cells

    # $canvas eq {} or [winfo class $canvas] eq Canvas
    variable canvas

    # probability of a 4 being inserted
    variable prob4

    # stack of cell contents - move pushes, undo - pops
    variable undostack

    # puzzle new ?-cells array-set-list? ?-canvas canvas?
    # or
    # puzzle create name ?-cells array-set-list? ?-canvas canvas?
    # If you're supplying array-set-list to initialize cells it only
    # need supply the non-empty cells and takes the form
    #     cellndx element cellndx element ...
    # where cellndx ranges over 00 .. 03 10 .. 13 20 .. 23 30 .. 33
    # and the 1st digit indicates row, 2nd digit indicates column
    # array names pzl::Cell_Keys gives you a list of valid cellndx
    # array names pzl::CellBg gives you a list of valid elements
    constructor args {
      my variable cells canvas prob4 undostack

      set prob4 $pzl::Default_Prob4
      set undostack {}

      array set cells [array get pzl::Cell_Keys]
      set canvas {}

      array set argarr $args

      foreach {opt val} $args {
        switch $opt {
          -canvas {
            set cls {}
            if {[catch {set cls [winfo class $val]}] || $cls ne {Canvas}} {
              error "-class arg not a canvas"
            }
            set canvas $val
            my Canvas_init
          }
          -cells {
            my Update_cells $val
          }
          default {
            error "only -cells and -canvas acceptable to pzl::puzzle constructor"
          }
        }
      }
    } ;# End constructor

    method Validate_Cells_setlist {csl} {
      set cslen [llength $csl]
      if {$cslen % 2} {
        error "-cells arg must be list of even length"
      }

      if {$cslen > 4*4*2} {
        error "-cells arg list too large (length > 32)"
      }

      foreach {k v} $csl {
        if {![info exists pzl::Cell_Keys($k)]} {
          error "-cells arg list key ($k) not in pzl::Cell_Keys"
        }
        if {![info exists pzl::CellBg($v)]} {
          error "-cells arg list val ($v) not valid"
        }
      }
    }

    # With no argument returns current value of prob4
    # with a valid value (0 <= $nv <= 1.0), sets prob4
    # Note the default value is in ::pzl::Default_Prob4
    method prob4 {nv} {
      my variable prob4
      if {$nv eq {}} {
        return $prob4
      }

      if {! [regexp {^(1\.0+|0?\.\d+)$} $nv]} {
        error "arg to prob4 not a number >= 0 and <= 1.0"
      }
      return [set prob4 $nv]
    }

    # Not exported
    method Canvas_init {} {
      my variable canvas
      $canvas configure -bg $pzl::NormalCnvBg

      set canvsize [expr {4 * $pzl::CellSize + 5* $pzl::CellSpacing}]
      $canvas configure -width $canvsize -height $canvsize

      set celloffset [expr {$pzl::CellSize + $pzl::CellSpacing}]
      set txtoffset [expr {$pzl::CellSize / 2}]
      set startpos [expr {$pzl::CellSpacing + $pzl::StartOffset}]
      set y $startpos
      for {set i 0} {$i < 4} {incr i} {
        set x $startpos
        for {set j 0} {$j < 4} {incr j} {
          set sfx $i$j
          set lrx [expr {$x + $pzl::CellSize}]
          set lry [expr {$y + $pzl::CellSize}]
          set tx  [expr {$x + $txtoffset}]
          set ty  [expr {$y + $txtoffset}]

          roundRect $canvas $x $y $lrx $lry $pzl::CellRadius \
          -tag r$sfx -fill $pzl::CellBg() -outline black -width 2;

          $canvas create text $tx $ty -tag t$sfx -font CellFont
          incr x $celloffset
        }
        incr y $celloffset
      }
    }

    # Not exported
    method Canvas_update {kvlist} {
      my variable canvas
      # expect to only be called from Update_cells, so it depends on
      # it to do kvlist validation

      foreach {sfx val} $kvlist {
        $canvas itemconfigure t$sfx -text $val
        set bg $pzl::CellBg($val)
        $canvas itemconfigure r$sfx -fill $bg
      }
    }

    # Takes an argument list like the last arg to array set name
    # Only need to supply changed values
    # Not exported
    method Update_cells {kvlist} {
      my variable cells canvas
      my Validate_Cells_setlist $kvlist

      array set cells $kvlist

      if {$canvas ne {}} {
        my Canvas_update $kvlist
      }
    } ;# End method update_cells

    method load {kvlist} {
      my variable undostack
      my Validate_Cells_setlist $kvlist
      set undostack {}
      my clear
      my Update_cells $kvlist
    } ;# End method load

    method room {} {
      my variable cells

      set emptycnt 0
      foreach k [array names cells] {
        if {$cells($k) eq {}} {incr emptycnt}
      }
      return $emptycnt
    } ;# End method room

    method clear {} {
      my variable cells

      set asl {}
      foreach k [array names pzl::Cell_Keys] {
        lappend asl $k {}
      }

      my Update_cells $asl
    }

    method insert {} {
      my variable cells prob4

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
      set cktemplate {}; #  A list of row or column keys in processing order

      # For Up or Down we're scanning column $i over 4 rows
      # For Left or Right we're scanning row $i over 4 columns
      # A given row or column is processed starting at the cell that is
      # furthest in the direction of shift and then working to the other end.

      switch $direction {
        Up {
          for {set j 0} {$j < 4} {incr j} {
            lappend cktemplate "$j\$i"
          }
        }
        Down {
          for {set j 3} {$j >= 0} {incr j -1} {
            lappend cktemplate "$j\$i"
          }
        }
        Left {
          for {set j 0} {$j < 4} {incr j} {
            lappend cktemplate "\$\{i\}$j"
          }
        }
        Right {
          for {set j 3} {$j >= 0} {incr j -1} {
            lappend cktemplate "\$\{i\}$j"
          }
        }
      }

      set changes 0 ;# number of changed rows or columns
      set csetlist {} ;# an array-set-list of changes

      for {set i 0} {$i < 4} {incr i} {
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
      	if {$vcnt == 0 || $vcnt == 4} {continue}

      	for {set k 0} {$k < 4} {incr k} {
      	    set nv [expr {$k < $vcnt ? [lindex $vals $k] : {}}]
      	    set ndx [lindex $ckeys $k]
      	    if {$nv ne $cells($ndx)} {
              lappend csetlist $ndx $nv
      	    }
      	}

      	if {[llength $csetlist] == 0} {continue}
      	incr changes
      }

      my Update_cells $csetlist
      return $changes

    } ;# End method shift

    # Returns 0 if successful, 1 if nothing moved, 2 if game over
    method move {direction} {
      my variable cells undostack

      set state [array get cells]

      if {[my shift $direction] == 0} {return 1}
      if {[my room]} {my insert}
      if {! [my playable]} {
        if {$canvas ne {}} {
          $canvas configure -bg $pzl::OverCnvBg
        }
        return 2
      }

      lappend undostack $state
      return 0
    } ;# End method move

    # True if a move can be made, false otherwise
    method playable {} {
      my variable cells
      set room [my room]
      if {$room > 1} {
        if {$canvas ne {}} {$canvas configure -bg $pzl::NormalCnvBg}
        return 1
      }

      if {$canvas ne {}} {
        $canvas configure -bg $pzl::WarnCnvBg
      }

      set tst [pzl::puzzle new -cells [array get cells]]

      # note that for non-playable grid nothing changes under shift
      foreach d {Up Down Left Right} {
        if {[$tst shift $d]} {
          return 1
        }
      }

      $tst destroy
      return 0
    } ;# End method playable

    # Returns 0 if undo successful, 1 means that stack was empty
    method undo {} {
      my variable cells undostack
      if {[llength $undostack] == 0} {return 1}

      set prevstate [lindex $undostack end]
      set undostack [lreplace $undostack end end]
      my Update_cells $prevstate
      return 0
    } ;# End method undo

    # Start or restart game
    method start {} {
      my variable cells undostack

      set undostack {}
      if {$canvas ne {}} {
        $canvas configure -bg $pzl::NormalCnvBg
      }
      my clear
      my insert; my insert
    } ;# End method start

    method getrow {i} {
      my variable cells

      for {set j 0} {$j < 4} {incr j} {
        lappend retlst $cells($i$j)
      }
      return $retlst
    }
  } ;# End oo::class create puzzle

} ;# End namespace eval
