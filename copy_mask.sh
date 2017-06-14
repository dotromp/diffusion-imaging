#!/bin/bash
# Do Tromp 2013
# Convert T1 mask to fmap magnitude mask

if [ $# -lt 4 ]
then
echo
echo "ERROR, not enough input variables"
echo
echo "This script copies manual drawn T1 masks to fmap magnitude mask"
echo "Usage:"
echo "copy_mask.sh {process_dir} {inputpath_of_T1_files} {inputpath_of_T1_masks} {t1_prefix} {subj}"
echo "eg:"
echo "copy_mask.sh /study/process /Volumes/Shelton/*/processed/*T1High*.hdr /Volumes/Shelton/*/processed/*T1High*.hdr /study/etc/001_T1high 001/"
echo
#echo "Before you run this script first run dti_2dfast.sh and get text file with 2dfast names"
echo 

else
PROCESS=$1
one=$2
mask=$3
t1_prefix=$4

shift 4
subject=$*

for i in $subject;
do
echo ~~~Copy mask from manual masks~~~
echo fslmaths ${one} -add 0 ${t1_prefix};
fslmaths ${one} -add 0 ${t1_prefix};
echo fslmaths ${mask} -add 0 ${t1_prefix}_M;
fslmaths ${mask} -add 0 ${t1_prefix}_M;
echo Written: 
ls -ltrh ${t1_prefix}*;
done

fi
