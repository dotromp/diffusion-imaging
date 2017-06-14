#!/bin/bash
# Do Tromp 2012
# Output scan info to screen and text document for group of subjects

if [ $# -lt 2 ]
then
echo
echo "ERROR, not enough input variables"
echo
echo "This script outputs scan info to screen and a text document for a group of subjects"
echo "Usage:"
echo "group_info.sh {input_dir} {suffix} {output_text_prefix}"
echo "eg:"

echo "group_info.sh . dti.nii info_all"
echo

echo "The output text file is easily importable into Excel since it's a comma separated. In
Excel do: "

echo "Data; Text to Columns; Delimited; Comma; Finish"


echo
else
dir=$1
cd $dir
suffix=$2
info=$3
echo ~~~Check image info~~~
rm -f ${info}.txt;
echo subject, xdim, ydim, zdim, volumes, xpix, ypix, zpix >> ${info}.txt
for i in `ls -tr *${suffix}`;
do
dim1=`fslinfo $i | grep dim1 | awk 'BEGIN{FS="dim1"}{print $2}'`;
dim2=`fslinfo $i | grep dim2 | awk 'BEGIN{FS="dim2"}{print $2}'`;
dim3=`fslinfo $i | grep dim3 | awk 'BEGIN{FS="dim3"}{print $2}'`;
dim4=`fslinfo $i | grep dim4 | awk 'BEGIN{FS="dim4"}{print $2}'`;
xdim=`echo ${dim1} | awk 'BEGIN{FS=" "}{print $1}'`;
ydim=`echo ${dim2} | awk 'BEGIN{FS=" "}{print $1}'`;
zdim=`echo ${dim3} | awk 'BEGIN{FS=" "}{print $1}'`;
dir=`echo ${dim4} | awk 'BEGIN{FS=" "}{print $1}'`;
xpix=`echo ${dim1} | awk 'BEGIN{FS=" "}{print $2}'`;
ypix=`echo ${dim2} | awk 'BEGIN{FS=" "}{print $2}'`;
zpix=`echo ${dim3} | awk 'BEGIN{FS=" "}{print $2}'`;
echo ${i}, ${xdim}, ${ydim}, ${zdim}, ${dir}, ${xpix}, ${ypix}, ${zpix} >> ${info}.txt;
echo ${i}, ${xdim}, ${ydim}, ${zdim}, ${dir}, ${xpix}, ${ypix}, ${zpix};
done
fi
