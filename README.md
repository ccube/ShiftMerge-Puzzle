# ShiftMerge-Puzzle
ShiftMerge is a puzzle written in Tcl/Tk similar to 2048 by Gabriele Cirulli
and Threes by Asher Vollmer

## Introduction

This project was initiated to teach myself Tcl/Tk, with which I plan to implement
a GUI on another project. So until it matures, don't expect it to be an
example of good Tcl/Tk usage.

I chose Cirulli's 2048 as a model since I've enjoyed it as a light weight
pastime when I'm waiting for something, and it won't require me to learn
anything else but Tcl/Tk itself. With that game, I'd always wanted a
way to undo my last move, so I'm aiming to provide that here. It would also be
fun to experiment with the size of the field, the relative frequency of the
4 vs the 2 for insertions, and other modes of play. In case of different modes
of play, they will all have these features in common:

- a square grid of cells that are either empty or contain compatible elements
- arrow keys shift elements into empty cells in the direction of the arrow,
leaving all empty spaces on the side of the grid opposite to the shift
- if, after a shift, adjacent non-empty elements meet conditions for the mode,
they will be merged and trailing elements will shifted into the resulting
empty cell(s)
- when the grid has no empty cells and no shift will merge anything, the
game is over

## Requirements
You will need Tcl/Tk installed on your system. This script was developed
using versions 8.6 of both Tcl and Tk.
