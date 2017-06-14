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
echo "sh create_fmap.sh {raw_input_dir} {process_dir} {mask_or_not} {mask} {fmap_prefix} {twodfast_raw} {subjs_separate_by_space}"
echo eg:
echo
echo create_fmap.sh /study/mri/raw-data /study5/aa-scratch/MRI mask /study/etc/MASK/001_mask /study/etc/FMAP/001_fmap 002 003 004 
echo
echo pr-existing_mask = mask or nomask, if pre-existing mask is available location in output_dir/MASK or not, respectively
echo
echo Script used: http://brainimaging.waisman.wisc.edu/~jjo/fieldmap_correction/make_fmap.html

else

raw=$1
PROCESS=$2
mask=$3
mask_prefix=$4
fmap_prefix=$5
twodfast_raw=$6

shift 6
subject=$*

for i in ${subject};
do
cd ${raw}/${i}/dicoms/;
subj=`echo $i | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`

if [ $mask == "nomask" ]
then
echo ~~~MAKE FMAP without pre-existing mask~~~
#for k in `ls -d *_2dfast *_fmap`;
#for k in `ls -d *_2dfast`;
#do
make_fmap ${twodfast_raw} ${fmap_prefix};
echo Written:
ls -lthr ${fmap_prefix}*
#done

else
echo ~~~MAKE FMAP with pre-existing mask~~~
#for k in `ls -d *_2dfast *_fmap`;
#for k in `ls -d *_2dfast`;
#do
make_fmap ${twodfast_raw} ${fmap_prefix} -m ${mask_prefix}.nii.gz;
echo Written:
ls -ltrh ${fmap_prefix}*

fi

#echo ~~~Output txt files~~~
#cd ${PROCESS}/DTI_RAW
#for l in `ls ${subj}*dti.nii* ${subj}*hydie.nii*`;
#do
##subj=`echo $l | awk 'BEGIN{FS="_"}{print $1}'`
#scan=`echo $l | awk 'BEGIN{FS="_"}{print $2}' | awk 'BEGIN{FS="_"}{print $1}' | cut -c2- | sed -e 's:^0*::'`;
#num=$(( $scan + 1 ))
#cd ${PROCESS}/2DFAST
#for j in `ls ${subj}_[sS]*${num}_2dfast.nii*`;
#do

#echo ${l}, ${j} >> ${out_both}
#echo ${l}, ${j}

#echo ${l} >> ${out_dti}
#done
#done

cd ${raw}
done
fi
