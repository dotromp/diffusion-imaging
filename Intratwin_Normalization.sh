#!/bin/sh

cd /Volumes/Vol5/processed_DTI/VVCeA/TEMPLATE/normalize/${1}

for i in `ls *.nii.gz`
do
echo $i >> spds.txt
done

echo Bootstrapping
TVMean -in spds.txt -out mean_initial.nii.gz
TVResample -in mean_initial.nii.gz -align center -size 256 128 256 -vsize 0.5 1.0 0.5
#resampling scheme of initial twin normalization #TVResample -in mean_initial.nii.gz -align center -size 128 128 64 -vsize 1.5 1.75 2.5

echo Rigid and Affine
dti_rigid_population mean_initial.nii.gz spds.txt EDS 3
dti_affine_population mean_rigid3.nii.gz spds.txt EDS 3

echo Mask
TVtool -in mean_affine3.nii.gz -tr
BinaryThresholdImageFilter mean_affine3_tr.nii.gz mask.nii.gz 0.01 100 1 0

echo Diffeomorphic
dti_diffeomorphic_population mean_affine3.nii.gz spds_aff.txt mask.nii.gz 0.002


