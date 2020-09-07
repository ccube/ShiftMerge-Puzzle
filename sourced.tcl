package require Tcl 8.6

if {[info procs ::src::sourced_before] ne {}} {return}

# Provide a way for source files that want to be included only once
# to use a mechanism similar to C include files. This should have
# no effect on non-participating scripts. This script should be sourced
# by the toplevel or highest level script that expects this behavior.

# Used like this:
#  if {::src::sourced_before(TAG)} {return}
# ... Rest of module or script
# ::src::source_done(TAG)
#
namespace eval ::src {
   namespace export sourced sourced_before source_done
   variable sourced

   # If no arg provided, returns tags of participating scripts that have
   # been loaded along with the full pathname for where that tag was set
   # by source_done in an list suitable for array set (ie alternating tags
   # and pathnames). Otherwise, return the same thing as above, but only for
   # tags that match one of the args.
   proc sourced args {
     variable sourced
     if {[llength $args] == 0} {
       return [array get sourced]
     }

     foreach tag $args {
       if {[info exists sourced($tag)]} {
         set ret($tag) $sourced($tag)
       }
     }
     return [array get ret]
   }

   proc sourced_before {tag} {
     variable sourced

     return [info exists sourced($tag)]
   }

   proc source_done {tag} {
     variable sourced
     set sourced($tag) [file normalize [info script]]
   }
}

#To test, create files the following files in different directories

#contents of asrc.tcl:
#if {[sourced_before ASRC]} {return}
#puts "   Sourcing [info script]"
#source_done ASRC

#contents of bsrc.tcl
#if {[sourced_before BSRC]} {return}
#puts "   Sourcing [info script]"
#source_done BSRC

# then uncomment below, changing the paths to what you used

# namespace import ::src::source*
# set
# puts "First source of a"
# source asrc.tcl
#
# puts "First source of b"
# source ../../../sandbox/bsrc.tcl
#
# puts "Second source of a"
# source asrc.tcl
#
# puts "Second source of b"
# source ../../../sandbox/bsrc.tcl
#
# puts "[sourced BSRC]"
#
# array set foo [sourced]
# parray foo
#
# array set bar [sourced GOO ASRC]
# parray bar

::src::source_done SOURCED
