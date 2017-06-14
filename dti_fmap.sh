#!/bin/bash
# Do Tromp 2013
# Make dti and fmap text file

if [ $# -lt 1 ]
then
echo
echo "ERROR, not enough input variables"
echo
echo "This script make a compare file of dti and 2dfast files"
echo "Usage:"
echo "dti_fmap.sh {process_dir}"
echo "eg:"
echo "dti_fmap.sh /Volumes/Shelton/"
echo

else
PROCESS=$1

cd ${PROCESS}/DTI_RAW
out_both=${PROCESS}/dti_fmap.txt
rm -f ${out_both}

for i in `ls *dti.nii* *hydie.nii*`;
do
subj=`echo $i | awk 'BEGIN{FS="_"}{print $1}'`
scan=`echo $i | awk 'BEGIN{FS="_"}{print $2}' | awk 'BEGIN{FS="_"}{print $1}' | cut -c2- | sed -e 's:^0*::'`;
num=$(( $scan + 1 ))
cd ${PROCESS}/FMAP
for j in `ls ${subj}_[sS]*${num}_fmap.nii*`;
do

echo ${i}, ${j} >> ${out_both}
echo ${i}, ${j}

done
done

echo
echo ~~~Move non-used fmaps to tmp file~~~
mkdir ${PROCESS}/FMAP/tmp
mv ${PROCESS}/FMAP/*.* ${PROCESS}/FMAP/tmp
for i in `cat ${out_both}|awk 'BEGIN{FS=", "}{print $2}'`;
do
mv ${PROCESS}/FMAP/tmp/${i} ${PROCESS}/FMAP/;
done
fi
