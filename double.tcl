package require Tcl 8.6

if {[sourced_before DOUBLE]} {return}

source [file join $::smdir roundRect.tcl]
source [file join $::smdir util.tcl]
source [file join $::smdir puzzle.tcl]

oo::class create ::double {
  superclass ::puzzle

  classvar Default_Prob4 0.2
  classvar Instructions {Arrow keys to move, BackSpace or Control-z to Undo}

  # set in method Canvas_init so I can debug this without Tk being loaded
  classvar CellFont {}

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
  classvar CellBg {"#FFFFFF" "#FFFFF5" "#FFFDE0" "#FFF8CC" "#FFF3C2" "#FFE9AD"
                   "#FFDD99" "#FFCE85" "#FFBC70" "#FFA85C" "#FF9147" "#A0FFA0"
                   "#60F060" "#10E010" "#00D000" "#00C000" "#00B000" "#00A000"
                   "azure"   "azure"   "azure"   "azure"   "azure"   "azure"
                   "azure"   "azure"   "azure"   "azure"   "azure"   "azure"
                   "azure"   "azure"   "azure"   "azure"   "azure"   "azure"
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

  method insert {} {
    my variable numcells cells
    set empty {}
    for {set i 0} {$i < $numcells} {incr i} {
      if {[lindex $cells $i] == 0} {
        lappend empty $i
      }
    }

    set cnt [llength $empty]

    if {! $cnt} {error "Attempt to insert into a full grid"}

    set newnum [expr {rand() > $prob4 ? 1 : 2}]
    set cellndx [lindex $empty [expr {int(rand()*$cnt)}]]

    my Update_cells $newnum $cellndx

    return [expr $cnt - 1]
  } ;# End method insert

  # Shift the sequence (a list which may be either a row or column of cells)
  # from the end of the list to the beginning, filling empty spaces (0) and/or
  # merging same valued neighbors. Returns the result or if nothing was changed
  # (because there were no spaces and no mergeable neighbors) returns an
  # empty string.
  method shift1 {seq} {
    my variable size

    set vals {}
    set merge 0

    foreach v $seq {
      if {$v eq 0} {continue}
      if {$v eq [lindex $vals end]  && ! $merge} {
        lset vals end [expr $v + 1]
        set merge 1
      } else {
        lappend vals $v
        set merge 0
      }
    }

    set vcnt [llength $vals]

    # if vals is empty or full, there's nothing to change for this row/col
    if {$vcnt == 0 || $vcnt == $size} {
      return {}
    } else {
      while {[llength $vals] < $size} {
        lappend vals 0
      }
      return $vals
    }
  } ;# End method shift1

  # True if a move can be made, false otherwise
  method playable {} {
    classvar NormalCnvBg WarnCnvBg
    my variable cells

    if {[my room] > 1} {
      my setcnvbg $NormalCnvBg
      return 1
    }

    my setcnvbg $WarnCnvBg

    # Note that methods that implement undo and displaying the puzzle
    # are mixins that are directly applied to objects, which arent't
    # mixed into tst.
    set tst [[self class] new -cells $cells]

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

    set CellFont [font create -family "Comic Sans MS" -size 20]

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
        set suffx [expr $i * $size + $j]
        set lrx [expr {$x + $CellSize}]
        set lry [expr {$y + $CellSize}]
        set tx  [expr {$x + $txtoffset}]
        set ty  [expr {$y + $txtoffset}]

        roundRect $canvas $x $y $lrx $lry $CellRadius \
        -tag r$suffx -fill [lindex $CellBg 0] -outline black -width 2;

        $canvas create text $tx $ty -tag t$suffx -font $CellFont
        incr x $celloffset
      }
      incr y $celloffset
    }
  } ;# End method Canvas_init

  # Not exported - meant to be called by display mixin
  method Canvas_update {vlst {ndxlst {}}} {
    my variable cells canvas numcells
    classvar CellBg
    set loopbody {
      set val [lindex $cells $i]
      set txt [expr {$val == 0 ? "" : 1 << $val}]

      $canvas itemconfigure t$i -text $txt
      $canvas itemconfigure r$i -fill [lindex $CellBg $val]
    }

    if {$ndxlst eq {}} {
      for {set i 0} {$i < $numcells} {incr i} {
        eval $loopbody
      }
    } else {
      foreach i $ndxlst {
        eval $loopbody
      }
    }
  } ;# End method Canvas_update

  method instructions {} {
    classvar Instructions
    return $Instructions
  }
} ;# End class create double

source_done DOUBLE
