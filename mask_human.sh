#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Mask human data 

if [ $# -lt 2 ]
then
	echo
	echo ~ERROR, not enough input variables~
	echo
	echo This will remove the rim around DTI brain data.
	echo Usage:
	echo sh mask_human.sh {process_dir} {mask_prefix} {corrected_prefix} {subjects}
	echo eg:
	echo mask_human.sh /study/scratch/MRI mask prefix 001 002
	echo 
	echo Needs output of bval_bvec.sh
	echo

else
	PROCESS=$1
	mask_prefix=$2
	corrected_prefix=$3
	shift 3
	subject=$*

	cd ${PROCESS}/CORRECTED
	for j in ${subject};
	do
		subj=`echo $j | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`
		for i in `ls ${corrected_prefix}.nii*`;
		do
			if [ ! -f ${mask_prefix}.nii.gz ];
			then
				gzip -f ${corrected_prefix}*.nii
				prefix=`echo ${mask_prefix} | awk 'BEGIN{FS="_mask"}{print $1}'`
				echo ~~MASK~~~
				echo bet ${i} ${prefix} -m -n;
				bet ${i} ${prefix} -m -n;
				echo fslmaths ${i} -mas ${mask_prefix}.nii.gz ${corrected_prefix};
				fslmaths ${i} -mas ${mask_prefix}.nii.gz ${corrected_prefix};
				echo Written:
				ls -ltrh ${corrected_prefix}*.nii*
			else
				echo
				echo "NOTE: Mask already completed for subject ${subject}";
			fi;
		done
	done
fi
