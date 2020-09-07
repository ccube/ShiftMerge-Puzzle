# Define classes for shiftmerge puzzles
package require Tcl 8.6
#package require Tk 8.6

if {[sourced_before PUZZLE]} {return}

# Puzzle is the base class for the shiftmerge puzzle modes.
# All state is contained in a square array of elements and empty cells.
# Subclasses provide move methods to receive arrow key events and
# call this class' unexported Update_cells method to change the state
# of the game.

oo::class create ::puzzle {

  classvar Default_size 4
  classvar Valid_size {3 4 5 6}

  # Length of row or column
  variable size

  # Hold elements
  variable cells

  constructor args {
    classvar Default_size Valid_size

    set size $Default_size
    set init_cells {}

    foreach {opt val} $args {
      switch $opt {
        -cells {
          set init_cells $val
        }

        -size {
          if {$val ni $Valid_size} {
            error "invalid size ($val); must be in {$Valid_size}"
          }
          set size $val
        }
      }
    }

    # The names in cells is used to validate keys in init_cells
    # and init_cells may contain only the non-empty values
    for {set i 0} {$i < $size} {incr i} {
      for {set j 0} {$j < $size} {incr j} {
        set cells($i$j) {}
      }
    }

    if {$init_cells ne {}} {
      my Update_cells $init_cells
    }
  } ;# End constructor

  # Not exported
  method Validate_Cells_setlist {csl} {
    set cslen [llength $csl]
    if {$cslen % 2} {
      error "arg list not an even length"
    }

    set maxcsl [expr $size * $size * 2]
    if {$cslen > $maxcsl} {
      error "arg list too large (length > $maxcsl)"
    }

    foreach {k v} $csl {
      if {![info exists cells($k)]} {
        error "arg list key ($k) not in cells"
      }
      if {![my valid_element $v]} {
        error "arg list val ($v) not valid"
      }
    }
  } ;# End method Validate_Cells_setlist

  # Takes an argument list like the last arg to array set name
  # Only need to supply changed values
  # Not exported
  method Update_cells {kvlist} {
    my Validate_Cells_setlist $kvlist

    array set cells $kvlist
  } ;# End method Update_cells

  method load {kvlist} {
    my Validate_Cells_setlist $kvlist
    set undostack {}
    my clear
    my Update_cells $kvlist
  } ;# End method load

  method room {} {
    set emptycnt 0
    foreach k [array names cells] {
      if {$cells($k) eq {}} {incr emptycnt}
    }
    return $emptycnt
  } ;# End method room

  method clear {} {
    my variable cells

    set asl {}
    foreach k [array names cells] {
      if {$cells($k) ne {}} {
        lappend asl $k {}
      }
    }

    my Update_cells $asl
  } ;# End method clear

} ;# End oo::class create puzzle

source_done PUZZLE
