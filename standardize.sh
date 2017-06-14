#!/bin/bash
# Do Tromp 2013
# Standardize images for nomalization step

if [ $# -lt 3 ]
then
	echo
	echo "ERROR, not enough input variables"
	echo
	echo "This script standardizes images before nomalization"
	echo "Usage:"
	echo "standardize.sh {process_dir} {species} {subj}"
	echo "eg:"
	echo "standardize.sh /study/mri nhp 001 002"
	echo
else
	PROCESS=$1
	species=$2
	shift 2
	subject=$*
	dir=${PROCESS}/TENSOR
	outdir=${PROCESS}/TEMPLATE
	cd ${dir}
	for j in ${subject};
	do
		subj=`echo $j | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`
		for i in `ls ${subj}*_dt.nii*`;
		do
			prefix=`echo $i | awk 'BEGIN{FS="_dt.nii"}{print $1}'`
			if [ ! -f ${outdir}/$prefix"_sdt".nii.gz ];
			then				
				echo ~~~Run Standardization~~~
				echo ~~Adjusting Diffusivity Units~~
				echo TVtool -in $i -scale 1000000000 -out $prefix"_sdt".nii.gz
				TVtool -in $i -scale 1000000000 -out $prefix"_sdt".nii.gz
				echo
				echo ~~Making and applying Mask~~
				TVtool -in $prefix"_sdt".nii.gz -tr
				BinaryThresholdImageFilter $prefix"_sdt_tr".nii.gz ${prefix}_mask.nii.gz 0.5 100 1 0
				echo TVtool -in $prefix"_sdt".nii.gz -out ${prefix}_tmp.nii.gz -mask ${prefix}_mask.nii.gz
				TVtool -in $prefix"_sdt".nii.gz -out ${prefix}_tmp.nii.gz -mask ${prefix}_mask.nii.gz
				mv -f ${prefix}_tmp.nii.gz $prefix"_sdt".nii.gz
				echo
				echo ~~Checking for and removing Outliers~~
				TVtool -in $prefix"_sdt".nii.gz -norm
				SVtool -in $prefix"_sdt_norm".nii.gz -stats
				BinaryThresholdImageFilter $prefix"_sdt_norm".nii.gz ${prefix}_non_outliers.nii.gz 0 100 1 0
				echo TVtool -in $prefix"_sdt".nii.gz -mask ${prefix}_non_outliers.nii.gz -out $prefix"_tmp".nii.gz
				TVtool -in $prefix"_sdt".nii.gz -mask ${prefix}_non_outliers.nii.gz -out $prefix"_tmp".nii.gz
				mv -f ${prefix}_tmp.nii.gz $prefix"_sdt".nii.gz
				TVtool -in $prefix"_sdt".nii.gz -norm
				echo
				echo ~~~Stats for${prefix} - max should be below 100~~~
				SVtool -in $prefix"_sdt_norm".nii.gz -stats
				echo
				echo ~~Enforcing positive semi-definiteness~~
				echo TVtool -in $prefix"_sdt".nii.gz -spd -out $prefix"_tmp".nii.gz
				TVtool -in $prefix"_sdt".nii.gz -spd -out $prefix"_tmp".nii.gz
				mv -f ${prefix}_tmp.nii.gz $prefix"_sdt".nii.gz
				spds=`fslstats ${prefix}_sdt_nonSPD.nii.gz -V | awk 'BEGIN{FS=" "}{print $1}'`;
				echo ${prefix} ${spds} >> ${outdir}/number_of_spds.txt
				echo
		
				if [ $species == "nhp" ]
				then
					echo ~~Standardizing Voxel Space for non-human primates~~
					echo TVAdjustVoxelspace -in $prefix"_sdt".nii.gz -origin 0 0 0 -out ${outdir}/$prefix"_sdt".nii.gz
					TVAdjustVoxelspace -in $prefix"_sdt".nii.gz -origin 0 0 0 -out ${outdir}/$prefix"_sdt".nii.gz
					echo
					echo ~~~Reorient Image to LPI~~~
					echo TVtool -in ${outdir}/$prefix"_sdt".nii.gz -out ${outdir}/$prefix"_sdt_LPI".nii.gz -orientation LIP LPI
					TVtool -in ${outdir}/$prefix"_sdt".nii.gz -out ${outdir}/$prefix"_sdt_LPI".nii.gz -orientation LIP LPI
					echo TVResample -in ${outdir}/$prefix"_sdt_LPI".nii.gz -align center -size 256 256 256 -vsize 0.5 0.5 0.5 #monkey
					TVResample -in ${outdir}/$prefix"_sdt_LPI".nii.gz -align center -size 256 256 256 -vsize 0.5 0.5 0.5 #monkey
					rm -f ${outdir}/$prefix"_sdt".nii.gz
				else
					echo ~~Standardizing Voxel Space for human primates~~
					echo TVAdjustVoxelspace -in $prefix"_sdt".nii.gz -origin 0 0 0 -out ${outdir}/$prefix"_sdt".nii.gz
					TVAdjustVoxelspace -in $prefix"_sdt".nii.gz -origin 0 0 0 -out ${outdir}/$prefix"_sdt".nii.gz
				fi
			echo ~~~Cleaning up~~~
			rm -f ${prefix}_mask.nii.gz
			rm -f ${prefix}_sdt_tr.nii.gz
			rm -f ${prefix}_tmp.nii.gz
			rm -f ${prefix}_non_outliers.nii.gz
			rm -f ${prefix}_sdt_nonSPD.nii.gz
			rm -f ${prefix}_sdt_norm.nii.gz
			rm -f ${dir}/$prefix"_sdt".nii.gz
			echo
			echo Written:
			ls -ltrh ${outdir}/${prefix}_sdt*.nii.gz
			else
				echo
				echo "NOTE: Standardization already completed for subject ${subject}";
			fi;
		done
	done
fi
