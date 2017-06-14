#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# convert to camino

if [ $# -lt 2 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo This will convert to camino
echo Usage:
echo sh to_camino.sh {process_dir} {subjects}
echo eg:
echo to_camino.sh /study/scratch/MRI 001 002
echo 
echo

else
echo "Process directory: "$1
PROCESS=$1

shift 1
subject=$*

cd ${PROCESS}/CORRECTED
#pwd

for j in ${subject};
do
subj=`echo $j | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`;

for i in `ls ${subj}*_masked.nii*`;
do 
prefix=`echo $i | awk 'BEGIN{FS=".nii"}{print $1}'`;
echo Prefix is: ${prefix}

rm -f ${PROCESS}/CAMINO/${subj}*.Bfloat

echo ~~~NIFTI to CAMINO~~~;
echo "$my_script/my_image2voxel -4dimage ${i} > ${PROCESS}/CAMINO/${prefix}_DWI.Bfloat";
$my_script/my_image2voxel -4dimage ${i} > ${PROCESS}/CAMINO/${prefix}_DWI.Bfloat;

done
done


fi
