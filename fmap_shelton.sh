#!/bin/bash
# Do Tromp 2013
# Make fieldmap

if [ $# -lt 4 ]
then
echo
echo ERROR, not enough input variables
echo
echo Make fieldmap for fieldmap correction.
echo Usage:
echo sh fmap.sh {raw_input_dir} {fmap_dir} {process_dir} {mask_or_not} {subjs_separate_by_space}
echo eg:
echo
echo fmap.sh /study/mri/raw-data example /study5/aa-scratch/MRI mask 002 003 004 
echo
echo pr-existing_mask = mask or nomask, if pre-existing mask is available location in output_dir/MASK or not, respectively
echo
echo Script used: http://brainimaging.waisman.wisc.edu/~jjo/fieldmap_correction/make_fmap.html

else

raw=$1
echo "Input directory "$raw
raw_fmap=$2
PROCESS=$3
mkdir -p -v ${PROCESS}/FMAP
echo "Process directory: "$PROCESS
mask=$4

shift 4
subject=$*

for i in ${subject};
do

echo ~~~Subject in process: ${i}~~~
cd $raw
subj=$i
prefix=`echo ${raw_fmap} | awk 'BEGIN{FS="/"}{print $3}'| awk 'BEGIN{FS="_"}{print $1}'`;

echo make_fmap $raw/${raw_fmap} ${PROCESS}/FMAP/${subj}_${prefix}_fmap -m ${PROCESS}/MASK/${subj}*_mask.nii.gz;
make_fmap $raw/${raw_fmap} ${PROCESS}/FMAP/${subj}_${prefix}_fmap -m ${PROCESS}/MASK/${subj}*_mask.nii.gz;

cd $raw
done
fi
