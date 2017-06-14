dir=/Volumes/Vol5/processed_DTI/VVCeA/TEMPLATE/normalize/Intratwin_Averages
std=${dir}/Intratwin_in_pop_space
mkdir -p -v ${dir}/Intratwin_in_pop_space
cd $dir

for j in `ls *aff_diffeo.df.nii.gz`
do 
prefix=`echo $j|awk 'BEGIN{FS="_aff"}{print $1}'`

echo Combining affine and diffeomorphic deformation fields for $prefix and applying combined deformation field to $prefix to warp to template space
dfRightComposeAffine -aff ${prefix}.aff -df $j -out $std/${prefix}_combined.df.nii.gz
deformationSymTensor3DVolume -in ${prefix}.nii.gz -trans $std/${prefix}_combined.df.nii.gz -target mean_diffeomorphic_initial6.nii.gz -out $std/${prefix}_combined.nii.gz
done

cd $std
rm combined.txt -f

for i in `ls *combined.nii.gz`
do
echo "$i" >> combined.txt
done

TVMean -in combined.txt -out Pop_combined_mean.nii.gz
TVtool -in Pop_combined_mean.nii.gz -fa

