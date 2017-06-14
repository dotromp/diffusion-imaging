fa=$1
tr=$2
ad=$3
rd=$4

tensorFile=$5
orig=$6
Trans=$7
diffeoTrans=$8
dtiToT1Trans=$9
T1=${10}


smoption=EDS
lengthscale=0.5


##compose full warp and apply
#dfRightComposeAffine -aff $affineTrans -df $diffeoTrans -out combined.df.nii.gz

##combine full warp with affine to T1 and apply
dfLeftComposeAffine -df $diffeoTrans -aff $dtiToT1Trans -out $Trans
deformationSymTensor3DVolume -in $orig -trans $Trans -target $T1 -out $tensorFile


TVtool -in $tensorFile -fa -out $fa
TVtool -in $tensorFile -tr -out $tr
TVtool -in $tensorFile -ad -out $ad 
TVtool -in $tensorFile -rd -out $rd


#SVGaussianSmoothing -in $fa -fwhm  6 6 6
#SVGaussianSmoothing -in $tr -fwhm  6 6 6
#SVGaussianSmoothing -in $ad -fwhm  6 6 6
#SVGaussianSmoothing -in $rd -fwhm  6 6 6

fslchfiletype NIFTI_GZ $fa 
fslchfiletype NIFTI_GZ $tr 
fslchfiletype NIFTI_GZ $ad 
fslchfiletype NIFTI_GZ $rd 

#rm -f combined.df.nii.gz
rm -f $Trans

