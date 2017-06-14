dir=/Volumes/Vol5/processed_DTI/VVCeA/TEMPLATE/normalize
cd $dir
mkdir -p -v ${dir}/Intratwin_Averages

for twin in BG88/ BH14/ BH19/ BH30/ BH44/ BH60/ BH63/ BH65/ BH79/ r11024/
do
echo $twin
cd ${dir}/${twin}
twin_prefix=`echo $twin|awk 'BEGIN{FS="/"}{print $1}'`
rm combined.txt -f

for j in `ls *aff_diffeo.df.nii.gz`
do
prefix=`echo $j|awk 'BEGIN{FS="_aff"}{print $1}'`
subj_prefix=`echo $j|awk 'BEGIN{FS="_dti"}{print $1}'`
echo $prefix
dfRightComposeAffine -aff ${prefix}.aff -df $j -out ${prefix}_combined.df.nii.gz
deformationSymTensor3DVolume -in ${prefix}.nii.gz -trans ${prefix}_combined.df.nii.gz -target mean_diffeomorphic_initial6.nii.gz -out ${prefix}_combined.nii.gz
done
	for i in `ls *combined.nii.gz`
	do
	echo "$i" >> combined.txt
	done
TVMean -in combined.txt -out ${twin_prefix}_combined_mean.nii.gz
cp ${twin_prefix}_combined_mean.nii.gz ${dir}/Intratwin_Averages

cd ${dir}
done
