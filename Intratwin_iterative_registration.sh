dir=/Volumes/Vol5/processed_DTI/VVCeA/TEMPLATE/normalize/Intratwin_Averages
cd $dir

subj_list_file=spds
rm -f ${subj_list_file}.txt

for i in `ls *_combined_mean.nii.gz`
do
echo $i >> ${subj_list_file}.txt
done

echo Bootstrapping
TVMean -in ${subj_list_file}.txt -out mean_initial.nii.gz
#TVResample -in mean_initial.nii.gz -align center -size 128 128 64 -vsize 2.0 2.0 2.5

echo Rigid and Affine
dti_rigid_population mean_initial.nii.gz ${subj_list_file}.txt EDS 3
dti_affine_population mean_rigid3.nii.gz ${subj_list_file}.txt EDS 3

echo Mask
TVtool -in mean_affine3.nii.gz -tr
BinaryThresholdImageFilter mean_affine3_tr.nii.gz mask.nii.gz 0.01 100 1 0

echo Diffeomorphic
dti_diffeomorphic_population mean_affine3.nii.gz ${subj_list_file}_aff.txt mask.nii.gz 0.002


