#!/bin/bash
# this script receives in order: IP-source, IP-destiny, capture and
# proccesing_capture generates a file (txt and csv) with the next structure:
#
#	column 1	packet number
#	column 2	serial number
#	column 3	packet size
#	column 4	interarrival packet time (microseconds)
#	column 5	normalized capture time (microseconds)
#	column 6	dropped packets
#	column 7	buffer's output rate (Mbps)
#	column 8	buffer's input rate (Mbps)
#	column 9	buffer size (packets)
#
####################################################################################################
# filtering tcpdump capture
tcpdump -r $3 -nn -tt src $1 and dst $2 and udp -X > parser_$3.txt
####################################################################################################
# function name: convert_columns #
##################################
# obtainig time, length and serial number in hex
# changes the line number for next packet (6:remote and 7:local)
if [ $4 == 0 ]
then
awk '
BEGIN {
	FS=" "
	cont=1
}
{
if (cont==1) { # for first line, takes time and packet length
	printf $1 " " # print time
	printf $8 " " # print length
}
if (cont==3) { # thirth line allowos beginning of serial number
	printf $9
}
if (cont==4) { # fourth line allowos the rest of serial number
	printf $2
	printf $3 "\n"
}
cont++
if (cont==7) { # changes the line number for next packet
	cont=1
}
}
' parser_$3.txt > temp1.txt
fi
if [ $4 == 1 ]
then
awk '
BEGIN {
	FS=" "
	cont=1
}
{
if (cont==1) { # for first line, takes time and packet length
	printf $1 " " # print time
	printf $8 " " # print length
}
if (cont==3) { # thirth line allowos beginning of serial number
	printf $9
}
if (cont==4) { # fourth line allowos the rest of serial number
	printf $2
	printf $3 "\n"
}
cont++
if (cont==6) { # changes the line number for next packet
	cont=1
}
}
' parser_$3.txt > temp1.txt
fi
####################################################################################################
# swap and erasing ( and )
awk 'BEGIN{}{printf $3 "\t" $1 "\t" $2 "\n"}' temp1.txt > temp.txt
sed -i "s/)//g" temp.txt 
sed -i "s/(//g" temp.txt
cp temp.txt temp1.txt
rm temp.txt
####################################################################################################
# function name: serial_number #
################################
# obtaining serial number
awk '
BEGIN {
	FS=""a
	pos=1
}
{
while (pos<13) { # serial number end
	if (substr($pos,1) == "3") {
		pos=pos+1
		printf $pos 
		pos=pos+1
	}
	if (substr($pos,1) == "2") {
		pos=13
		}
}
printf "\n"
pos=1
}
' temp1.txt > temp2.txt
####################################################################################################
# swap
awk '
BEGIN{}
{
getline a < "temp2.txt"
printf $2 "\t" $3 "\t" a "\n" 
}
' temp1.txt > temp.txt
cp temp.txt temp2.txt
rm temp.txt
####################################################################################################
# function name: calculate #
############################
# calculations for interarrival packet time and dropped packtes
awk '
BEGIN {
	FS=" "
	cont=1
}
{
# calculating for initial conditions
if (cont==1) { 
	t_initial=$1
	t_before=$1
	time=0
	bw=0
	dropped=0
	output_rate=0
}
# calculating for the rest
if (cont>1) {
	time=$1-t_before # interarrival packet time (microseconds)
	dropped=$3-before_position-1 # dropped packets
}
# printed in order: packet number, serial number, packet size, interarrival packet time (microseconds), normalized capture time (microseconds) 
printf cont "\t" $3 "\t" $2+26+20+8 "\t" time*1000000 "\t" ($1-t_initial)*1000000 "\t" dropped "\n"
t_before=$1
before_position=$3
cont++
}
' temp2.txt > temp3.txt
####################################################################################################
# function name: output_rate #
##############################
# calculating output rate
awk '
BEGIN {
	FS=" "
	before_serial=0
	time=0
	bytes=0
	go=0
}
{
if (go==0) {
	printf $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" 0 "\n"
	go++
}
if ($2==(before_serial+1)) {
	before_serial=$2
	time=time+$4
	bytes=bytes+$3
	printf $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" 0 "\n"
}
if ($2>before_serial+1) {
	rate=bytes*8/time
	printf $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" rate "\n"
	before_serial=$2
	time=$4
	bytes=$3
}
}
' temp3.txt > temp4.txt
####################################################################################################
# function name: tx_bw_ini #
############################
# firts step for calculating input rate
awk '
BEGIN {
	FS=" "
	go=0
	before_serial=0
}
# calculating transmission rate to be used for the first frame
{
# assigning before serial and time for all file
if ($2==(before_serial+1)) {
	before_serial=$2
	before_time=$5
}
# in case of packet loss 
if ($2>(before_serial+1)) {
	if (go==0) {
		initial_packet=$2
		initial_time=before_time		
	}
	if (go==1) {
		tx_rate=(($2-initial_packet)*$3*8)/($5-initial_time)
		printf tx_rate
	}
	before_serial=$2
	before_time=$5
	go++
}
}
' temp4.txt > temp5.txt
####################################################################################################
# function name: buffer_size #
##############################
# calculating input rate and buffer size
awk '
BEGIN {
	FS=" "
	go=0
	before_serial=0
}
# calculating transmission rate
{
if (go==0) {
	getline tx_rate < "temp5.txt"
	initial_packet=$2
	initial_time=$5
	go++
	printf $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" 0 "\t" 0 "\t" 0 "\n"
}
if ($2==(before_serial+1)) {
	before_serial=$2
	before_time=$5
	printf $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" 0 "\t" 0 "\t" 0 "\n"
}
if ($2>(before_serial+1)) {
	if (go==1) {
		buffer_max=((($5-initial_time))/((1/(tx_rate-$7))+(1/$7)))/($3*8)
		buffer_min=buffer_max-((($6*$3*8/tx_rate)*$7)/($3*8))		
		printf $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" tx_rate "\t" buffer_max "\t" buffer_min "\n"
	}
	if (go>1) {
		tx_rate=(($2-initial_packet)*$3*8)/($5-initial_time)
		buffer_min=buffer_max-((($5-initial_time))/((1/(tx_rate-$7))+(1/$7)))/($3*8)
		printf $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" tx_rate "\t" buffer_max "\t" buffer_min "\n"
	}
	initial_packet=$2
	initial_time=before_time
	before_serial=$2
	go++
}
}
' temp4.txt > temp6.txt
####################################################################################################
# function name: order #
########################
# ordering data
awk '
BEGIN {
	FS=" "
}
{
if ($9==0) {
	column1=$1
	column2=$2
	column3=$3
	column4=$4
	column5=$5
	column6=$6
	column7=$7
	column8=$8
	column10=$10
	printf $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" 0 "\n"
}
if ($9!=0) {
	printf column1 "\t" column2 "\t" column3 "\t" column4 "\t" column5 "\t" column6 "\t" column7 "\t" column8 "\t" $9 "\n" 
	printf $1 "\t" $2 "\t" $3 "\t" $4 "\t" $5 "\t" $6 "\t" $7 "\t" $8 "\t" $10 "\n"
}
}
' temp6.txt > $3.txt
####################################################################################################
# converting to csv format
awk '{printf $1 "," $2 "," $3 "," $4 "," $5 "," $6 "," $7 "," $8 "," $9 "\n"}' $3.txt > $3.csv
####################################################################################################
# function name: graphic #
##########################
# printing file to graphic buffer size
awk '
# printing file to graphic buffer size
BEGIN {
	printf 0 "," 0 "\n"

}
{
if ($9!=0) {
	printf $2 "," $9 "\n"
}
}
' $3.txt > graphic_$3.csv
