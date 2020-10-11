package require Tcl 8.6

if {[sourced_before UNDO]} {return}

# Intended as a mixin for class puzzle, it's subclasses and objects
# Probably a waste of space and cycles to mix it into instances that
# will be used for analysis which will probably need independant
# stacking systems.

oo::class create ::undo {
  export undo move mvcnt

  # stack of the contents of cells
  variable undostack

  method mixconf args {
    set undostack {}
    if {[llength [self next]]} {
      next {*}$args
    }
  } ;# End method mixconf

  method undo {} {
    my variable cells
    if {[llength $undostack]} {
      set prev_state [lindex $undostack end]
      set undostack [lreplace $undostack end end]
      binary scan $prev_state cu* clst
      my Update_cells $clst
    }
  } ;# End method undo

  method move {d} {
    my variable cells
    set state [binary format c* $cells]
    set ret [next $d]
    if {! $ret} {
      lappend undostack $state
    }
    return $ret
  } ;# End method move

  method start {} {
    set undostack {}
    next
  }

  method mvcnt {} {
    return [llength $undostack]
  }

} ;# End class create undo

source_done UNDO
