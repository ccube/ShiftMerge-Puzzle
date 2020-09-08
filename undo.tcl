package require Tcl 8.6

if {[sourced_before UNDO]} {return}

# Intended as a mixin for class puzzle, it's subclasses and objects
# Probably a waste of space and cycles to mix it into instances that
# will be used for analysis which will probably need independant
# stacking systems.

oo::class create ::undo {
  export undo load move mvcnt

  # stack of the contents of cells
  variable undostack

  method mixconf args {
    set undostack {}
    if {[llength [self next]]} {
      next {*}$args
    }
  } ;# End method mixconf

  method push_state {} {
    my variable cells

    lappend undostack array get cells
  } ;# End method push_state

  method undo {} {
    my variable cells
    set prev_state [lindex $undostack end]
    set undostack [lreplace $undostack end end]
    my Update_cells $prev_state
  } ;# End method undo

  method move {d} {
    my variable cells
    set state [array get cells]
    set ret [next $d]
    if {! $ret} {
      lappend undostack $state
    }
    return $ret
  } ;# End method move

  method load {kvl} {
    next $kvl
    set undostack {}
  }

  method start {} {
    set undostack {}
    next
  }

  method mvcnt {} {
    return [llength $undostack]
  }

} ;# End class create undo

source_done UNDO
