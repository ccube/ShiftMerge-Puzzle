package require Tcl 8.6

# If you want to debug a file in isolation from the main program,
# source this prior to sourcing what you want to debug. Assumes your
# pwd is the directory where these files are located

set ::smdir .
source sourced.tcl
namespace path {::src}
