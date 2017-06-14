#!/bin/bash
# Do Tromp 2013
# Convert T1 mask to fmap magnitude mask

if [ $# -lt 2 ]
then
echo
echo "ERROR, not enough input variables"
echo
echo "This script converts manual drawn T1 masks to fmap magnitude mask"
echo "Usage:"
echo "make_mask.sh {process_dir} {subj}"
echo "eg:"
echo "make_mask.sh /study/process 001/etcetc"
echo
echo "Before you run this script first run dti_2dfast.sh and get text file with 2dfast names"
echo 

else
    PROCESS=$1

    #one=$2
    #echo
    #echo "T1 image is: "$one;
    #mask=$3
    #echo "Mask image is: "$mask;
    shift 1
    subject=$*

    for i in $subject;
    do
	one=`echo $i | awk 'BEGIN{FS=","}{print $4}'`;
	t1_mask=`echo $i | awk 'BEGIN{FS=","}{print $3}'`;
	dti=`echo $i | awk 'BEGIN{FS=","}{print $1}'`;
	subj=`echo $dti | awk 'BEGIN{FS="/"}{print $1}'`;
	echo "T1 image is: "$one;
	echo "Mask image is: "$t1_mask;
	#subj=$i
	#echo ~~~Prefix is ${subj}~~~;
	#echo fslmaths ${one} -add 0 ${PROCESS}/T1/${subj}_T1High;
	#fslmaths ${one} -add 0 ${PROCESS}/T1/${subj}_T1High;

	#t1=T1High
	#subj=`echo $i | awk 'BEGIN{FS="MOM2/"}{print $2}'| awk 'BEGIN{FS="."}{print $1}'`
	#scan=`echo $i | awk 'BEGIN{FS="/proc"}{print $1}'| awk 'BEGIN{FS="."}{print $2}'`
	echo fslmaths ${t1_mask} -add 0 ${PROCESS}/T1/${subj}_T1High_M;
	fslmaths ${t1_mask} -add 0 ${PROCESS}/T1/${subj}_T1High_M;

	echo fslmaths "${one}" -add 0 ${PROCESS}/T1/${subj}_T1High;
	fslmaths "${one}" -add 0 ${PROCESS}/T1/${subj}_T1High;
    done

fi
