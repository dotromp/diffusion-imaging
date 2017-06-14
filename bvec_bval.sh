#!/bin/bash
# Do Tromp 2013
# tromp@wisc.edu
# Make bvec and bval files

if [ $# -lt 4 ]
then
echo
echo ~ERROR, not enough input variables~
echo
echo This will make bvec and bval files for your data set.
echo Usage:
echo sh bvec_bval.sh {process_dir} {b-value} {sample_image_dicom_or_nifti} {format of sample}
echo eg:
echo bvec_bval.sh /study/scratch/MRI 1000 /study/raw/dicoms/s08_dti dicom
echo or
echo bvec_bval.sh /study/scratch/MRI 1000 102_s05_dti.nii nifti
echo
echo nifti file is assumed in DTI_RAW dir and unzipped
echo Find b-value in dicoms/info.txt or output root dir, often b=1000
echo
echo format = nifti or dicom

else

echo "Root directory "$1
PROCESS=$1
bvalue=$2
sample=$3
format=$4
cd ${PROCESS}

if [ $format == "nifti" ]
then
cp ${PROCESS}/DTI_RAW/$sample ${PROCESS}/sample.nii
else
convert_file ${sample} ${PROCESS}/sample nii
fi
num=`fslinfo sample.nii | grep ^dim4 | awk 'BEGIN{FS="4"}{print $2}' | sed 's/ //g'` 
echo ~Number of total directions: ${num}~

bvalout=bvals_${num}.txt
rm -f $bvalout
bvecout=bvecs_${num}.txt
rm -f $bvecout
binfo=info_bvals_${num}.txt
rm -f $binfo

echo ~~~Determine number of b0s and directional volumes~~~
fslstats -t sample.nii -M > stats.txt
cat stats.txt |cut -c1-3 > stats2.txt
mean=`fslstats sample.nii -M`
mean=`echo ${mean} | cut -c1-3`
#echo Mean: $mean
cat stats2.txt
b0=0
dir=0
echo ~~~Make bval txt file~~~
for i in `cat stats2.txt`;
do
if [ $i -gt $mean ]
then
b0=`expr $b0 + 1`
echo bval_${b0} equals 0
echo 0 >> ${bvalout}
else
dir=`expr $dir + 1`
echo bval_${dir} equals ${bvalue}
echo $bvalue >> ${bvalout}
fi
done
echo b0: ${b0} >> $binfo 
echo dirs: ${dir} >> $binfo
echo totalnum: ${num} >> $binfo
echo ~b0: ${b0}~
echo ~dirs: ${dir}~
echo ~totalnum: ${num}~
rm -f stats*.txt

echo ~~~Make zeros for bvec file~~~
rm -f tmp.txt
for i in `cat ${bvalout}`;
do
if [ $i == 0 ]
then
echo 0 0 0 >> tmp.txt
fi
done

echo ~~~Make gradient directions text file~~~
rm -f grad_dir_${num}.txt
sed 1d ${my_script}/tensor/tensor_${dir}.dat > grad_dir_${num}.txt
cat tmp.txt grad_dir_${num}.txt >> tmp_${num}.txt

echo ~~~Transpose grad_dir into bvecs file~~~~
awk '{
for (f = 1; f <= NF; f++) { a[NR, f] = $f }
}
NF > nf { nf = NF }
END {
for (f = 1; f <= nf; f++) {
for (r = 1; r <= NR; r++) {
printf a[r, f] (r==NR ? RS : FS)
}
}
}' tmp_${num}.txt > $bvecout
rm -f tmp*.txt
rm -f sample.nii

#mkdir tensor
#to split the original tensor.dat
#for i in `cat num.txt`;
#do 
#cat tensor.dat |grep -A $i ^$i$ > tensor/tensor_${i}.dat
#done

fi
