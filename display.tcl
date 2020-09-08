package require Tcl 8.6
package require Tk 8.6

if {[sourced_before DISPLAY]} {return}


# Intended as a mixin class for subclasses and objects of
# class ::puzzle to coordinate update of the playing field in Tk
oo::class create display {
  superclass ::puzzle

  variable canvas

  method mixconf args {
    if {[set ndx [lsearch $args -canvas]] < 0}  {
      error "display needs a -canvas arg"
    }
    set cnv [lindex $args [expr $ndx + 1]]
    set cls {}
    if {[catch {set cls [winfo class $cnv]}] || $cls ne "Canvas"} {
      error "not a canvas"
    }

    set canvas $cnv

    # Implemented in non-mixin subclass of puzzle
    my Canvas_init
    if {[llength [self next]]} {
      next {*}$args
    }
  } ;# End of method mixconf

  method Update_cells {kvlist} {
      next $kvlist
      # Implemented in non-mixin subclass of puzzle
      my Canvas_update $kvlist
  } ;#
} ;# End class create display

source_done DISPLAY
