#!/bin/bash
# Do Tromp 2012
# Convert DTI, FMAP, T1, T2 from DICOM to NIfTI for multiple subjects

if [ $# -lt 3 ]
then
echo
echo ERROR, not enough input variables
echo
echo Convert DTI, FMAP, T1, T2 from DICOM to NIfTI for multiple subjects
echo Usage:
echo sh convert_script.sh {raw_input_dir} {nifti_output_dir} {subjs_separate_by_space}
echo eg:

echo convert_script.sh /study/mri/raw-data /study5/aa-scratch/MRI 002 003 004 
echo "The command does not deal well with wild cards yet" 
echo
else
echo Convert File

f=3 # Used as argument index
while [ $f -le $# ]; do
subject=${!f}
echo "Subject in process: "$subject
echo "Input directory "$1
raw=$1
echo "Output directory "$2
PROCESS=$2
cd ${raw}

for i in ${subject};
do
cd ${raw}/${i}/dicoms/;
mkdir -p -v ${PROCESS}/DTI_RAW
mkdir -p -v ${PROCESS}/T1
mkdir -p -v ${PROCESS}/T2
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

echo CONVERT DTI SCANS
for j in `ls -d *_dti *_hydie`;
do
prefix=`echo $j | awk 'BEGIN{FS="/"}{print $1}'`;
subj=${subject}
echo Scan is ${j}
convert_file ${j} ${PROCESS}/DTI_RAW/${subj}_${prefix} nii;
done

echo CONVERT ANATOMICAL
for j in `ls -d *_bravo`;
do
prefix=`echo $j | awk 'BEGIN{FS="/"}{print $1}'`;
subj=${subject};
echo Scan is ${j}
convert_file ${j} ${PROCESS}/T1/${subj}_${prefix} nii;
done

echo CONVERT T2
for j in `ls -d *_cube`;
do
prefix=`echo $j | awk 'BEGIN{FS="/"}{print $1}'`;
subj=${subject};
echo Scan is ${j}
convert_file ${j} ${PROCESS}/T2/${subj}_${prefix} nii;
done

echo MAKE FMAP
for k in `ls -d *_2dfast`;
do
prefix=`echo $k | awk 'BEGIN{FS="/"}{print $1}'`;
subj=${subject}
echo Scan is ${prefix}
convert_file ${k} ${PROCESS}/2DFAST/${subj}_${prefix} nii;
make_fmap $k ${PROCESS}/FMAP/${subj}_FMAP;
done
cd ${raw}

f=$((f+1))
done
done

cd ${PROCESS}
echo "You are now in the output directory "
pwd
fi
