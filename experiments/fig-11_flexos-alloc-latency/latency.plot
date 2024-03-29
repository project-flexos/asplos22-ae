#!/usr/bin/gnuplot

reset

set terminal svg enhanced size 300,250 font 'Arial,18'
set output '/out/latency.svg'

set grid
set style fill pattern border -1
set style data histogram
set xtic right nomirror rotate by 30 font ",16" scale 0
set ytic nomirror
set ylabel "Gate Latency (cycles)" offset 2.5,0

#set logscale y 2
set lmargin 7
set bmargin 2.5
set rmargin 1
set tmargin 0.5

set xrange [0:9]
set yrange [0:800]
set boxwidth 0.5

set label "2"   at 0.80,55  font ",16"
set label "62"  at 2.60,117 font ",16"
set label "108" at 3.40,161 font ",16"
set label "462" at 4.41,515 font ",16"
set label "470" at 6.40,523 font ",16"
set label "146" at 7.40,199 font ",16"

set label "all"    at 0.60,700 font ",16"
set label "FlexOS" at 2.80,700 font ",16"
set label "Linux"  at 6.65,700 font ",16"

set arrow from 2, graph 0 to 2, graph 1 nohead
set arrow from 6, graph 0 to 6, graph 1 nohead

plot "/out/results/latency.dat" \
		   every 6::0 using 1:3:xtic(2) with boxes fs pattern 1 lc "black" notitle, \
                "" every 6::1 using 1:3:xtic(2) with boxes fs pattern 2 lc "black" notitle, \
                "" every 6::2 using 1:3:xtic(2) with boxes fs pattern 6 lc "black" notitle, \
                "" every 6::3 using 1:3:xtic(2) with boxes fs pattern 1 lc "black" notitle, \
                "" every 6::4 using 1:3:xtic(2) with boxes fs pattern 7 lc "black" notitle, \
                "" every 6::5 using 1:3:xtic(2) with boxes fs pattern 8 lc "black" notitle
