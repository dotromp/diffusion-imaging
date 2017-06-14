dir=/Volumes/Vol5/processed_DTI/VVCeA/TEMPLATE/normalize
std=$dir/Intratwin_Averages/Intratwin_in_pop_space
mkdir -p -v $dir/Native_in_pop_space
cd $dir

for i in BG88/ BH14/ BH19/ BH30/ BH44/ BH60/ BH63/ BH65/ BH79/ r11024/;
do
cd $i

for j in `ls *aff_diffeo.df.nii.gz`
do
sub=`echo $i | awk 'BEGIN{FS="/"}{print $1}'`
subj=`echo $j | awk 'BEGIN{FS="_dti"}{print $1}'`
prefix=`echo $j | awk 'BEGIN{FS="_aff"}{print $1}'`

echo $subj
dfComposition -df1 $std/${sub}_combined_mean_combined.df.nii.gz -df2 ${prefix}_combined.df.nii.gz -out ${subj}_combined_long.df.nii.gz
deformationSymTensor3DVolume -in ${prefix}.nii.gz -trans ${subj}_combined_long.df.nii.gz -target $std/Pop_combined_mean.nii.gz -out $dir/Native_in_pop_space/${subj}_spd_combined_pop_space.nii.gz

done

cd ${dir}
done
