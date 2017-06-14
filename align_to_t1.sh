dti=$1
t1=$2 
dtiToT1Trans=$3

TVtool -in $dti -tr -out my_tr.nii.gz 
BinaryThresholdImageFilter my_tr.nii.gz my_mask.nii.gz 0.7 100 1 0
TVtool -in $dti -mask my_mask.nii.gz -out my_strip.nii.gz
#TVtool -in my_strip.nii.gz -fa -out my_strip_fa.nii.gz 
TVtool -in my_strip.nii.gz -tr -out my_strip_tr.nii.gz 
asvDSM -template $t1 -subject my_strip_tr.nii.gz -outTrans $dtiToT1Trans -sep 0.5 0.5 0.5 -ftol 0.0001
TVtool -in $dti -fa
prefix=`echo $dti | awk 'BEGIN{FS=".nii"}{print $1}'`
affineScalarVolume -in ${prefix}_fa.nii.gz -trans $dtiToT1Trans -target $t1 -out ${prefix}_inT1_fa.nii.gz

rm -f my_tr.nii.gz
rm -f my_mask.nii.gz
rm -f my_strip.nii.gz
#rm -f my_strip_fa.nii.gz
