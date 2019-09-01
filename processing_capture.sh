#!/bin/bash
read -p "Source IP address: " src_ip
read -p "Destiny IP address (public): " dst_ip_pub
read -p "Destiny IP address (private): " dst_ip_pri
mkdir results_remote
mkdir results_sniffer
cd ./captures_remote/
echo "Proccessing remote captures"
for x in `ls`
	do
		../buffer $src_ip $dst_ip_pri $x 0
		cp $x.csv ../results_remote
		cp $x.txt ../results_remote
		cp graphic_$x.csv ../results_remote
done
#rm *.csv
#rm *.txt
echo "Done"
cd ..
cd ./captures_sniffer/
echo "Proccessing sniffer's captures"
for x in `ls`
	do
		../buffer $src_ip $dst_ip_pub $x 1
		cp $x.csv ../results_sniffer
		cp $x.txt ../results_sniffer
		cp graphic_$x.csv ../results_sniffer
done
#rm *.csv
#rm *.txt
echo "Done"
cd ..
cd ./results_remote
echo "Proccessing remote graphics"
for x in `ls graphic_*.csv`
	do
		cp $x $x.txt
		sed -i "s/,/ /g" $x.txt
		echo "set terminal png" > graphic.gnuplot
		echo "set autoscale	# scale axes automatically" >> graphic.gnuplot
		echo "unset log	# remove any log-scaling" >> graphic.gnuplot
		echo "unset label	# remove any previous labels" >> graphic.gnuplot
		echo "set xtic auto	# set xtics automatically" >> graphic.gnuplot
		echo "set ytic auto	# set ytics automatically" >> graphic.gnuplot
		echo "set output '$x.png'" >> graphic.gnuplot
		echo "set key bottom right nobox" >> graphic.gnuplot
		echo "set title 'Buffer occupancy for different packet size'" >> graphic.gnuplot
		echo "set xlabel 'Time (microseconds)'" >> graphic.gnuplot
		echo "set ylabel 'Buffer occupancy (packets)'" >> graphic.gnuplot
		echo "plot '$x.txt' w lines" >> graphic.gnuplot
		gnuplot < graphic.gnuplot
		rm $x.txt graphic.gnuplot
done
echo "Done"
cd ..
cd ./results_sniffer
echo "Proccessing sniffer's graphics"
for x in `ls graphic_*.csv`
	do
		cp $x $x.txt
		sed -i "s/,/ /g" $x.txt
		echo "set terminal png" > graphic.gnuplot
		echo "set autoscale	# scale axes automatically" >> graphic.gnuplot
		echo "unset log	# remove any log-scaling" >> graphic.gnuplot
		echo "unset label	# remove any previous labels" >> graphic.gnuplot
		echo "set xtic auto	# set xtics automatically" >> graphic.gnuplot
		echo "set ytic auto	# set ytics automatically" >> graphic.gnuplot
		echo "set output '$x.png'" >> graphic.gnuplot
		echo "set key bottom right nobox" >> graphic.gnuplot
		echo "set title 'Buffer occupancy for different packet size'" >> graphic.gnuplot
		echo "set xlabel 'Time (microseconds)'" >> graphic.gnuplot
		echo "set ylabel 'Buffer occupancy (packets)'" >> graphic.gnuplot
		echo "plot '$x.txt' w lines" >> graphic.gnuplot
		gnuplot < graphic.gnuplot
		rm $x.txt graphic.gnuplot
done
echo "Done"
