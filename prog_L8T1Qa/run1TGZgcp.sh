#!/bin/bash

tgzF=$1

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: not enough arguments: TGZ input file"
  exit 2
elif [ $# -gt 1 ]; then
  echo 1>&2 "$0: too many arguments"
  exit 2
fi

#INPUT L8 DIR
in_l8=~/RSDATA/IN_L8/IN_L8_Ya

#Make output directory
out_l8=~/RSDATA/OUT_L8_Ya
mkdir -p $out_l8

# Recompile with latest changes
make clean &>/dev/null
make &>/dev/null


#pwd of program
prog=~/L8T1Qa/trunk/prog_L8T1Qa/

#CD to input dir
cd $in_l8

# Uncompress tarball
mkdir -p $in_l8/$(echo $1 | sed 's/.tar.gz//')
tar -I pigz -xvf $tgzF -C $in_l8/$(echo $1 | sed 's/.tar.gz//') &>/dev/null

# Go to untarballed dir
cd $in_l8/$(echo $tgzF | sed 's/.tar.gz//')

# Set input names
inB4=$(ls *band4.tif)
inB5=$(ls *band5.tif)
inB6=$(ls *band6.tif)
inBQ=$(ls *pixel_qa.tif)

# Set output names
outL8VI=$out_l8/$(echo $tgzF | sed 's/.tar.gz//')\_NDVI.tif
outL8WI=$out_l8/$(echo $tgzF | sed 's/.tar.gz//')\_NDWI.tif
	
# Set temp names
tmpL8VI=$out_l8/temp_$(echo $tgzF | sed 's/.tar.gz//')\_NDVI.tif
tmpL8WI=$out_l8/temp_$(echo $tgzF | sed 's/.tar.gz//')\_NDWI.tif
	
# Process
#echo "$prog/l8t1qa $inB4 $inB5 $inB6 $inBQ $tmpL8VI $tmpL8WI" 
$prog/l8t1qa $inB4 $inB5 $inB6 $inBQ $tmpL8VI $tmpL8WI
#echo "python ./run.py $inB4 $inB5 $inB6 $inBQ $tmpL8VI $tmpL8WI" 
#python ./run.py $inB4 $inB5 $inB6 $inBQ $tmpL8VI $tmpL8WI 

# Clean up
cd $in_l8
rm -Rf $in_l8/$(echo $tgzF | sed 's/.tar.gz//')

# Go to output Dir
cd $out_l8
#echo "cd $out_l8"

# Convert tmp to EPSG:4326
gdalwarp -q -multi -t_srs "EPSG:4326" $tmpL8VI $outL8VI
gdalwarp -q -multi -t_srs "EPSG:4326" $tmpL8WI $outL8WI

# Tarball the output file & clean up
tar -I pigz -cvf $(echo $outL8VI | sed 's/.tif//').tar.gz $outL8VI &>/dev/null
tar -I pigz -cvf $(echo $outL8WI | sed 's/.tif//').tar.gz $outL8WI &>/dev/null
rm -f $tmpL8VI &
rm -f $tmpL8WI &
rm -f $outL8VI &
rm -f $outL8WI &
rm -f *.IMD
