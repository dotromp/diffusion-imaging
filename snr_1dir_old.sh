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
echo sh snr_1dir.sh {process_dir} {subjects}
echo eg:
echo snr_1dir.sh /study/scratch/MRI 001 002
echo 
echo Needs output of bvec_bval.sh
echo

else
echo "Process directory: "$1
PROCESS=$1
mkdir -p -v ${PROCESS}/SNR

shift 1
subject=$*
snr_txt=${PROCESS}/snr_all.txt
#rm -f ${snr_txt};

echo ~~~Calculate SNR~~~
cd ${PROCESS}/EDDY
pwd

for j in ${subject};
do
subj=`echo $j | tr "." "-"| awk -F"/" '{$1=$1}1' OFS=""`

##REMEMBER DONT USE MASKED FOR 1DIR DATA
##for i in `ls ${subj}*_masked.nii*`;
for i in `ls ${subj}*.nii*`;
do 
prefix=`echo $i | awk 'BEGIN{FS=".nii"}{print $1}'`;
eddy=`echo $i | awk 'BEGIN{FS="_eddy"}{print $1}'`_eddy;
num=`fslinfo ${i}|grep ^dim4|awk 'BEGIN{FS="4"}{print $2}'| sed 's/ //g'`
b0=`cat ${PROCESS}/info_bvals_${num}.txt|grep b0:|awk 'BEGIN{FS=" "}{print $2}'| sed 's/ //g'`
bvalue=`tail -n 1 ${PROCESS}/bvals_${num}.txt| sed 's/ //g'`

echo Prefix is: ${prefix}
echo Eddy is: ${eddy}
echo Directions is: ${num}

dti_recon ${i} ${prefix}_DTK -b0 $b0 -b $bvalue -gm ${PROCESS}/grad_dir_$num.txt -no_tensor -no_eigen;
#dti_recon $i ${prefix}_DTK -gm ${PROCESS}/grad_dir_${num}.txt -no_tensor -no_eigen

echo ~~~Make SCHEME files~~~
rm -f ${PROCESS}/EDDY/${eddy}*.mat
sh ${my_script}/newecc.sh ${PROCESS}/EDDY/${eddy}.ecclog
sh ${my_script}/rotate_bvectors.sh ${PROCESS}/bvecs_${num}.txt ${PROCESS}/SCHEME/${prefix}.bvecs ${PROCESS}/EDDY/${eddy}
rm -f ${PROCESS}/EDDY/${eddy}*.mat
fsl2scheme -bvecfile ${PROCESS}/SCHEME/${prefix}.bvecs -bvalfile ${PROCESS}/bvals_${num}.txt -flipx -flipy -usegradmod > ${PROCESS}/SCHEME/${prefix}.scheme
##fsl2scheme -bvecfile ${PROCESS}/SCHEME/${prefix}.bvecs -bvalfile ${PROCESS}/bvals_${num}.txt > ${PROCESS}/SCHEME/${prefix}.scheme
sed -i 1d ${PROCESS}/SCHEME/${prefix}.scheme
sed -i 1d ${PROCESS}/SCHEME/${prefix}.scheme
sed -i 1i"VERSION: 2" ${PROCESS}/SCHEME/${prefix}.scheme

#echo ~~~Make SCHEME files~~~
#rm -f ${PROCESS}/EDDY/${eddy}*.mat
#sh ${my_script}/newecc.sh ${PROCESS}/EDDY/${eddy}.ecclog
#sh ${my_script}/rotate_bvectors.sh ${PROCESS}/bvecs_${num}.txt ${PROCESS}/SCHEME/${prefix}.bvecs ${PROCESS}/EDDY/${eddy}
#rm -f ${PROCESS}/EDDY/${eddy}*.mat
#fsl2scheme -bvecfile ${PROCESS}/SCHEME/${prefix}.bvecs -bvalfile ${PROCESS}/bvals_${num}.txt -flipx -flipy -usegradmod > ${PROCESS}/SCHEME/${prefix}.scheme

echo ~~~NIFTI to CAMINO~~~
my_image2voxel -4dimage ${i} > ${PROCESS}/CAMINO/$prefix"_DWI".Bfloat

if [ ${num} == "13" ];
then
echo ~~~PRODUCE SCALARS~~~
fslmaths ${prefix}_DTK_fa.nii -bin -ero -ero ${prefix}_DTK_mask;
fslmaths ${prefix}_DTK_fa.nii -mul ${prefix}_DTK_mask.nii.gz ${prefix}_DTK_fa_wm;
fslmaths ${prefix}_DTK_fa_wm.nii -thr 0.25 -bin ${prefix}_DTK_fa_wm;
fslmaths ${prefix}_DTK_fa.nii -bin -dilM -dilM -dilM -dilM -dilM -add 1 -uthr 1.5 ${prefix}_DTK_background;

echo ~~~Calculate SNR with 1 b0 image~~~
estimatesnr -inputfile ${PROCESS}/CAMINO/$prefix"_DWI".Bfloat -schemefile ${PROCESS}/SCHEME/${prefix}*.scheme -bgmask ${prefix}_DTK_fa_wm.nii.gz -noiseroi ${prefix}_DTK_background.nii.gz > ${PROCESS}/SNR/${prefix}_snr.txt

echo ~~~Write snr and sigma value~~~
snr=`cat ${PROCESS}/SNR/${prefix}_snr.txt |grep SNR|grep stdv|awk 'BEGIN{FS=":"}{print $2}'`;
sigma=`cat ${PROCESS}/SNR/${prefix}_snr.txt |grep sigma|grep stdv|awk 'BEGIN{FS=":"}{print $2}'`;
echo ${i}, ${snr}, ${sigma} >> ${snr_txt};
echo ${i}, ${snr}, ${sigma};

rm -f ${prefix}_DTK*

else
echo ~~~PRODUCE SCALARS~~~
fslmaths ${prefix}_DTK_fa.nii -bin -ero -ero ${prefix}_DTK_mask;
fslmaths ${prefix}_DTK_fa.nii -mul ${prefix}_DTK_mask.nii.gz ${prefix}_DTK_fa_wm;
fslmaths ${prefix}_DTK_fa_wm.nii -thr 0.25 -bin ${prefix}_DTK_fa_wm;

echo ~~~Calculate SNR with more than 2 b0 images~~~
estimatesnr -inputfile ${PROCESS}/CAMINO/$prefix"_DWI".Bfloat -schemefile ${PROCESS}/SCHEME/${subj}*.scheme -bgmask ${prefix}_DTK_fa_wm.nii.gz > ${PROCESS}/SNR/${prefix}_snr.txt

echo ~~~Write sigma value~~~
snr=`cat ${PROCESS}/SNR/${prefix}_snr.txt |grep SNR|grep mult|awk 'BEGIN{FS=":"}{print $2}'`;
sigma=`cat ${PROCESS}/SNR/${prefix}_snr.txt |grep sigma|grep mult|awk 'BEGIN{FS=":"}{print $2}'`;
echo ${i}, ${snr}, ${sigma} >> ${snr_txt};
echo ${i}, ${snr}, ${sigma};

rm -f ${prefix}_DTK*
rm -f ${PROCESS}/CAMINO/$prefix"_DWI".Bfloat
fi
done
done


fi
