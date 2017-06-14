#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Use fieldmap to correct EPI distorted DTI data
# see also http://mri-xs.mri.psychiatry.wisc.edu/groups/kalinlab/wiki/47228/EPI_Distortion_Correction.html

if [ $# -lt 4 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo This corrects EPI distorted DTI data.
echo Usage:
echo sh fmap_script.sh {raw_data_dir} {process_dir} {pepolar} {eddy_prefix} {fmap_prefix} {subjects}
echo eg:
echo fmap_script.sh /study/mri/raw-data /study/scratch/MRI 0 /study/etc/EDDY/001_eddy /study/etc/FMAP/001_fmap 001 002
echo 
echo pepolar = 0 or 1 flip phase encoding direction, 0 is used for squished, 1 is used for stretched raw DWI
echo
echo Script used: http://mri-xs.mri.psychiatry.wisc.edu/groups/kalinlab/wiki/47228/EPI_Distortion_Correction.html
echo

else

raw=$1
PROCESS=$2
pepolar=$3
eddy_prefix=$4
fmap_prefix=$5

shift 5
subject=$*

if [ ! -f ${PROCESS}/CORRECTED/${subject}*_fm.nii* ];
then

	if [ $pepolar == 0 ]
	then
		echo ~~~FMAP Correct for 0 pepolar~~~
		for i in ${subject};
		do
			echo fieldmap_correction --beautify --pepolar ${fmap_prefix}.nii 0.800 ${PROCESS}/CORRECTED/ ${eddy_prefix}.nii;
			fieldmap_correction --beautify --pepolar ${fmap_prefix}.nii 0.800 ${PROCESS}/CORRECTED/ ${eddy_prefix}.nii;
			echo Written:
			ls -ltrh ${PROCESS}/CORRECTED/${subject}*_fm*
		done

	else
	echo ~~~FMAP Correct for 1 pepolar~~~
	for i in ${subject};
	do
		echo fieldmap_correction --beautify ${fmap_prefix}.nii 0.800 ${PROCESS}/CORRECTED/ ${eddy_prefix}.nii;
		fieldmap_correction --beautify ${fmap_prefix}.nii 0.800 ${PROCESS}/CORRECTED/ ${eddy_prefix}.nii;
		echo Written:
		ls -ltrh ${PROCESS}/CORRECTED/${subject}*_fm*
	done
	fi
else
echo
echo "NOTE: FMAP correct already completed for subject ${subject}";
fi;
fi

