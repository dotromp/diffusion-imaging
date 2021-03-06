#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Calculate Robust Tensor estimation

if [ $# -lt 7 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo This will calculate the tensors using a robust-RESTORE estimation
echo Usage:
echo sh tensor_rest.sh {process_dir} {sigma} {camino_dwi} {strip_prefix} {scheme_txt} {camino_dti} {dt_prefix} {subject}
echo eg:
echo tensor_rest.sh /study/scratch/MRI etc etc 001
echo 
echo Needs output of bval_bvec.sh
echo

else

PROCESS=$1
sigma=$2
camino_dwi=$3
strip_prefix=$4
scheme_txt=$5
camino_dti=$6
dt_prefix=$7

shift 7
subject=$*

if [ ! -f ${dt_prefix}dt.nii.gz ];
then
	cd ${PROCESS}/CAMINO
	for j in ${subject};
	do
		xdim=`fslinfo ${strip_prefix}.nii.gz |grep 'dim1'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
		ydim=`fslinfo ${strip_prefix}.nii.gz |grep 'dim2'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
		zdim=`fslinfo ${strip_prefix}.nii.gz |grep 'dim3'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
		xpix=`fslinfo ${strip_prefix}.nii.gz |grep 'pixdim1'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
		ypix=`fslinfo ${strip_prefix}.nii.gz |grep 'pixdim2'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
		zpix=`fslinfo ${strip_prefix}.nii.gz |grep 'pixdim3'| sed -n '1p' | awk 'BEGIN{FS=" "}{print $2}'`
		echo "xdim: "$xdim" ydim: "$ydim" zdim: "$zdim" xpix: "$xpix" ypix: "$ypix" zpix: "$zpix
		fslmaths ${strip_prefix}.nii.gz -bin ${strip_prefix}_bin

		echo ~~~Tensor calculation using RESTORE~~~;
		echo $my_script/my_modelfit -inputfile ${camino_dwi}.Bfloat -schemefile ${scheme_txt} -inputdatatype float -outputdatatype float -inversion -2 -sigma ${sigma} -outputfile ${camino_dti}.Bfloat 2> ${subject}_tmp.txt
		$my_script/my_modelfit -inputfile ${camino_dwi}.Bfloat -schemefile ${scheme_txt} -inputdatatype float -outputdatatype float -inversion -2 -sigma ${sigma} -outputfile ${camino_dti}.Bfloat 2> ${subject}_tmp.txt

		#echo ~~~SANITY CHECK~~~;
		#echo dteig -inputmodel dt -inputdatatype float -outputdatatype float < ${camino_dti}.Bfloat > ${PROCESS}/TENSOR/$prefix"_rest_DTI_EIG".Bfloat
		#dteig -inputmodel dt -inputdatatype float -outputdatatype float < ${camino_dti}.Bfloat > ${PROCESS}/TENSOR/$prefix"_rest_DTI_EIG".Bfloat
		#pdview -inputdatatype float -inputmodel dteig -inputfile ${PROCESS}/TENSOR/$prefix"_rest_DTI_EIG".Bfloat -datadims $xdim $ydim $zdim &

		echo ~~~CAMINO to NIFTI~~~;
		echo dt2nii -inputfile ${camino_dti}.Bfloat -inputdatatype float -header ${strip_prefix}.nii.gz -outputroot ${dt_prefix}
		dt2nii -inputfile ${camino_dti}.Bfloat -inputdatatype float -header ${strip_prefix}.nii.gz -outputroot ${dt_prefix}

		rm -f ${subject}_tmp.txt
		rm -f ${camino_dwi}.Bfloat
		rm -f ${strip_prefix}_bin
		rm -f ${camino_dti}.Bfloat
		rm -f ${dt_prefix}lns0.nii.gz
		rm -f ${dt_prefix}exitcode.nii.gz
		echo Written:
		ls -ltrh ${dt_prefix}*;
	done
else
echo
echo "NOTE: Tensor calculation already completed for subject ${subject}";
fi;
fi
