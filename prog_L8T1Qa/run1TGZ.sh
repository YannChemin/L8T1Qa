#!/bin/bash

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
out_l8=~/RSDATA/OUT_L8
mkdir-p $out_l8
rm $out_l8/*.tif -f

# Recompile with latest changes
make clean
make

#PWD program
PWD=$(pwd)

#CD to input dir
cd $in_l8

# Uncompress tarball
tar -I pigz -xvf $1 -C $(echo $1 | sed 's/.tar.gz//')

# Go to untarballed dir
cd ~/RSDATA/IN_L8/$(echo $1 | sed 's/.tar.gz//')

# Set input names
inB4=$(ls *band4.tif)
inB5=$(ls *band5.tif)
inB6=$(ls *band6.tif)
inBQ=$(ls *pixel_qa.tif)

# Set output names
outL8VI=$out_l8$(echo $1 | sed 's/.tar.gz//')\_NDVI.tif
outL8WI=$out_l8$(echo $1 | sed 's/.tar.gz//')\_NDWI.tif
	
# Process
echo "$PWD/l8t1qa $inB4 $inB5 $inB6 $inBQ $outL8VI $outL8WI" 
$PWD/l8t1qa $inB4 $inB5 $inB6 $inBQ $outL8VI $outL8WI
#echo "python ./run.py $inB4 $inB5 $inB6 $inBQ $outL8VI $outL8WI" 
#python ./run.py $inB4 $inB5 $inB6 $inBQ $outL8VI $outL8WI 

# Clean up
cd $in_l8
rm -Rf $in_l8/$(echo $1 | sed 's/.tar.gz//')

# Tarball the output file & clean up
cd $out_l8
echo "cd $out_l8"
for file in *.tif
do	
	tar -I pigz -cvzf $(echo $file| sed 's/.tif//').tar.gz $file $(echo $file | sed 's/.tif/.IMD/') -C $out_l8
	rm -f $file
	rm -f $(echo $file | sed 's/.tif/.IMD/')
done
