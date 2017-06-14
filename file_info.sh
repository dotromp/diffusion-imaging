#!/bin/bash
# Do Tromp 2012
# Output scan info of a file

if [ $# -lt 2 ]
then
echo
echo "ERROR, not enough input variables"
echo
echo "This script outputs scan info of a file"
echo "Usage:"
echo "file_info.sh {process_dir} {subjs_separated_by_space}"
echo "eg:"
echo "file_info.sh /Volumes/Vol5/processed_DTI/OFFem BG13.577/"
echo

echo "The output text file is easily importable into Excel since it's a comma separated. In
Excel do: "
echo "Data; Text to Columns; Delimited; Comma; Finish"

echo
else
PROCESS=$1
cd $PROCESS
shift 1
subject=$*

for i in $subject;
do
echo ~~~Subject in process: ${i}~~~
echo
subj=`echo $i | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`
echo ~~~Prefix is ${subj}~~~
echo

echo ~~~File Info~~~
info_dti=${PROCESS}/INFO/${subj}_info_dti.txt
info_rsfmri=${PROCESS}/INFO/${subj}_info_rsfmri.txt
rm -f ${info_dti};
rm -f ${info_rsfmri};

for j in `ls ${PROCESS}/rs-fMRI/${subj}_*_epi.nii*`;
do
dim1=`fslinfo $j | grep dim1 | awk 'BEGIN{FS="dim1"}{print $2}'`;
dim2=`fslinfo $j | grep dim2 | awk 'BEGIN{FS="dim2"}{print $2}'`;
dim3=`fslinfo $j | grep dim3 | awk 'BEGIN{FS="dim3"}{print $2}'`;
dim4=`fslinfo $j | grep dim4 | awk 'BEGIN{FS="dim4"}{print $2}'`;
xdim=`echo ${dim1} | awk 'BEGIN{FS=" "}{print $1}'`;
ydim=`echo ${dim2} | awk 'BEGIN{FS=" "}{print $1}'`;
zdim=`echo ${dim3} | awk 'BEGIN{FS=" "}{print $1}'`;
dir=`echo ${dim4} | awk 'BEGIN{FS=" "}{print $1}'`;
xpix=`echo ${dim1} | awk 'BEGIN{FS=" "}{print $2}'`;
ypix=`echo ${dim2} | awk 'BEGIN{FS=" "}{print $2}'`;
zpix=`echo ${dim3} | awk 'BEGIN{FS=" "}{print $2}'`;
echo ${j}, ${xdim}, ${ydim}, ${zdim}, ${dir}, ${xpix}, ${ypix}, ${zpix} >> ${info_rsfmri};
echo ${j}, ${xdim}, ${ydim}, ${zdim}, ${dir}, ${xpix}, ${ypix}, ${zpix};
done

for j in `ls ${PROCESS}/DTI_RAW/${subj}_*_dti.nii*`;
do
dim1=`fslinfo $j | grep dim1 | awk 'BEGIN{FS="dim1"}{print $2}'`;
dim2=`fslinfo $j | grep dim2 | awk 'BEGIN{FS="dim2"}{print $2}'`;
dim3=`fslinfo $j | grep dim3 | awk 'BEGIN{FS="dim3"}{print $2}'`;
dim4=`fslinfo $j | grep dim4 | awk 'BEGIN{FS="dim4"}{print $2}'`;
xdim=`echo ${dim1} | awk 'BEGIN{FS=" "}{print $1}'`;
ydim=`echo ${dim2} | awk 'BEGIN{FS=" "}{print $1}'`;
zdim=`echo ${dim3} | awk 'BEGIN{FS=" "}{print $1}'`;
dir=`echo ${dim4} | awk 'BEGIN{FS=" "}{print $1}'`;
xpix=`echo ${dim1} | awk 'BEGIN{FS=" "}{print $2}'`;
ypix=`echo ${dim2} | awk 'BEGIN{FS=" "}{print $2}'`;
zpix=`echo ${dim3} | awk 'BEGIN{FS=" "}{print $2}'`;
echo ${j}, ${xdim}, ${ydim}, ${zdim}, ${dir}, ${xpix}, ${ypix}, ${zpix} >> ${info_dti};
echo ${j}, ${xdim}, ${ydim}, ${zdim}, ${dir}, ${xpix}, ${ypix}, ${zpix};
done
done
fi
