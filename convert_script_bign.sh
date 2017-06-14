#!/bin/bash
# Do Tromp 2013
# Convert DTI, FMAP, T1 from DICOM to NIfTI for multiple subjects

if [ $# -lt 3 ]
then
echo
echo ERROR, not enough input variables
echo
echo Convert DTI, FMAP, T1 from DICOM to NIfTI for multiple subjects
echo Usage:
echo sh convert_script_bign.sh {raw_input_dir} {process_dir} {subjs_separate_by_space}
echo eg:
echo
echo convert_script_bign.sh /study/mri/raw-data /study5/aa-scratch/MRI 002 003 004 
echo Assumes file with locations of T1, Mask, DTI, 2dfast.

else

#raw=$1
#echo "Input directory "$raw
PROCESS=$2
#echo "Output directory "$PROCESS

shift 2
subject=$*

echo ~~~Convert File~~~;
for i in ${subject};
do
raw=`cat /Volumes/Vol5/processed_DTI/bigN/all_files.txt|grep ${i}|awk 'BEGIN{FS=" "}{print $2}'`
echo "Input directory "$raw
echo "Output directory "$PROCESS
dti=`cat /Volumes/Vol5/processed_DTI/bigN/all_files.txt|grep ${i}|awk 'BEGIN{FS=" "}{print $3}'`
echo "DTI directory "$raw/$dti
twodfast=`cat /Volumes/Vol5/processed_DTI/bigN/all_files.txt|grep ${i}|awk 'BEGIN{FS=" "}{print $4}'`
echo "2dfast directory "$raw/$twodfast
mask=`cat /Volumes/Vol5/processed_DTI/bigN/all_files.txt|grep ${i}|awk 'BEGIN{FS=" "}{print $5}'`
echo "Mask file "$mask
t1=`cat /Volumes/Vol5/processed_DTI/bigN/all_files.txt|grep ${i}|awk 'BEGIN{FS=" "}{print $6}'`
echo "T1 file "$t1
cd ${PROCESS};
echo "Current dir "$PROCESS
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

echo ~~~Subject in process: ${i}~~~
echo COPY T1 and MASK
echo fslmaths ${mask} -add 0 ${PROCESS}/T1/${i}_T1High_M;
fslmaths ${mask} -add 0 ${PROCESS}/T1/${i}_T1High_M;
echo fslmaths ${t1} -add 0 ${PROCESS}/T1/${i}_T1High;
fslmaths ${t1} -add 0 ${PROCESS}/T1/${i}_T1High;
echo Written: 
ls -lthr ${PROCESS}/T1/${i}*;

echo CONVERT DTI SCANS
echo Scan is ${dti}
echo convert_file ${raw}/${dti} ${PROCESS}/DTI_RAW/${i}_dti nii;
convert_file ${raw}/${dti} ${PROCESS}/DTI_RAW/${i}_dti nii;

echo CONVERT 2DFAST
echo Scan is ${twodfast}
echo convert_file ${raw}/${twodfast} ${PROCESS}/2DFAST/${i}_2dfast nii;
convert_file ${raw}/${twodfast} ${PROCESS}/2DFAST/${i}_2dfast nii;

done

cd ${PROCESS}
echo "You are now in the output directory "
pwd
fi
