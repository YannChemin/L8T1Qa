#!/bin/bash

if [ $# -lt 2 ]; then
  echo 1>&2 "$0: not enough arguments: number of threads & output directory"
  exit 2
elif [ $# -gt 2 ]; then
  echo 1>&2 "$0: too many arguments"
  exit 2
fi

# Recompile with latest changes
make clean
make

# Number of running threads
export OMP_NUM_THREADS=$1

#Basename of satellite imagery tile without Path and Row
productL8=LC08_L1TP_

#PWD program
PWD=$(pwd)

#RSDATA directory (sub) structure
DataRoot=$PWD/../RSDATA
root=$DataRoot/3_Products
in_l8=$DataRoot/2_PreProcessed/L8/
in_l8_qa=$DataRoot/2_PreProcessed/L8/
out_l8=$root/$2/

#Make output directory
mkdir -p $out_l8
rm $out_l8/*.tif -f

#Process by timestamp range
for (( doy = 2018000 ; doy <= 2019000 ; doy++ ))
do 	test0=$(find $in_l8 -type f | grep $productL8 | grep $doy | grep tar.gz | wc -l)
	if [ $test0 -eq 1 ] 
	then 
		# Uncompress tarball
		tar xvf $(find $in_l8 -type f | grep $productL8 | grep $doy | grep tar.gz) -C $in_l8 
		# Get input files count
		test1=$(find $in_l8 -type f | grep $productL8 | grep $doy | grep _B1.TIF | wc -l)
		test2=$(find $in_l8_qa -type f | grep $productL8 | grep $doy | grep _BQA.TIF | wc -l)
		# Get output file count
  		test3=$(find $out_l8 -type f | grep $out_l8$productL8\_$doy.tif | wc -l)
		#if output exists, do not overwrite (test3 -eq 0)
		if [ $test1 -eq 1 -a $test2 -eq 1 -a $test3 -eq 0 ]
  		then 
			# Get Band 1
			inB2=$(find $in_l8 -type f | grep $productL8 | grep $doy | grep _B1.TIF)
			# Get QA band
			inB3=$(find $in_l8 -type f | grep $productL8 | grep $doy | grep _BQA.TIF)
			# Set output name
			outL8=$out_l8$productL8\_$doy.tif
			# Process
			echo "$PWD/l8t1qa $inB2 $inB3 $outL8" 
			$PWD/l8t1qa $inB2 $inB3 $outL8 
			# Clean up
			rm -f $in_l8/*.TIF
			rm -f $in_l8/*.txt
			# Tarball the output file & clean up
			cd $out_l8
			echo "cd $out_l8"
			for file in *.tif
			do	tar -cvzf $(echo $file| sed 's/.tif//').tar.gz $file $(echo $file | sed 's/.tif/.IMD/') -C $out_l8
				rm -f $file
				rm -f $(echo $file | sed 's/.tif/.IMD/')
			done
			# Return to program dir
			cd $PWD
		fi 
	fi
done
