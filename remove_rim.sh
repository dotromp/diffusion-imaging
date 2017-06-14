#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Remove rim around brain edge

if [ $# -lt 7 ]
then
	echo
	echo ~ERROR, not enough input variables~
	echo
	echo This will remove the rim around DTI brain data.
	echo Usage:
	echo sh remove_rim.sh {process_dir} {num} {b0} {bvalue} {grad_dir_txt} {corrected_prefix} {strip_prefix} {subject}
	echo eg:
	echo remove_rim.sh /study/scratch/MRI 57 8 1000 /study/etc/grad_dir_57.txt /study/etc/CORRECTED/001_dti_eddy_fmap /study/etc/CORRECTED/001_etc_strip 001
	echo 
	#echo Needs output of bval_bvec.sh

else

	PROCESS=$1
	num=$2
	b0=$3
	bvalue=$4
	grad_dir_txt=$5
	corrected_prefix=$6
	strip_prefix=$7 

	shift 7
	subject=$*

	if [ ! -f ${strip_prefix}.nii.gz ];
	then
		echo ~~REMOVE RIM~~
		cd ${PROCESS}/CORRECTED
		for j in ${subject};
		do
			echo dti_recon ${corrected_prefix}.nii* ${corrected_prefix}_DTK -b0 $b0 -b $bvalue -gm ${grad_dir_txt} -no_tensor -no_eigen;
			dti_recon ${corrected_prefix}.nii* ${corrected_prefix}_DTK -b0 $b0 -b $bvalue -gm ${grad_dir_txt} -no_tensor -no_eigen;
			fslmaths ${corrected_prefix}_DTK_dwi.nii -thrP 5 -bin ${corrected_prefix}_DTK_dwi_thrP;
			fslmaths ${corrected_prefix}_DTK_adc.nii -uthrP 95 -bin ${corrected_prefix}_DTK_adc_uthrP
			fslmaths ${corrected_prefix}_DTK_b0.nii -thrP 5 -bin ${corrected_prefix}_DTK_b0_thrP
			fslmaths ${corrected_prefix}_DTK_dwi_thrP.nii.gz -mas ${corrected_prefix}_DTK_adc_uthrP.nii.gz ${corrected_prefix}_DTK_tmp1
			fslmaths ${corrected_prefix}_DTK_tmp1.nii.gz -mas ${corrected_prefix}_DTK_b0_thrP.nii.gz ${corrected_prefix}_DTK_tmp2
			echo fslmaths ${corrected_prefix}.nii -mas ${corrected_prefix}_DTK_tmp2.nii.gz ${strip_prefix};
			fslmaths ${corrected_prefix}.nii -mas ${corrected_prefix}_DTK_tmp2.nii.gz ${strip_prefix};
			rm -f ${corrected_prefix}_DTK*
			
			echo Written:
			ls -ltrh ${strip_prefix}* 
		done
	else
		echo
		echo "NOTE: Rim removal already completed for subject ${subject}";
	fi;
fi
