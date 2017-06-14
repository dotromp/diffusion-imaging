#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Calculate Signal to Noise ratio

if [ $# -lt 12 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo This will calculate the Signal to Noise ratio.
echo Usage:
echo sh snr.sh {process_dir} {num} {b0} {bvalue} {grad_dir_txt} {snr_txt} {bvec_txt} {bval_txt} {scheme_txt} {eddy_prefix} {strip_prefix} {camino_dwi} {subject}
echo eg:
echo snr.sh /study/scratch/MRI etc etc 001
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

echo ~~~Calculate SNR~~~
cd ${PROCESS}/CORRECTED

for j in ${subject};
do
	echo dti_recon ${strip_prefix}.nii.gz ${strip_prefix}_DTK -b0 ${b0} -b ${bvalue} -gm ${grad_dir_txt} -no_tensor -no_eigen
	dti_recon ${strip_prefix}.nii.gz ${strip_prefix}_DTK -b0 ${b0} -b ${bvalue} -gm ${grad_dir_txt} -no_tensor -no_eigen
	
	echo ~~~Make SCHEME files~~~
	rm -f ${eddy_prefix}*.mat
	sh ${my_script}/newecc.sh ${eddy_prefix}.ecclog
	sh ${my_script}/rotate_bvectors.sh ${bvec_txt} ${strip_prefix}.bvecs ${eddy_prefix}
	rm -f ${eddy_prefix}*.mat
	fsl2scheme -bvecfile ${strip_prefix}.bvecs -bvalfile ${bval_txt} -flipx -flipy -usegradmod > ${scheme_txt}
	
	my_image2voxel -4dimage ${strip_prefix}.nii.gz > ${camino_dwi}.Bfloat
	
if [ ${num} == "13" ];
then
	echo "NOTE DO NOT USE for single B0 - USE snr_1dir.sh instead"
else
	fslmaths ${strip_prefix}_DTK_fa.nii -bin -ero -ero ${strip_prefix}_DTK_mask;
	fslmaths ${strip_prefix}_DTK_fa.nii -mul ${strip_prefix}_DTK_mask.nii.gz ${strip_prefix}_DTK_fa_wm;
	fslmaths ${strip_prefix}_DTK_fa_wm.nii -thr 0.25 -bin ${strip_prefix}_DTK_fa_wm;
	
	echo ~~~Calculate SNR with more than 2 b0 images~~~
	echo estimatesnr -inputfile ${camino_dwi}.Bfloat -schemefile ${scheme_txt} -bgmask ${strip_prefix}_DTK_fa_wm.nii.gz > ${strip_prefix}_snr.txt
	estimatesnr -inputfile ${camino_dwi}.Bfloat -schemefile ${scheme_txt} -bgmask ${strip_prefix}_DTK_fa_wm.nii.gz > ${strip_prefix}_snr.txt
	snr=`cat ${strip_prefix}_snr.txt |grep SNR|grep mult|awk 'BEGIN{FS=":"}{print $2}'`;
	sigma=`cat ${strip_prefix}_snr.txt |grep sigma|grep mult|awk 'BEGIN{FS=":"}{print $2}'`;
	echo ${strip_prefix}, ${snr}, ${sigma} >> ${snr_txt};
	echo SNR is: ${snr};
	rm -f ${strip_prefix}_DTK*
	rm -f ${strip_prefix}.bvecs
	rm -f ${strip_prefix}_snr.txt
fi
done
fi
