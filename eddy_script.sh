#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Run eddy current correction

if [ $# -lt 3 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo This command runs eddy current correction.
echo Usage:
echo sh eddy_script.sh {process_dir} {dti_prefix} {eddy_prefix} {subject}
echo eg:
echo sh eddy_script.sh /study/scratch/MRI /study/etc/DTI_RAW/001_dti /study/etc/EDDY/001_EDDY 001
echo 
echo Script used: http://fsl.fmrib.ox.ac.uk/fsl/fsl-4.1.9/fdt/fdt_eddy.html

else
PROCESS=$1
dti_prefix=$2
eddy_prefix=$3

shift 3
subject=$*
if [ ! -f ${eddy_prefix}.nii ];
then

	echo ~~~Eddy Correction~~~;
	for i in ${subject};
	do
		#rm -f ${eddy_prefix}.ecclog
		eddy_correct ${dti_prefix}.nii.gz ${eddy_prefix} 0;
		gunzip -f ${eddy_prefix}.nii.gz 
		echo Written:
		ls -ltrh ${eddy_prefix}*
	done

else
echo
echo "NOTE: Eddy correct already completed for subject ${subject}";
fi;
fi
