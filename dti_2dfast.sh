#!/bin/bash
# Do Tromp 2013
# Make dti and 2dfast text file

if [ $# -lt 1 ]
then
echo
echo "ERROR, not enough input variables"
echo
echo "This script makes a compare file of dti and 2dfast files"
echo "Usage:"
echo "dti_2dfast.sh {process_dir}"
echo "eg:"
echo "dti_2dfast.sh /Volumes/Shelton/"
echo

else
PROCESS=$1

cd ${PROCESS}/DTI_RAW
out_both=${PROCESS}/dti_2dfast.txt
rm -f ${out_both}
out_dti=${PROCESS}/dti.txt
rm -f ${out_dti}

for i in `ls *dti.nii* *hydie.nii*`;
do
subj=`echo $i | awk 'BEGIN{FS="_"}{print $1}'`
scan=`echo $i | awk 'BEGIN{FS="_"}{print $2}' | awk 'BEGIN{FS="_"}{print $1}' | cut -c2- | sed -e 's:^0*::'`;
num=$(( $scan + 1 ))
cd ${PROCESS}/2DFAST
for j in `ls ${subj}_[sS]*${num}_2dfast.nii*`;
do

echo ${i}, ${j} >> ${out_both}
echo ${i}, ${j}

#echo ${i} >> ${out_dti}

done
done

echo
echo ~~~Move non-used fmaps to tmp file~~~
mkdir ${PROCESS}/2DFAST/tmp
mv ${PROCESS}/2DFAST/*.* ${PROCESS}/2DFAST/tmp
for i in `cat ${out_both}|awk 'BEGIN{FS=", "}{print $2}'`;
do
mv ${PROCESS}/2DFAST/tmp/${i} ${PROCESS}/2DFAST/;
done
fi
