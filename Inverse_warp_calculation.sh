# Dan Destiche
# Edits Do Tromp
# January 16, 2014/April 29 2014
# Calculating inverse warps from population space to native space for Twin data

dir=/Volumes/Vol5/processed_DTI/VVCeA/TEMPLATE/normalize
intra=$dir/Intratwin_Averages
inverse=$dir/Inverse_Warps
mkdir -p -v ${inverse}

cd $dir

for i in BG88/ BH14/ BH19/ BH30/ BH44/ BH60/ BH63/ BH65/ BH79/ r11024/;
#for i in `ls -d 801-802/`
do
cd $i
twin=`echo $i | awk 'BEGIN{FS="/"}{print $1}'`;

	echo Calculating inverse warp of population space to twin space for $twin
	affine3Dtool -in $intra/${twin}_combined_mean.aff -invert -out $intra/${twin}_combined_mean_inv.aff;
	dfToInverse -in $intra/${twin}_combined_mean_aff_diffeo.df.nii.gz;
	dfLeftComposeAffine -df $intra/${twin}_combined_mean_aff_diffeo.df_inv.nii.gz -aff $intra/${twin}_combined_mean_inv.aff -out $intra/${twin}_combined_mean_combined.df_inv.nii.gz;	

for j in `ls *final_spd.nii.gz`
do
	subj=`echo $j | awk 'BEGIN{FS="_dti"}{print $1}'`;
	prefix=`echo $j | awk 'BEGIN{FS=".nii.gz"}{print $1}'`;
	
	echo Calculating inverse warp of twin space to native space for $subj
	affine3Dtool -in ${prefix}.aff -invert -out ${prefix}_inv.aff;
	dfToInverse -in ${prefix}_aff_diffeo.df.nii.gz;
	dfLeftComposeAffine -df ${prefix}_aff_diffeo.df_inv.nii.gz -aff ${prefix}_inv.aff -out ${prefix}_combined.df_inv.nii.gz;
	
	echo Combining two inverse warps for $subj
	dfComposition -df1 ${prefix}_combined.df_inv.nii.gz -df2 $intra/${twin}_combined_mean_combined.df_inv.nii.gz -out $inverse/${subj}_combined_long.df_inv.nii.gz

done

cd ${dir}
done

