# source dtitk_common.sh
#. dtitk_common.sh
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
echo sh bootstrap.sh {process_dir} {out_file} {in}
echo eg:
echo bootstrap.sh /study/scratch/MRI mean_sdt.nii.gz "subj_*sdt.nii.gz"
echo 

else
echo "Process directory: "$1
PROCESS=$1
echo Process dir: ${PROCESS}
template=$2
echo Output files: ${template}

shift 2
input=$*
echo Input file: ${input}

rm -f subjects.txt

#echo ${input} > subjects.txt
for subj_dif in `ls ${input}`
do
	echo ${subj_dif} >> subjects.txt
echo ${subj_dif}
done

echo "~~~Bootstrap files~~~" 
echo TVMean -in subjects.txt -out ${template}
TVMean -in subjects.txt -out ${template}
echo TVtool -in ${template} -fa;
TVtool -in ${template} -fa;
fi
#ls -al
