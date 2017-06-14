#!/bin/bash
# Do Tromp 2013
# dtromp@wisc.edu
# Calculate epi SNR


if [ $# -lt 2 ]
then
echo
echo ERROR, not enough input variables
echo
echo Calculate epi SNR
echo Usage:
echo sh epi_snr.sh {process_dir} {subjs_separate_by_space}
echo eg:
echo epi_snr.sh /Volumes/Vol5/processed_DTI/OFFem BG13.577/
echo
echo Run this code after running convert_script_all.sh
echo

else
PROCESS=$1
echo "Output directory "$PROCESS
shift 1
subject=$*

for i in $subject;
do
echo ~~~Subject in process: ${i}~~~
echo
subj=`echo $i | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`
echo ~~~Prefix is ${subj}~~~
echo

echo ~~~Calculate SNR~~~;
snr_dti=${PROCESS}/INFO/${subj}_snr_dti.txt
snr_rsfmri=${PROCESS}/INFO/${subj}_snr_rsfmri.txt
rm -f $snr_dti
rm -f $snr_rsfmri

for i in `ls ${PROCESS}/rs-fMRI/${subj}_*_epi.nii*`
do
prefix=`echo $i | awk 'BEGIN{FS=".nii"}{print $1}'`;

echo 3dTstat -cvarinv -prefix ${prefix}_TSNR.file ${i}'[3-$]' >> ${PROCESS}/INFO/${subj}_process_info.txt;
3dTstat -cvarinv -prefix ${prefix}_TSNR.file ${i}'[3-$]' >> ${PROCESS}/INFO/${subj}_process_info.txt;

echo convert_file ${prefix}_TSNR.file+orig ${prefix}_snr nii >> ${PROCESS}/INFO/${subj}_process_info.txt;
convert_file ${prefix}_TSNR.file+orig ${prefix}_snr nii >> ${PROCESS}/INFO/${subj}_process_info.txt;
rm -f ${prefix}_TSNR.file*

fslmaths ${prefix}_snr -thrp 60 ${prefix}_snr_thrp60
mean=`fslstats ${prefix}_snr_thrp60.nii.gz -M`
vol=`fslstats ${prefix}_snr_thrp60.nii.gz -V|awk 'BEGIN{FS=" "}{print $1}'`

echo ${i}, ${mean}, ${vol} >> ${snr_rsfmri};
echo ${i}, ${mean}, ${vol};
rm -f ${prefix}_snr_thrp60.nii.gz
done

for i in `ls ${PROCESS}/DTI_RAW/${subj}_*_dti.nii*`
do
prefix=`echo $i | awk 'BEGIN{FS=".nii"}{print $1}'`;

echo 3dTstat -cvarinv -prefix ${prefix}_TSNR.file ${i}'[1-6]' >> ${PROCESS}/INFO/${subj}_process_info.txt;
3dTstat -cvarinv -prefix ${prefix}_TSNR.file ${i}'[1-6]' >> ${PROCESS}/INFO/${subj}_process_info.txt;

echo convert_file ${prefix}_TSNR.file+orig ${prefix}_snr nii >> ${PROCESS}/INFO/${subj}_process_info.txt;
convert_file ${prefix}_TSNR.file+orig ${prefix}_snr nii >> ${PROCESS}/INFO/${subj}_process_info.txt;
rm -f ${prefix}_TSNR.file*

fslmaths ${prefix}_snr -thrp 60 ${prefix}_snr_thrp60
mean=`fslstats ${prefix}_snr_thrp60.nii.gz -M`
vol=`fslstats ${prefix}_snr_thrp60.nii.gz -V|awk 'BEGIN{FS=" "}{print $1}'`

echo ${i}, ${mean}, ${vol} >> ${snr_dti};
echo ${i}, ${mean}, ${vol};
rm -f ${prefix}_snr_thrp60.nii.gz
done
mkdir -p -v ${PROCESS}/DTI_RAW/SNR
mkdir -p -v ${PROCESS}/rs-fMRI/SNR
mv ${PROCESS}/DTI_RAW/${subj}*_snr.nii ${PROCESS}/DTI_RAW/SNR/
mv ${PROCESS}/rs-fMRI/${subj}*_snr.nii ${PROCESS}/rs-fMRI/SNR/
done
fi
