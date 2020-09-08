package require Tcl 8.6

if {[sourced_before UTIL]} {return}

# Stolen from tcllib ooutil.tcl by Donal Fellows
# but I'm going to give me no rope to hang myself with: if I'm using
# classvar, I will define it as classvar. Used inside method definition to
# link class variable "name" (and any others in args) to local variables of
# the same name
proc ::oo::Helpers::classvar {name args} {
    # Get a reference to the class's namespace
    set ns [info object namespace [uplevel 1 {self class}]]

    # Double up the list of variable names
    set vs [list $name $name]
    foreach v $args {lappend vs $v $v}

    # Lastly, link the caller's local variables to the class's
    # variables
    uplevel 1 [list namespace upvar $ns {*}$vs]
}

# This classvar works like namespace "variable". Used in define script or as
# a define subcommand. Takes a name and a required intial value. If
# val is a list whose 1st element is ARRAY, then the remainder of that
# list is used to array set name. If you intend to use name as an array,
# you must at least pass a val of ARRAY to intialize it to an empty array.
# Note that if you plan to treat the variable as a number (e.g. use incr),
# you must initialize it to a number


proc ::oo::define::classvar {name val} {
  set class [lindex [info level -1] 1]
  set ns [info object namespace $class]
  set nm "${ns}::$name"
  if {[lindex $val 0] eq "ARRAY"} {
    array set $nm [lreplace $val 0 0]
  } else {
    set $nm $val
  }
}

# Example:
# oo::class create foo {
#   classvar a 17
#   classvar b ARRAY
#   classvar totcnt 0
#
#   variable nm icnt
#
#   constructor {} {
#     set objns [info object namespace [self]]
#     set clsns [info object namespace [self class]]
#
#     set icnt 0 ;# to get icnt to show up in info vars
#     set nm [lindex [info level 0] 2]
#
#     set cv [lmap v [info vars ${clsns}::*] {namespace tail $v}]
#     set iv [lmap v [info vars ${objns}::*] {namespace tail $v}]
#     puts "Class vars: {$cv}"
#     puts "Instance vars: {$iv}"
#   }
#
#   method show {n} {
#     classvar a b totcnt
#     lappend b($nm) $n
#     incr totcnt
#     incr icnt
#     incr a $n
#     puts "a: $a $nm calls: $icnt all calls: $totcnt history: {$b($nm)}"
#   }
# }
# foo create x
# x show 5          ;# -> a: 22 x calls: 1 all calls: 1 history: {5}
# x show 3          ;# -> a: 25 x calls: 2 all calls: 2 history: {5 3}
# foo create y
# y show 11         ;# -> a: 36 y calls: 1 all calls: 3 history: {11}
# x show -7         ;# -> a: 29 x calls: 3 all calls: 4 history: {5 3 -7}
# y show 100        ;# -> a: 129 y calls: 2 all calls: 5 history: {11 100}
source_done UTIL