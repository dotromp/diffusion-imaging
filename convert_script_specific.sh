#!/bin/bash
# Do Tromp 2013
# Convert files from specific dir 

if [ $# -lt 3 ]
then
echo
echo ERROR, not enough input variables
echo
echo Convert files form specific dir
echo Usage:
echo sh convert_script_specific.sh {raw_input_dir} {process_dir} {subjs_raw_file_loc_separate_by_space}
echo eg:
echo
echo convert_script_specific.sh /study/mri/raw-data /study5/aa-scratch/MRI 065/anatomicals/S5_EPI2 
echo

else

raw=$1
echo "Input directory "$raw
PROCESS=$2
echo "Output directory "$PROCESS

shift 2
subject=$*
cd ${raw}

echo ~~~Convert File~~~;
for i in ${subject};
do

dti=`echo $subject | awk 'BEGIN{FS=","}{print $1}'`;
fmap=`echo $subject | awk 'BEGIN{FS=","}{print $2}'`;

cd ${raw}/;
mkdir -p -v ${PROCESS}/DTI_RAW
mkdir -p -v ${PROCESS}/T1
mkdir -p -v ${PROCESS}/2DFAST
mkdir -p -v ${PROCESS}/MASK
mkdir -p -v ${PROCESS}/FMAP
mkdir -p -v ${PROCESS}/EDDY
mkdir -p -v ${PROCESS}/CORRECTED
mkdir -p -v ${PROCESS}/SCHEME
mkdir -p -v ${PROCESS}/CAMINO
mkdir -p -v ${PROCESS}/SNR
mkdir -p -v ${PROCESS}/TENSOR
mkdir -p -v ${PROCESS}/TEMPLATE
mkdir -p -v ${PROCESS}/SCALARS
mkdir -p -v ${PROCESS}/TRACKVIS
mkdir -p -v ${PROCESS}/INFO

echo CONVERT SCANS
subj=`echo $dti | awk 'BEGIN{FS="/"}{print $1}'`;
subj2=`echo $fmap | awk 'BEGIN{FS="/"}{print $1}'`;
prefix=`echo $dti | awk 'BEGIN{FS="/"}{print $3}'`;
prefix2=`echo $fmap | awk 'BEGIN{FS="/"}{print $3}'`;
echo convert_file ${raw}/${dti} ${PROCESS}/DTI_RAW/${subj}_${prefix} nii;
convert_file ${raw}/${dti} ${PROCESS}/DTI_RAW/${subj}_${prefix} nii;
echo convert_file ${raw}/${fmap} ${PROCESS}/2DFAST/${subj2}_${prefix2} nii;
convert_file ${raw}/${fmap} ${PROCESS}/2DFAST/${subj2}_${prefix2} nii;
echo ${subj}_${prefix}.nii, ${subj2}_${prefix2}.nii >> ${PROCESS}/dti_2dfast.txt

done

#cd ${raw}

#done

#cd ${PROCESS}
#echo "You are now in the output directory "
#pwd
fi
