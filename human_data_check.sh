#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Convert and QC new subjects

if [ $# -lt 2 ]
then
echo
echo ERROR, not enough input variables
echo
echo Convert and QC new subjects
echo Usage:
echo sh human_data_check.sh {study_name} {subjs_separate_by_space}
echo eg:
echo sh human_data_check.sh RISK BG13.577 BG08.604
echo
echo Code assumes that raw data is located here:
echo /Volumes/Studies/kalin
echo and processing directory is here:
echo /Volumes/Vol5/processed_DTI
echo


else
study=$1
echo
echo "Study is: "$study
raw=/Volumes/Studies/kalin/${study}
echo "Input directory: "$raw
PROCESS=/Volumes/Vol5/processed_DTI/${study}
echo "Output directory: "$PROCESS
shift 1
subject=$*
echo "Subjects to run: "$subject
echo

#process_txt=${PROCESS}/INFO/${subj}_process_info.txt
#rm -f $process_txt

for i in $subject;
do
echo ~~~Subject in progress: ${i}~~~
echo
subj=`echo $i | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`
echo ~~~Prefix is ${subj}~~~

mkdir -p -v ${PROCESS}/INFO
echo >> ${PROCESS}/INFO/${subj}_process_info.txt;
echo ~~~~~~~~~~~~ >> ${PROCESS}/INFO/${subj}_process_info.txt;
echo ~~~`date`~~~ >> ${PROCESS}/INFO/${subj}_process_info.txt;
echo ~~~~~~~~~~~~ >> ${PROCESS}/INFO/${subj}_process_info.txt;
echo >> ${PROCESS}/INFO/${subj}_process_info.txt;

echo ~~~Convert File~~~;
#echo sh $my_script/convert_script_all.sh $raw $PROCESS $i
sh $my_script/convert_script_all.sh $raw $PROCESS $i &>> ${PROCESS}/INFO/${subj}_process_info.txt;

echo ~~~File Info~~~;
#echo sh $my_script/file_info.sh $PROCESS $i;
sh $my_script/file_info.sh $PROCESS $i &>> ${PROCESS}/INFO/${subj}_process_info.txt;

echo ~~~Calculate SNR~~~;
#echo sh $my_script/epi_snr.sh $PROCESS $i;
sh $my_script/epi_snr.sh $PROCESS $i &>> ${PROCESS}/INFO/${subj}_process_info.txt;

echo ~~~Calculate Max~~~;
#echo sh $my_script/epi_intensity.sh $PROCESS $i &>> ${PROCESS}/INFO/${subj}_process_info.txt;
sh $my_script/epi_intensity.sh $PROCESS $i &>> ${PROCESS}/INFO/${subj}_process_info.txt;

echo ~~~Output Values:;
for scan in dti rsfmri
do
echo Image info:
cat ${PROCESS}/INFO/${subj}_info_${scan}.txt;
echo SNR info:
cat ${PROCESS}/INFO/${subj}_snr_${scan}.txt;
echo Max info:
cat ${PROCESS}/INFO/${subj}_intensity_${scan}.txt;

echo
day=`date | awk 'BEGIN{FS=" "}{print $2 $3}'`
cat ${PROCESS}/INFO/${subj}_snr_${scan}.txt >>  ${PROCESS}/INFO/group_snr_${scan}_${day}.txt;
cat ${PROCESS}/INFO/${subj}_info_${scan}.txt >>  ${PROCESS}/INFO/group_info_${scan}_${day}.txt;
cat ${PROCESS}/INFO/${subj}_intensity_${scan}.txt >> ${PROCESS}/INFO/group_intensity_${scan}_${day}.txt;
cat ${PROCESS}/INFO/group_snr_${scan}_*.txt > ${PROCESS}/group_snr_${scan}.txt
cat ${PROCESS}/INFO/group_info_${scan}_*.txt > ${PROCESS}/group_info_${scan}.txt
cat ${PROCESS}/INFO/group_intensity_${scan}_*.txt > ${PROCESS}/group_intensity_${scan}.txt
done
echo ~~~Finished subject ${subj}~~~

done
fi

