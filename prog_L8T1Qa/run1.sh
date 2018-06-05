#!/bin/bash

#INPUT L8 DIR
in_l8=~/RSDATA/IN_L8/IN_L8_Ya

#Make output directory
out_l8=~/RSDATA/OUT_L8_Ya
mkdir -p $out_l8
rm $out_l8/*.tif -f

# Recompile with latest changes
make clean &>/dev/null
make &>/dev/null

#pwd of program
prog=~/dev/L8T1Qa/trunk/prog_L8T1Qa/

#CD to input dir
cd $in_l8

# Set input names
inB4=$(ls *band4.tif)
inB5=$(ls *band5.tif)
inB6=$(ls *band6.tif)
inBQ=$(ls *pixel_qa.tif)

# Set output names
outL8VI=$out_l8/$(echo $inB4 | sed 's/band4.tif//')\_NDVI.tif
outL8WI=$out_l8/$(echo $inB4 | sed 's/band4.tif//')\_NDWI.tif
	
# Set temp names
tmpL8VI=$out_l8/temp_$(echo $inB4 | sed 's/band4.tif//')\_NDVI.tif
tmpL8WI=$out_l8/temp_$(echo $inB4 | sed 's/band4.tif//')\_NDWI.tif
	
# Process
#echo "$prog/l8t1qa $inB4 $inB5 $inB6 $inBQ $tmpL8VI $tmpL8WI" 
$prog/l8t1qa $inB4 $inB5 $inB6 $inBQ $tmpL8VI $tmpL8WI
#echo "python ./run.py $inB4 $inB5 $inB6 $inBQ $tmpL8VI $tmpL8WI" 
#python ./run.py $inB4 $inB5 $inB6 $inBQ $tmpL8VI $tmpL8WI 

# Go to output Dir
cd $out_l8
#echo "cd $out_l8"

# Convert tmp to EPSG:4326
gdalwarp -q -multi -t_srs "EPSG:4326" $tmpL8VI $outL8VI
gdalwarp -q -multi -t_srs "EPSG:4326" $tmpL8WI $outL8WI

rm -f temp*
