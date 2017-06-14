#!/bin/bash

if [[ $# -ne 3 ]] ; then 
  echo "Incorrect Number of Paramaters Specified"
  echo "Usage: <original bvecs> <rotated bvecs> <Path to mats>"
  echo ""
  echo "<Path to mats>		ABSOLUTE path to directory with motion correction matrices"
  echo "			Warning: there must be only ecc-correction derived matrices"
  echo "			in the <Path to mats>"
  echo ""
  exit 1;
fi
  
  #echo $1 $2 $3
  
if [ -e $2 ] ; then
	rm $2
fi

newXs="";
newYs="";
newZs=""


BVECS=$1;
Xs=$(cat $BVECS | head -1 | tail -1)
Ys=$(cat $BVECS | head -2 | tail -1)
Zs=$(cat $BVECS | head -3 | tail -1)

MATs=$(ls ${3}*.mat);

VOLUMES=$(cat $BVECS | head -1 | tail -1 | wc -w)

#echo $VOLUMES
#echo $MATs

if [ $VOLUMES != $(echo ${MATs} | wc -w) ]
then
	echo "Number of *.mat files in $3 is not equal to number"
	echo "of gradients in $BVECS!"
	exit 1
fi

i=1
while [ $i -le $VOLUMES ] ; do
	MAT=$(echo ${MATs} | cut -d " " -f ${i});

	output=$(avscale --allparams ${MAT} | head -2 | tail -1)
	m11=$(echo $output | cut -d " " -f 1)
	m12=$(echo $output | cut -d " " -f 2)
	m13=$(echo $output | cut -d " " -f 3)

	output=$(avscale --allparams ${MAT} | head -3 | tail -1)
	m21=$(echo $output | cut -d " " -f 1)
	m22=$(echo $output | cut -d " " -f 2)
	m23=$(echo $output | cut -d " " -f 3)

	output=$(avscale --allparams ${MAT} | head -4 | tail -1)
	m31=$(echo $output | cut -d " " -f 1)
	m32=$(echo $output | cut -d " " -f 2)
	m33=$(echo $output | cut -d " " -f 3)

	X=$(echo $Xs | cut -d " " -f "$i")
	Y=$(echo $Ys | cut -d " " -f "$i")
	Z=$(echo $Zs | cut -d " " -f "$i")

	X=`printf "%1.7g" $X`
	Y=`printf "%1.7g" $Y`
	Z=`printf "%1.7g" $Z`

	rX=`echo "$m11 * $X + $m12 * $Y + $m13 * $Z" | bc`
	rY=`echo "$m21 * $X + $m22 * $Y + $m23 * $Z" | bc`
	rZ=`echo "$m31 * $X + $m32 * $Y + $m33 * $Z" | bc`

	rX=`printf "%1.7g" $rX`
	rY=`printf "%1.7g" $rY`
	rZ=`printf "%1.7g" $rZ`


	rXs=${rXs}${rX}" ";
	rYs=${rYs}${rY}" ";
	rZs=${rZs}${rZ}" ";

	i=$(echo "$i + 1" | bc) ;
done

echo "$rXs" >> $2;
echo "$rYs" >> $2;
echo "$rZs" >> $2;
