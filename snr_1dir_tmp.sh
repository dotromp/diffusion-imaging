#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Calculate Signal to Noise ratio

if [ $# -lt 2 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo This will calculate the Signal to Noise ratio.
echo Usage:
#echo sh snr_1dir.sh {process_dir} {subjects}
echo sh snr_1dir_bign.sh {process_dir} {num} {b0} {bvalue} {grad_dir_txt} {snr_txt} {bvec_txt} {bval_txt} {scheme_txt} {eddy_prefix} {strip_prefix} {camino_dwi} {subject}
echo eg:
echo snr_1dir_bign.sh /study/scratch/MRI 001 002
echo 
echo Needs output of bvec_bval.sh
echo

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

pwd

for j in ${subject};
do
echo REMEMBER DONT USE MASKED FOR 1DIR DATA

echo dti_recon ${eddy_prefix}.nii ${eddy_prefix}_DTK -b0 ${b0} -b ${bvalue} -gm ${grad_dir_txt} -no_tensor -no_eigen
dti_recon ${eddy_prefix}.nii ${eddy_prefix}_DTK -b0 ${b0} -b ${bvalue} -gm ${grad_dir_txt} -no_tensor -no_eigen


echo ~~~Make SCHEME files~~~
echo fsl2scheme -bvecfile ${bvec_txt} -bvalfile ${bval_txt} > ${scheme_txt}
fsl2scheme -bvecfile ${bvec_txt} -bvalfile ${bval_txt}  > ${scheme_txt}

echo ~~~NIFTI to CAMINO~~~
echo my_image2voxel -4dimage ${eddy_prefix}.nii > ${camino_dwi}.Bfloat
my_image2voxel -4dimage ${eddy_prefix}.nii > ${camino_dwi}.Bfloat


echo ~~~PRODUCE SCALARS~~~
fslmaths ${eddy_prefix}_DTK_fa.nii -bin -ero -ero ${eddy_prefix}_DTK_mask;
fslmaths ${eddy_prefix}_DTK_fa.nii -mul ${eddy_prefix}_DTK_mask.nii.gz ${eddy_prefix}_DTK_fa_wm;
fslmaths ${eddy_prefix}_DTK_fa_wm.nii -thr 0.25 -bin ${eddy_prefix}_DTK_fa_wm;
fslmaths ${eddy_prefix}_DTK_fa.nii -bin -dilM -dilM -dilM -dilM -dilM -add 1 -uthr 1.5 ${eddy_prefix}_DTK_background;


echo ~~~Calculate SNR with 1 b0 image~~~
echo estimatesnr -inputfile ${camino_dwi}.Bfloat -schemefile ${scheme_txt} -bgmask ${eddy_prefix}_DTK_fa_wm.nii.gz -noiseroi ${eddy_prefix}_DTK_background.nii.gz > ${strip_prefix}_snr.txt
estimatesnr -inputfile ${camino_dwi}.Bfloat -schemefile ${scheme_txt} -bgmask ${eddy_prefix}_DTK_fa_wm.nii.gz -noiseroi ${eddy_prefix}_DTK_background.nii.gz > ${strip_prefix}_snr.txt


echo ~~~Write snr and sigma value~~~
snr=`cat ${strip_prefix}_snr.txt |grep SNR|grep stdv|awk 'BEGIN{FS=":"}{print $2}'`;
sigma=`cat ${strip_prefix}_snr.txt |grep sigma|grep stdv|awk 'BEGIN{FS=":"}{print $2}'`;
echo ${strip_prefix}, ${snr}, ${sigma} >> ${snr_txt};
echo SNR is: ${snr};

#rm -f ${eddy_prefix}_DTK*
#rm -f ${strip_prefix}.bvecs
#rm -f ${strip_prefix}_snr.txt

cd ${PROCESS}/CORRECTED
echo my_image2voxel -4dimage ${strip_prefix}.nii.gz > ${camino_dwi}.Bfloat
my_image2voxel -4dimage ${strip_prefix}.nii.gz > ${camino_dwi}.Bfloat
done


fi
