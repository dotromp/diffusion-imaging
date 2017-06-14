#!/bin/bash
# Do Tromp 2013
# Run tractography on standardized tensor file

if [ $# -lt 3 ]
then
echo
echo "ERROR, not enough input variables"
echo
echo "This script runs tractography on a standardized tensor file"
echo "Usage:"
echo "tractography.sh {process_dir} {fa_cut_off} {curve_threshold} {tensor_files}"
echo "eg:"
echo "tractography.sh /study/mri 0.2 90 mean_sdt.nii.gz 001_sdt.nii.gz"
echo

else
PROCESS=$1
fa_cut=$2
curve_cut=$3

shift 3
subject=$*

echo ~~~Run tractography~~~
dir=${PROCESS}
cd ${PROCESS}
echo ~~~Current dir~~~
pwd
for i in ${subject};
do
prefix=`echo $i | awk 'BEGIN{FS=".nii"}{print $1}'`;
echo $prefix;
echo TVtool -in $i -fa
TVtool -in $i -fa

echo ~~~making wm masks~~~
fslmaths ${prefix}_fa.nii.gz -bin -ero -ero ${prefix}_mask;
fslmaths ${prefix}_fa.nii.gz -mul ${prefix}_mask.nii.gz ${prefix}_wm;
fslmaths ${prefix}_wm.nii -thr ${fa_cut} -bin ${prefix}_wm
fslswapdim ${prefix}_wm.nii.gz -x y -z ${prefix}_wm_xz

echo ~~~nifti 2 camino~~~
echo my_nii2dt -inputfile ${i} -outputdatatype float ">" ${prefix}_DTI.Bfloat;
##nii2dt -inputfile ${i} -outputdatatype float > ${prefix}_DTI.Bfloat;
my_nii2dt -inputfile ${i} -outputdatatype float > ${prefix}_DTI.Bfloat;
echo ~~Track~~
##echo track -inputmodel dt -inputdatatype float -outputdatatype float -seedfile ${prefix}_wm.nii.gz -inputfile ${prefix}_DTI.Bfloat -outputfile ${prefix}_Tracts.Bfloat -tend -anisthresh 0.15 -ipthresh 0.7071 -interpolate vectors
##track -inputmodel dt -inputdatatype float -outputdatatype float -seedfile ${prefix}_wm.nii.gz -inputfile ${prefix}_DTI.Bfloat -outputfile ${prefix}_Tracts.Bfloat -tend -anisthresh 0.15 -ipthresh 0.7071 -interpolate vectors
echo track -inputmodel dt -inputdatatype float -outputdatatype float -seedfile ${prefix}_wm.nii.gz -inputfile ${prefix}_DTI.Bfloat -outputfile ${prefix}_Tracts.Bfloat -tracker rk4 -stepsize 0.625 -interpolator tend -anisthresh ${fa_cut} -curvethresh ${curve_cut} 
track -inputmodel dt -inputdatatype float -outputdatatype float -seedfile ${prefix}_wm.nii.gz -inputfile ${prefix}_DTI.Bfloat -outputfile ${prefix}_Tracts.Bfloat -tracker rk4 -stepsize 0.625 -interpolator tend -anisthresh ${fa_cut} -curvethresh ${curve_cut} 
##echo track -inputmodel dt -inputdatatype float -outputdatatype float -seedfile ${prefix}_wm.nii.gz -inputfile ${prefix}_DTI.Bfloat -outputfile ${prefix}_Tracts.Bfloat -tracker fact -interpolator tend 
##track -inputmodel dt -inputdatatype float -outputdatatype float -seedfile ${prefix}_wm.nii.gz -inputfile ${prefix}_DTI.Bfloat -outputfile ${prefix}_Tracts.Bfloat -tracker fact -interpolator tend 
$my_script/camino_to_trackvis -i ${prefix}_Tracts.Bfloat -o ${prefix}_Tracts.trk --nifti ${prefix}_wm_xz.nii.gz
rm -f ${prefix}*sdt_mask.nii.gz;
rm -f ${prefix}*_wm*.nii.gz;
rm -f ${prefix}*Tracts.Bfloat;
rm -f ${prefix}*DTI.Bfloat;
done


fi
