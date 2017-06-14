dir=/scratch/Twin_normalization
std=$dir/Intratwin_Averages/Intratwin_in_pop_space
cd $dir

for i in `ls -d 8??-8??`
do
cd $i

for j in `ls *aff_diffeo.df.nii.gz`
do
subj=`echo $j | awk 'BEGIN{FS="_"}{print $1}'`
prefix=`echo $j | awk 'BEGIN{FS="_aff"}{print $1}'`

echo $subj
#dfComposition -df1 $std/*${subj}*_combined_mean_combined.df.nii.gz -df2 ${prefix}_combined.df.nii.gz -out ${subj}_combined_long.df.nii.gz
deformationSymTensor3DVolume -in ${prefix}.nii.gz -trans ${subj}_combined_long.df.nii.gz -target $std/Pop_combined_mean.nii.gz -out $dir/TBSS/1x1x1_tensor/${subj}_spd_combined_pop_space.nii.gz -vsize 1.0 1.0 1.0

done

cd ..
done
