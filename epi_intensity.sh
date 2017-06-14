#!/bin/bash
# Do Tromp 2013
# dtromp@wisc.edu
# Calculate epi intensity


if [ $# -lt 2 ]
then
echo
echo ERROR, not enough input variables
echo
echo Calculate epi intensity
echo Usage:
echo sh epi_intensity.sh {process_dir} {subjs_separate_by_space}
echo eg:
echo epi_intensity.sh /Volumes/Vol5/processed_DTI/OFFem BG13.577/
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

echo ~~~Calculate intensity~~~;
intensity_dti=${PROCESS}/INFO/${subj}_intensity_dti.txt
intensity_rsfmri=${PROCESS}/INFO/${subj}_intensity_rsfmri.txt
rm -f $intensity_dti
rm -f $intensity_rsfmri

for i in `ls ${PROCESS}/rs-fMRI/${subj}_*_epi.nii*`
do
prefix=`echo $i | awk 'BEGIN{FS=".nii"}{print $1}'`;

#echo 3dTstat -cvarinv -prefix ${prefix}_TSNR.file ${i}'[3-$]' >> ${PROCESS}/INFO/${subj}_process_info.txt;
#3dTstat -cvarinv -prefix ${prefix}_TSNR.file ${i}'[3-$]' >> ${PROCESS}/INFO/${subj}_process_info.txt;

#echo convert_file ${prefix}_TSNR.file+orig ${prefix}_intensity nii >> ${PROCESS}/INFO/${subj}_process_info.txt;
#convert_file ${prefix}_TSNR.file+orig ${prefix}_intensity nii >> ${PROCESS}/INFO/${subj}_process_info.txt;
#rm -f ${prefix}_TSNR.file*

#fslmaths ${prefix}_intensity -thrp 60 ${prefix}_intensity_thrp60
#mean=`fslstats ${i} -r`
vol=`fslstats ${i} -r|awk 'BEGIN{FS=" "}{print $2}'`

echo ${i}, ${vol} >> ${intensity_rsfmri};
echo ${i}, ${vol};
#rm -f ${prefix}_intensity_thrp60.nii.gz
done

for i in `ls ${PROCESS}/DTI_RAW/${subj}_*_dti.nii*`
do
prefix=`echo $i | awk 'BEGIN{FS=".nii"}{print $1}'`;

#echo 3dTstat -cvarinv -prefix ${prefix}_TSNR.file ${i}'[1-6]' >> ${PROCESS}/INFO/${subj}_process_info.txt;
#3dTstat -cvarinv -prefix ${prefix}_TSNR.file ${i}'[1-6]' >> ${PROCESS}/INFO/${subj}_process_info.txt;

#echo convert_file ${prefix}_TSNR.file+orig ${prefix}_intensity nii >> ${PROCESS}/INFO/${subj}_process_info.txt;
#convert_file ${prefix}_TSNR.file+orig ${prefix}_intensity nii >> ${PROCESS}/INFO/${subj}_process_info.txt;
#rm -f ${prefix}_TSNR.file*

#fslmaths ${prefix}_intensity -thrp 60 ${prefix}_intensity_thrp60
#mean=`fslstats ${prefix}_intensity_thrp60.nii.gz -M`
vol=`fslstats ${i} -r|awk 'BEGIN{FS=" "}{print $2}'`

echo ${i}, ${vol} >> ${intensity_dti};
echo ${i}, ${vol};
#rm -f ${prefix}_intensity_thrp60.nii.gz
done
#mkdir -p -v ${PROCESS}/DTI_RAW/SNR
#mkdir -p -v ${PROCESS}/rs-fMRI/SNR
#mv ${PROCESS}/DTI_RAW/${subj}*_intensity.nii ${PROCESS}/DTI_RAW/SNR/
#mv ${PROCESS}/rs-fMRI/${subj}*_intensity.nii ${PROCESS}/rs-fMRI/SNR/
done
fi
