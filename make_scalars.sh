#!/bin/bash
# Do Tromp 2013
# Make scalars

if [ $# -lt 3 ]
then
	echo
	echo "ERROR, not enough input variables"
	echo
	echo "This script makes scalars"
	echo "Usage:"
	echo "make_scalars.sh {process_dir} {out_dir} {maps} {subj}"
	echo "eg:"
	echo "make_scalars.sh /study/mri/TEMPLATE /study/mri/SCALARS fa 001 002"
	echo
	echo "maps= fa/all, either make all scalars maps or only fa map."
else
	dir=$1
	outdir=$2
	map=$3
	shift 3
	subject=$*
	cd ${dir}

	for j in ${subject};
	do
		subj=`echo $j | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`
		for i in `ls ${subj}*sdt*.nii*`;
		do
			prefix=`echo $i | awk 'BEGIN{FS=".nii"}{print $1}'`
			if [ ! -f ${outdir}/${prefix}_fa.nii.gz ];
			then			
				echo ~~~Make Scalars~~~;			
				if [ $map == "all" ]
				then
					TVtool -in $i -fa -out ${outdir}/${prefix}_fa.nii.gz
					TVtool -in $i -tr -out ${outdir}/${prefix}_tr.nii.gz
					TVtool -in $i -rd -out ${outdir}/${prefix}_rd.nii.gz
					TVtool -in $i -ad -out ${outdir}/${prefix}_ad.nii.gz
				else
					TVtool -in $i -fa -out ${outdir}/${prefix}_fa.nii.gz
				fi
			else
				echo
				echo "NOTE: Scalar calculation already completed for subject ${subject}";
			fi;
		done
	done
fi
