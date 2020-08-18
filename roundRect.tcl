 #----------------------------------------------------------------------
 #
 # roundRect --
 #
 #       Draw a rounded rectangle in the canvas.
 #
 # Parameters:
 #       w - Path name of the canvas
 #       x0, y0 - Co-ordinates of the upper left corner, in pixels
 #       x3, y3 - Co-ordinates of the lower right corner, in pixels
 #       radius - Radius of the bend at the corners, in any form
 #                acceptable to Tk_GetPixels
 #       args - Other args suitable to a 'polygon' item on the canvas
 #
 # Results:
 #       Returns the canvas item number of the rounded rectangle.
 #
 # Side effects:
 #       Creates a rounded rectangle as a smooth polygon in the canvas.
 #
 # Author: Laurent Duperval
 #   (see https://wiki.tcl-lang.org/page/Drawing+rounded+rectangles)
 #----------------------------------------------------------------------

 proc roundRect { w x0 y0 x3 y3 radius args } {

    set r [winfo pixels $w $radius]
    set d [expr { 2 * $r }]

    # Make sure that the radius of the curve is less than 3/8
    # size of the box!

    set maxr 0.75

    if { $d > $maxr * ( $x3 - $x0 ) } {
        set d [expr { $maxr * ( $x3 - $x0 ) }]
    }
    if { $d > $maxr * ( $y3 - $y0 ) } {
        set d [expr { $maxr * ( $y3 - $y0 ) }]
    }

    set x1 [expr { $x0 + $d }]
    set x2 [expr { $x3 - $d }]
    set y1 [expr { $y0 + $d }]
    set y2 [expr { $y3 - $d }]

    set cmd [list $w create polygon]
    lappend cmd $x0 $y0
    lappend cmd $x1 $y0
    lappend cmd $x2 $y0
    lappend cmd $x3 $y0
    lappend cmd $x3 $y1
    lappend cmd $x3 $y2
    lappend cmd $x3 $y3
    lappend cmd $x2 $y3
    lappend cmd $x1 $y3
    lappend cmd $x0 $y3
    lappend cmd $x0 $y2
    lappend cmd $x0 $y1
    lappend cmd -smooth 1
    return [eval $cmd $args]
 }

 # Demonstration program

 # grid [canvas .c -width 600 -height 300]
 # grid [scale .s -orient horizontal \
 #          -label "Radius" \
 #          -variable rad -from 0 -to 200 \
 #          -command doit] \
 #    -sticky ew

 # proc doit { args } {

 #    global rad

 #    .c delete rect
 #    roundRect .c 100 50 500 250 $rad -fill white -outline black -tags rect
 # }
