#!/bin/bash

# source dtitk_common.sh
#. dtitk_common.sh
export PATH=$PATH:.
template=$1

rm -f subjects_diffeo.txt

for subj_dif in `ls toT1*diffeo.nii.gz`
do
	echo ${subj_dif} >> subjects_diffeo.txt
echo ${subj_dif}
done

echo "TVMean" 

TVMean -in subjects_diffeo.txt -out ${template}

#ls -al
