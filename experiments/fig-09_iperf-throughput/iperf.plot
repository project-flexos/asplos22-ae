#!/usr/bin/gnuplot

reset

set terminal svg enhanced size 650,300 font 'Arial,20'
set output '/out/iperf.svg'

set grid

# Make the x axis labels easier to read.
set xtics font ",18" nomirror
set ytics nomirror

# make sure that the legend doesn't take too much space
set key inside bottom right samplen 1 font ',18' width -7

# ensure that y label doesn't take too much space
set ylabel "iPerf throughput (Gb/s)" offset 2.5,0
set xlabel "Receive Buffer Size" offset 0,0.5

# remove useless margins
#set bmargin 2
set lmargin 7
set rmargin 1
set tmargin 0.5

# use logscale, display powers of two
set logscale x 2
set logscale y 2
set format x '2^{%L}'

# line styles
set style line 1 \
    linecolor rgb '#2C1320' \
    linetype 1 linewidth 2 \
    pointtype 7 pointsize 0.5
set style line 2 \
    linecolor rgb '#66A182' \
    linetype 1 linewidth 2 \
    pointtype 5 pointsize 0.5
set style line 3 \
    linecolor rgb '#7F95D1' \
    linetype 1 linewidth 2 \
    pointtype 11 pointsize 0.5
set style line 4 \
    linecolor rgb '#306BAC' \
    linetype 1 linewidth 2 \
    pointtype 9 pointsize 0.5
set style line 5 \
    linecolor rgb '#AF9BB6' \
    linetype 1 linewidth 2 \
    pointtype 13 pointsize 0.5

# use this to set the range, although the default one seems to be good here
#set yrange [0:3.5]
set xrange [16:16384]

plot '/out/results/iperf.dat' \
        index 0 with linespoints linestyle 1 t "Unikraft", \
     '' index 1 with linespoints linestyle 2 t "FlexOS NONE", \
     '' index 3 with linespoints linestyle 3 t "FlexOS MPK2-light", \
     '' index 2 with linespoints linestyle 4 t "FlexOS MPK2-dss", \
     '' index 4 with linespoints linestyle 5 t "FlexOS EPT2"
