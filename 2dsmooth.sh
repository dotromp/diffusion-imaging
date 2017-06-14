#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# 2D Smoothing

if [ $# -lt 2 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo This will smooth the data in 2 dimensions.
echo Usage:
echo sh 2dsmooth.sh {process_dir} {subjects}
echo eg:
echo 2dsmooth.sh /study/scratch/MRI 001 002
echo 

else

echo "Process directory: "$1
PROCESS=$1

shift 1
subject=$*

echo ~~~2D SMOOTHING~~~
cd ${PROCESS}/CORRECTED

for j in ${subject};
do
subj=`echo $j | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`

for i in `ls ${subj}*_masked.nii*`;
do
prefix=`echo $i | awk 'BEGIN{FS=".nii"}{print $1}'`
smooth=`fslinfo ${i} |grep pixdim1|awk 'BEGIN{FS="dim1"}{print $2}'`
smooth=`echo $smooth |cut -c 1-3`
echo Prefix is: ${prefix};
echo Smoothing kernel is: ${smooth};
fslsplit $i ${prefix}_split -z;

for j in `ls ${prefix}_split????.nii.gz`;
do
pref=`echo $j | awk 'BEGIN{FS=".nii"}{print $1}'`;
echo ${pref};
fslmaths $j -s ${smooth} ${pref}_smooth;
done

fslmerge -z ${prefix}_smooth ${prefix}_split????_smooth.nii.gz;

rm -f ${prefix}_split????_smooth.nii.gz;
rm -f ${prefix}_split????.nii.gz;
done
done
fi
