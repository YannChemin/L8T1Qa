#!/bin/bash

if [ $# -lt 1 ]; then
  echo 1>&2 "$0: not enough arguments, just give the output directory"
  exit 2
elif [ $# -gt 1 ]; then
  echo 1>&2 "$0: too many arguments"
  exit 2
fi

productL8=LC08_L1TP_142054_

DataRoot=~/RSDATA/
root=$DataRoot/3_Products/
in_l8=$DataRoot/2_PreProcessed/L8/
in_l8_qa=$DataRoot/2_PreProcessed/L8/
out_l8=$root/$1/

mkdir $out_l8
rm $out_l8/*.tif -f


for (( doy = 2018000 ; doy <= 2019000 ; doy++ ))
do test0=$(find $in_l8 -type f | grep $productL8$doy | wc -l)
	if [ $test0 -eq 1 ] 
	then 
		do 
			test1=$(find $in_l8 -type f | grep $productL8$doy | wc -l)
			test2=$(find $in_l8_qa -type f | grep $productL8$doy | wc -l)
  			test3=$(find $out_l8 -type f | grep $out_l8$productL8$doy\_L8.tif | wc -l)
  			if [ $test1 -eq 1 -a $test2 -eq 1 -a $test3 -eq 0 ]
  			then 
				inB2=$in_lai$productLAI$doy\_L8.tif 
				inB3=$in_lai_qa$productLAI$doy\_L8_QA.tif 
				outLAI=$out_lai$productLAI$doy\_L8.tif 
				echo "./l8T1Qa $inB2 $inB3 $outL8" 
				./l8T1Qa $inB2 $inB3 $outL8 
			fi 
		done
	fi

done
