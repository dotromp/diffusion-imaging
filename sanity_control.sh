#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Run Sanity Control

if [ $# -lt 7 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo Run Sanity Control
echo Usage:
echo sh sanity_control.sh {process_dir} {sigma} {camino_dwi} {strip_prefix} {scheme_txt} {camino_dti} {dt_prefix} {subject}
echo eg:
echo sanity_control.sh /study/scratch/MRI etc etc 001
echo 

else

echo "Process directory: "$1
PROCESS=$1
sigma=$2
camino_dwi=$3
strip_prefix=$4
scheme_txt=$5
camino_dti=$6
dt_prefix=$7

shift 7
subject=$*

cd ${PROCESS}/CAMINO
for j in ${subject};
do

echo Extracting Voxel and Pixel dimensions
xdim=`fslinfo ${PROCESS}/CORRECTED/$prefix.nii.gz |grep 'dim1'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
ydim=`fslinfo ${PROCESS}/CORRECTED/$prefix.nii.gz |grep 'dim2'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
zdim=`fslinfo ${PROCESS}/CORRECTED/$prefix.nii.gz |grep 'dim3'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
xpix=`fslinfo ${PROCESS}/CORRECTED/$prefix.nii.gz |grep 'pixdim1'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
ypix=`fslinfo ${PROCESS}/CORRECTED/$prefix.nii.gz |grep 'pixdim2'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
zpix=`fslinfo ${PROCESS}/CORRECTED/$prefix.nii.gz |grep 'pixdim3'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
echo "xdim: "$xdim" ydim: "$ydim" zdim: "$zdim" xpix: "$xpix" ypix: "$ypix" zpix: "$zpix

echo ~~~Tensor calculation using RESTORE~~~;
echo $my_script/my_modelfit -inputfile ${camino_dwi}.Bfloat -schemefile ${scheme_txt} -inputdatatype float -outputdatatype float -inversion -2 -sigma ${sigma} -outputfile ${camino_dti}.Bfloat 2> ${subject}_tmp.txt
$my_script/my_modelfit -inputfile ${camino_dwi}.Bfloat -schemefile ${scheme_txt} -inputdatatype float -outputdatatype float -inversion -2 -sigma ${sigma} -outputfile ${camino_dti}.Bfloat 2> ${subject}_tmp.txt

echo ~~~SANITY CHECK~~~
dteig -inputmodel dt -inputdatatype float -outputdatatype float < ${PROCESS}/CAMINO/$prefix"_rest_DTI".Bfloat > ${PROCESS}/TENSOR/$prefix"_rest_DTI_EIG".Bfloat
pdview -inputdatatype float -inputmodel dteig -inputfile ${PROCESS}/TENSOR/$prefix"_rest_DTI_EIG".Bfloat -datadims $xdim $ydim $zdim &

done

fi
