dir=/scratch/Twin_normalization
cd $dir

for twin in `ls -d 8??-8??/`
do
echo $twin
cd $twin
twin_prefix=`echo $twin|awk 'BEGIN{FS="/"}{print $1}'`
rm combined.txt -f

for j in `ls *aff_diffeo.df.nii.gz`
do
prefix=`echo $j|awk 'BEGIN{FS="_aff"}{print $1}'`
subj_prefix=`echo $j|awk 'BEGIN{FS="_"}{print $1}'`
echo $prefix
dfRightComposeAffine -aff ${prefix}.aff -df $j -out ${prefix}_combined.df.nii.gz
deformationSymTensor3DVolume -in ${prefix}.nii.gz -trans ${prefix}_combined.df.nii.gz -target mean_diffeomorphic_initial6.nii.gz -out ${prefix}_combined.nii.gz
done
	for i in `ls *combined.nii.gz`
	do
	echo "$i" >> combined.txt
	done
TVMean -in combined.txt -out ${twin_prefix}_combined_mean.nii.gz
cp ${twin_prefix}_combined_mean.nii.gz ../Intratwin_Averages

cd ..
done
[tromp@fresno Twin_normalization]$ vi Native_to_template_space_1x1x1_MD_L1_L3.sh^C
[tromp@fresno Twin_normalization]$ cat Native_to_template_space_1x1x1_MD_L1_L3.sh
dir=/scratch/Twin_normalization
std=$dir/Intratwin_Averages/Intratwin_in_pop_space
cd $dir

for i in `ls -d 8??-8??`
do
cd $i

for j in `ls *final_spd.nii.gz`
do
subj=`echo $j | awk 'BEGIN{FS="_"}{print $1}'`
prefix=`echo $j | awk 'BEGIN{FS=".nii"}{print $1}'`

echo Calculating md, lambda1, and lambda3 for $subj
TVtool -in $j -tr 
fslmaths ${prefix}_tr.nii.gz  -div 3 $dir/Native_md/${prefix}_md.nii.gz
rm ${prefix}_tr.nii.gz
TVtool -in $j -eigs
mv ${prefix}_lambda1.nii.gz $dir/Native_lambda1
mv ${prefix}_lambda3.nii.gz $dir/Native_lambda3
rm ${prefix}_lambda2.nii.gz

for metric in md lambda1 lambda3
do
#dfComposition -df1 $std/*${subj}*_combined_mean_combined.df.nii.gz -df2 ${prefix}_combined.df.nii.gz -out ${subj}_combined_long.df.nii.gz
deformationScalarVolume -in $dir/Native_${metric}/${prefix}_${metric}.nii.gz -trans ${subj}_combined_long.df.nii.gz -target $std/Pop_combined_mean.nii.gz -out $dir/TBSS/1x1x1_${metric}/${subj}_combined_pop_space_${metric}.nii.gz -vsize 1.0 1.0 1.0
done
done

cd ..
done
