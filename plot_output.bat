set datafile separator ","
set style fill solid
#set xlabel "Establishment"
set xtics rotate by -60
unset key

set term png transparent truecolor

set style line 1 lc rgb "blue"
set style line 2 lc rgb "green"
set style line 3 lc rgb "green"
rgbFn(r,g,b) = 65536*int(r) + 256*int(g) + int(b)
ColumnToColor(c) = (c <= 8) ? rgbFn(47,118,183) : ((c <= 15) ? rgbFn(68,127,62) : ((c <= 20) ? rgbFn(160,27,55) : rgbFn(117,46,140)))

# NOTE:
# Output 1: Default
# Output 2: With a force-buy-landmark requirement in the bot
# Output 3: With always-roll-2-if-you-can (instead of randoming)
# Output 4: With always-activate-harbor
# Output 5: With only-2-tuna-boats-instead-of-6
# Output 6: Back to sometimes-activate-harbor
# Output 7: 6 Tuna boats, always activate harbor, but only roll 1 die when they do activate to get coins
# Output 8: Same as 7, but also back to sometimes-activate-harbor

set ylabel "Average # owned by the winning player"
set output 'output_1_purchased.png'
plot "output_1.dat" using 0:2:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_2_purchased.png'
plot "output_2.dat" using 0:2:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_3_purchased.png'
plot "output_3.dat" using 0:2:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_4_purchased.png'
plot "output_4.dat" using 0:2:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_5_purchased.png'
plot "output_5.dat" using 0:2:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_6_purchased.png'
plot "output_6.dat" using 0:2:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_7_purchased.png'
plot "output_7.dat" using 0:2:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_8_purchased.png'
plot "output_8.dat" using 0:2:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable

set ylabel "Average coins earned by the winning player"
set output 'output_1_earned_winner.png'
plot "output_1.dat" using 0:3:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_2_earned_winner.png'
plot "output_2.dat" using 0:3:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_3_earned_winner.png'
plot "output_3.dat" using 0:3:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_3b_earned_winner.png'
plot "output_3b.dat" using 0:3:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_3c_earned_winner.png'
plot "output_3c.dat" using 0:3:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_4_earned_winner.png'
plot "output_4.dat" using 0:3:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_5_earned_winner.png'
plot "output_5.dat" using 0:3:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_6_earned_winner.png'
plot "output_6.dat" using 0:3:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_7_earned_winner.png'
plot "output_7.dat" using 0:3:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_8_earned_winner.png'
plot "output_8.dat" using 0:3:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable

set ylabel "Average coins earned by all players"
set output 'output_1_earned_all.png'
plot "output_1.dat" using 0:4:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_2_earned_all.png'
plot "output_2.dat" using 0:4:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_3_earned_all.png'
plot "output_3.dat" using 0:4:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_3b_earned_all.png'
plot "output_3b.dat" using 0:4:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_3c_earned_all.png'
plot "output_3c.dat" using 0:4:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_4_earned_all.png'
plot "output_4.dat" using 0:4:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_5_earned_all.png'
plot "output_5.dat" using 0:4:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_6_earned_all.png'
plot "output_6.dat" using 0:4:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_7_earned_all.png'
plot "output_7.dat" using 0:4:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
set output 'output_8_earned_all.png'
plot "output_8.dat" using 0:4:(0.5):(ColumnToColor($0)):xtic(1) with boxes lc rgbcolor variable
