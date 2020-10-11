# Define classes for shiftmerge puzzles
package require Tcl 8.6

if {[sourced_before PUZZLE]} {return}

source [file join $::smdir util.tcl]
namespace import ::tcl::mathop::+

# Puzzle is the base class for the shiftmerge puzzle modes.
# All state is contained in a square array of elements.
# Subclasses provide move methods to receive events and call this class'
# unexported Update_cells method to change the state of the game.

# The default size of the array is 4x4, but by passing the -size option
# when the instance is created, you can specify the length of a side,
# but it must be a value between 3 & 6 inclusive.

# The contents of the array will be integers 0 .. (size**2 - 1).
# The subclasses may interpret these integers as they wish EXCEPT that 0
# must always be interpreted as EMPTY. So double (the subclass that implements
# a game similar to 2048), may interpret values > 0 as 2**value. Others
# may simply have an array or dict to map them to what they desire.

# An initial value for cells can be given with -cells, which expects
# a list of length size**2. Subclass constructors should convert the
# values THEY expect to  0 .. (size**2 - 1) before calling next.
# If you give both -size and -cells then they must agree on size.
# If you give just -cells, then that sets the size.
oo::class create ::puzzle {

  classvar Default_size 4
  classvar Valid_size {3 4 5 6}

  # Length of row or column
  variable size
  variable numcells

  # Hold elements. A list of length size**2, holding integers
  # >= 0 and < size**2, where a 0 indicates an empty cell.
  # The cell in row r, col c (both zero based) is represented by the
  # list element at index r * size + c.
  variable cells

  constructor args {
    classvar Default_size Valid_size

    set cells {}
    set size $Default_size
    set clst {}
    set size_arg 0

    foreach {opt val} $args {
      switch $opt {
        -cells {
          set clst $val
        }

        -size {
          if {$val ni $Valid_size} {
            error "invalid size ($val); must be in {$Valid_size}"
          }
          set size $val
          set size_arg 1
        }
      }
    }

    if {$clst ne {}} {
      foreach s $Valid_size {
        set sqrlen([expr $s * $s]) $s
      }
      set iclen [llength $clst]
      if {! [info exists sqrlen($iclen)]} {
        error "bad -cells list length ($iclen)"
      }

      set inferred_size $sqrlen($iclen)
      if {$size_arg && $inferred_size != $size} {
          error "-cells and -size disagree on size"
      }
      set numcells $iclen
      set size $inferred_size
    } else {
      set numcells [expr {$size * $size}]
      set clst [lrepeat $numcells 0]
    }

    my Update_cells $clst
  } ;# End constructor

  method cellndx {r c} {
    return [expr $r * $size + $c]
  } ;# End method cellndx

  # Coordinates subclasses and mixins
  method Update_cells {vlst {ndxlst {}}} {
    if {$ndxlst eq {}} {
      set cells $vlst
    } else {
      set cells [lmset $cells $vlst $ndxlst]
    }
  } ;# End method Update_cells

  method room {} {
    set emptycnt 0
    foreach v $cells {
      if {$v eq 0} {incr emptycnt}
    }
    set emptycnt
  } ;# End method room

  method clear {} {
    my Update_cells [lrepeat $numcells 0]
  } ;# End method clear

  #
  method shift {direction} {
    # Process columns (Up or Down) or rows (Left or Right)
    # Send column or row to subclass shift1 method starting
    # with the cell furthest in the direction we're shifting.
    # (e.g. Bottom for Down, Leftmost for Left, etc.)

    # Set parameters for outer & inner loops below in order
    # to achieve this processing order.
    switch $direction {
      Up -
      Down {
        set oset {set i 0}
        set otst {$i < $size}
        set onxt {incr i}
        if {$direction eq "Up"} {
          set iset {set j $i}
          set itst {$j < $numcells}
          set inxt {incr j $size}
        } else {
          set iset {set j [expr {$i + $numcells - $size}]}
          set itst {$j >= 0}
          set inxt {incr j [expr {- $size}]}
        }
      }

      Left -
      Right {
        set oset {set i 0}
        set otst {$i < $numcells}
        set onxt {incr i $size}
        if {$direction eq "Left"} {
          set iset {set j $i}
          set itst {$j < [expr {$i + $size}]}
          set inxt {incr j}
        } else {
          set iset {set j [expr {$i + $size - 1}]}
          set itst {$j >= $i}
          set inxt {incr j -1}
        }
      }
      default {
        error "bad direction $direction"
      }
    }
    set changes 0 ;# Number of calls to shift1 that result in a change
    set allindices {}
    set allvals    {}

    for $oset $otst $onxt {
      set indices {}
      for $iset $itst $inxt {
        lappend indices $j
      }
      lappend allindices {*}$indices
      set current [lmndx $cells $indices]
      set result [my shift1 $current]

      # If shift1 returns an empty string, then no change occurred for
      # that row/column.
      if {$result eq {}} {
        lappend allvals {*}$current
      } else {
        lappend allvals {*}$result
        incr changes
      }
    }
    my Update_cells $allvals $allindices

    return $changes
  } ;# End method shift
} ;# End oo::class create puzzle

source_done PUZZLE
