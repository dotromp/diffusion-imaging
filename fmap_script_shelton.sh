#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Use fieldmap to correct EPI distorted DTI data
# see also http://mri-xs.mri.psychiatry.wisc.edu/groups/kalinlab/wiki/47228/EPI_Distortion_Correction.html

if [ $# -lt 4 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo This corrects EPI distorted DTI data.
echo Usage:
echo sh fmap_script.sh {raw_data_dir} {process_dir} {pepolar} {subjects}
echo eg:
echo fmap_script.sh /study/mri/raw-data /study/scratch/MRI 0 001 002
echo 
echo pepolar = 0 or 1 flip phase encoding direction, 0 is used for squished, 1 is used for stretched raw DWI
echo
echo Script used: http://mri-xs.mri.psychiatry.wisc.edu/groups/kalinlab/wiki/47228/EPI_Distortion_Correction.html
echo

else

echo "Input directory "$1
raw=$1
echo "Output directory "$2
PROCESS=$2
mkdir -p -v ${PROCESS}/CORRECTED
pepolar=$3

shift 3
subject=$*

cd ${PROCESS}/EDDY

if [ $pepolar == 0 ]
then
echo ~~~FMAP Correct for 0 pepolar~~~
for i in ${subject};
do
subj=`echo $i | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`
#gunzip ${PROCESS}/EDDY/${subj}*eddy.nii.gz

for j in `ls ${subj}*eddy.nii`;
do
prefix=`echo $j | awk 'BEGIN{FS=".nii"}{print $1}'`;
scan=`echo $j | awk 'BEGIN{FS="_"}{print $2}' | awk 'BEGIN{FS="_"}{print $1}' | cut -c2- | sed -e 's:^0*::'`;
num=$(( $scan + 1 ))
fmap=`ls ${PROCESS}/FMAP/${subj}_*_fmap.nii`;

echo Prefix is: $prefix; 
echo Fieldmap is: $fmap;

fieldmap_correction --beautify --pepolar $fmap 0.800 ${PROCESS}/CORRECTED/ $j;
done
done

else
echo ~~~FMAP Correct for 1 pepolar~~~
for i in ${subject};
do
subj=`echo $i | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`

for j in `ls ${subj}*eddy.nii`;
do
prefix=`echo $j | awk 'BEGIN{FS=".nii"}{print $1}'`;
scan=`echo $j | awk 'BEGIN{FS="_"}{print $2}' | awk 'BEGIN{FS="_"}{print $1}' | cut -c2- | sed -e 's:^0*::'`;
num=$(( $scan + 1 ))
fmap=`ls ${PROCESS}/FMAP/${subj}_*_fmap.nii`;

echo Prefix is: $prefix; 
echo Fieldmap is: $fmap;

fieldmap_correction --beautify $fmap 0.800 ${PROCESS}/CORRECTED/ $j;
done
done
fi

fi

