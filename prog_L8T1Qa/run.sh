#!/bin/bash

productL8=L8_

DataRoot=~/RSDATA/
root=$DataRoot/3_Products/
in_l8=$DataRoot/2_PreProcessed/L8/Hco/
in_l8_qa=$DataRoot/2_PreProcessed/L8/Hco/
out_l8=$root/L8T1Qa/

mkdir $out_l8
rm $out_l8/*.tif -f


for (( doy = 2010000 ; doy <= 2011000 ; doy++ ))
 do test1=$(find $in_l8 -type f | grep $productL8$doy | wc -l)
  test2=$(find $in_l8_qa -type f | grep $productL8$doy | wc -l)
  test3=$(find $out_l8 -type f | grep $out_l8$productL8$doy\_L8.tif | wc -l)
  if [ $test1 -eq 1 -a $test2 -eq 1 -a $test3 -eq 0 ]
  then inB2=$in_lai$productLAI$doy\_L8.tif 
   inB3=$in_lai_qa$productLAI$doy\_L8_QA.tif 
   outLAI=$out_lai$productLAI$doy\_L8.tif 
   echo "./l8T1Qa $inB2 $inB3 $outL8" 
  ./l8T1Qa $inB2 $inB3 $outL8 
  fi 
done
