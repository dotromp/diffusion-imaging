#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Calculate new Scheme file

if [ $# -lt 12 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo This will calculate the Signal to Noise ratio.
echo Usage:
echo sh schemefile.sh {process_dir} {num} {b0} {bvalue} {grad_dir_txt} {snr_txt} {bvec_txt} {bval_txt} {scheme_txt} {eddy_prefix} {strip_prefix} {camino_dwi} {subject}
echo eg:
echo schemefile.sh /study/scratch/MRI etc etc 001
echo 
echo Needs output of bval_bvec.sh
echo
#not sure if this script works correctly for single b0 file - check fresno script/check DWI.bfloat mask.

else
PROCESS=$1
num=$2
b0=$3
bvalue=$4
grad_dir_txt=$5
snr_txt=$6
bvec_txt=$7
bval_txt=$8
scheme_txt=$9
eddy_prefix=${10}
strip_prefix=${11}
camino_dwi=${12}

mkdir -p -v ${PROCESS}/SNR

shift 12
subject=$*

cd ${PROCESS}/CORRECTED

for j in ${subject};
do

echo ~~~Make SCHEME files~~~
rm -f ${eddy_prefix}*.mat
sh ${my_script}/newecc.sh ${eddy_prefix}.ecclog
sh ${my_script}/rotate_bvectors.sh ${bvec_txt} ${strip_prefix}.bvecs ${eddy_prefix}
rm -f ${eddy_prefix}*.mat
#fsl2scheme -bvecfile ${strip_prefix}.bvecs -bvalfile ${bval_txt} -flipx -flipy -usegradmod > ${scheme_txt}
fsl2scheme -bvecfile ${strip_prefix}.bvecs -bvalfile ${bval_txt} -flipx -usegradmod > ${scheme_txt}

done

fi
