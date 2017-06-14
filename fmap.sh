#!/bin/bash
# Do Tromp 2013
# Make fieldmap

if [ $# -lt 4 ]
then
echo
echo ERROR, not enough input variables
echo
echo Make fieldmap for fieldmap correction.
echo Usage:
echo sh fmap.sh {raw_input_dir} {process_dir} {mask_or_not} {subjs_separate_by_space}
echo eg:
echo
echo fmap.sh /study/mri/raw-data /study5/aa-scratch/MRI mask 002 003 004 
echo
echo pr-existing_mask = mask or nomask, if pre-existing mask is available location in output_dir/MASK or not, respectively
echo
echo Script used: http://brainimaging.waisman.wisc.edu/~jjo/fieldmap_correction/make_fmap.html

else

raw=$1
echo "Input directory "$raw
PROCESS=$2
mkdir -p -v ${PROCESS}/FMAP
echo "Process directory: "$PROCESS
mask=$3

shift 3
subject=$*

for i in ${subject};
do

echo ~~~Subject in process: ${i}~~~
cd ${raw}/${i}/dicoms/;

subj=`echo $i | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`
echo ~~~Prefix is ${subj}~~~

if [ $mask == "nomask" ]
then
echo ~~~MAKE FMAP without pre-existing mask~~~
for k in `ls -d *_2dfast *_fmap`;
do
prefix=`echo $k | awk 'BEGIN{FS="/"}{print $1}'|awk 'BEGIN{FS="_"}{print $1}'`;
#subj=${i};
echo Scan is ${prefix}
#convert_file ${k} ${PROCESS}/2DFAST/${subj}_${prefix}_2dfast nii;
make_fmap $k ${PROCESS}/FMAP/${subj}_${prefix}_fmap;
done

else
echo ~~~MAKE FMAP with pre-existing mask~~~
for k in `ls -d *_2dfast *_fmap`;
do
prefix=`echo $k | awk 'BEGIN{FS="/"}{print $1}'|awk 'BEGIN{FS="_"}{print $1}'`;
#subj=${i};
echo Scan is ${prefix}
#convert_file ${k} ${PROCESS}/2DFAST/${subj}_${prefix}_2dfast nii;
make_fmap $k ${PROCESS}/FMAP/${subj}_${prefix}_fmap -m ${PROCESS}/MASK/${subj}_*mask.nii.gz;
done
fi

echo ~~~Output txt files~~~
out_both=${PROCESS}/dti_2dfast.txt
#rm -f ${out_both}
out_dti=${PROCESS}/dti.txt
#rm -f ${out_dti}

cd ${PROCESS}/DTI_RAW
for l in `ls ${subj}*dti.nii* ${subj}*hydie.nii*`;
do
#subj=`echo $l | awk 'BEGIN{FS="_"}{print $1}'`
scan=`echo $l | awk 'BEGIN{FS="_"}{print $2}' | awk 'BEGIN{FS="_"}{print $1}' | cut -c2- | sed -e 's:^0*::'`;
num=$(( $scan + 1 ))
cd ${PROCESS}/2DFAST
for j in `ls ${subj}_[sS]*${num}_2dfast.nii*`;
do

echo ${l}, ${j} >> ${out_both}
echo ${l}, ${j}

echo ${l} >> ${out_dti}
done
done

cd ${raw}
done
fi
