#!/usr/bin/gnuplot

reset

set terminal svg enhanced size 300,250 font 'Arial,18'
set output '/out/dss.svg'

set style data histogram
set style histogram cluster gap 1

# Make axis labels easier to read.
set xtics font ",16" nomirror offset 0,0.25
set ytics nomirror
set logscale y 2
set yrange [4:600]

set grid

# offsets reduces the space at the extreme left & right borders
# to minimize white space
set offsets -0.2, -0.2, 0, 0

# ensure that y label doesn't take too much space
set ylabel "Alloc. Latency (cycles)" offset 2.5,0
set xlabel "# of allocated buffers" offset 0,0.8
set lmargin 7
set rmargin 1
set tmargin 0.5

set style fill pattern border -1

unset key

set label 'Heap' at -0.25,200 rotate by 90 font ",14"
set label 'Shared stack and DSS' at 0.15,7 rotate by 90 font ",14"

plot 'results/dss.dat' \
        using 2:xtic(1) ti col lc "black" fs pattern 1, \
     '' using 3         ti col lc "black" fs pattern 2, \
     '' using 4         ti col lc "black" fs pattern 6
