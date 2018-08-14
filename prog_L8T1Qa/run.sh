#!/bin/bash

#if [ $# -lt 2 ]; then
#  echo 1>&2 "$0: not enough arguments: number of threads & output directory"
#  exit 2
#elif [ $# -gt 2 ]; then
#  echo 1>&2 "$0: too many arguments"
#  exit 2
#fi

# Recompile with latest changes
make clean
make

# Number of running threads
#export OMP_NUM_THREADS=$1
export OMP_NUM_THREADS=7

#Basename of satellite imagery tile without Path and Row
productL8=LC08_L1TP_

#PWD program
base=$(pwd)

#RSDATA directory (sub) structure
DataRoot=~/RSDATA/
in_l8=$DataRoot/2_PreProcessed/L8/WestBengal/
out_l8=/media/yann/4Tb/RSDATA/ETb/3_Products/L8/WestBengal/

#Make output directory
mkdir -p $out_l8
rm $out_l8/*.tif -f

cd $in_l8

#Process by tar.gz file
for file in LC08*gz
do
	# Uncompress tarball
	tar xvf $file -C $in_l8 
	pr=$(echo $file | sed 's/LC08\(......\)\(.*\)/\1/')_ 
	doy=$(echo $file | sed 's/LC08\(......\)\(........\)\(.*\)/\2/') 
	# Get Band 1-7
	inB1=$(find $in_l8 -type f | grep $productL8$pr$doy | grep _band1.tif)
	inB2=$(find $in_l8 -type f | grep $productL8$pr$doy | grep _band2.tif)
	inB3=$(find $in_l8 -type f | grep $productL8$pr$doy | grep _band3.tif)
	inB4=$(find $in_l8 -type f | grep $productL8$pr$doy | grep _band4.tif)
	inB5=$(find $in_l8 -type f | grep $productL8$pr$doy | grep _band5.tif)
	inB6=$(find $in_l8 -type f | grep $productL8$pr$doy | grep _band6.tif)
	inB7=$(find $in_l8 -type f | grep $productL8$pr$doy | grep _band7.tif)
	# Get QA band
	inQA=$(find $in_l8 -type f | grep $productL8$pr$doy | grep _pixel_qa.tif)
	# Set output name
	VI=$out_l8$productL8$pr$doy\_NDVI.tif
	WI=$out_l8$productL8$pr$doy\_NDWI.tif
	LSWI=$out_l8$productL8$pr$doy\_LSWI.tif
	NBR2=$out_l8$productL8$pr$doy\_NBR2.tif
	# Set Band 1-7
	B1=$out_l8$productL8$pr$doy\_band1.tif
	B2=$out_l8$productL8$pr$doy\_band2.tif
	B3=$out_l8$productL8$pr$doy\_band3.tif
	B4=$out_l8$productL8$pr$doy\_band4.tif
	B5=$out_l8$productL8$pr$doy\_band5.tif
	B6=$out_l8$productL8$pr$doy\_band6.tif
	B7=$out_l8$productL8$pr$doy\_band7.tif
	# Process
	#echo "$PWD/l8t1qa $inB1 $inB2 $inB3 $inB4 $inB5 $inB6 $inB7 $inQA $VI $WI $LSWI $NBR2 $B1 $B2 $B3 $B4 $B5 $B6 $B7" 
	#time $PWD/l8t1qa $inB1 $inB2 $inB3 $inB4 $inB5 $inB6 $inB7 $inQA $VI $WI $LSWI $NBR2 $B1 $B2 $B3 $B4 $B5 $B6 $B7
	echo "$PWD/l8t1qa $inB1 $inB2 $inB3 $inB4 $inB5 $inB6 $inB7 $inQA $VI $WI $LSWI $NBR2 $B1 $B2 $B3 $B4 $B5 $B6 $B7" 
	$base/l8t1qa $inB1 $inB2 $inB3 $inB4 $inB5 $inB6 $inB7 $inQA $VI $WI $LSWI $NBR2 $B1 $B2 $B3 $B4 $B5 $B6 $B7 
	# Clean up
	rm -f $in_l8/*.tif
	rm -f $in_l8/*.txt
	rm -f $in_l8/*.xml
done
