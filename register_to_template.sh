#!/bin/bash
# July, 2012
# October 8, 2009. 12:10 AM.
# Nagesh Adluru & Do Tromp
# Spatial normalization using DTI-TK.


if [ $# -lt 2 ]
then
        echo "Usage: `basename $0` template input_spd.nii.gz"
        exit 1
fi

template=$1
subject=$2
prefix_template=`echo $template | awk 'BEGIN{FS=".nii"}{print $1}'`
prefix_input=`echo $subject | awk 'BEGIN{FS=".nii"}{print $1}'`
TVtool -in $template -tr
template_tr=${prefix_template}_tr.nii.gz

rm -f affine.txt
rm -f average_inv.aff
rm -f *.aff

smoption=EDS
xsep=2
ysep=2
zsep=2
ftol=0.01
out=${prefix_input}_aff.nii.gz
trans=${prefix_input}.aff

echo ~~~Rigid registration of the subject to the template~~~
#dti_rigid_reg $template $subject EDS 2 2 2 0.001
rtvCGM -SMOption $smoption -template $template -subject $subject -sep $xsep $ysep $zsep -ftol $ftol -outTrans $trans
affineSymTensor3DVolume -in $subject -target $template -out $out -trans $trans -interp LEI

echo ~~~Affine registration of the subject to the template~~~
#dti_affine_reg $template $subject EDS 2 2 2 0.001 1
atvCGM -SMOption $smoption -template $template -subject $subject -sep $xsep $ysep $zsep -ftol $ftol -outTrans $trans -inTrans $trans
affineSymTensor3DVolume -in $subject -target $template -out $out -trans $trans -interp LEI


#echo Adjusting for the global shape variation by averaging affine transforms.
#affine3DShapeAverage affine.txt $template average_inv.aff 1
#for aff in `cat affine.txt`
#do
#	affine3Dtool -in $aff -compose average_inv.aff -out $aff
#	#affine3DCompose $aff average_inv.aff $aff
#        subj=`echo $aff | sed -e 's/.aff//'`
#        affineSymTensor3DVolume -in ${subj}.nii.gz -trans $aff -target $template -out ${subj}_aff.nii.gz
#done

#echo Getting the text file needed for diffeomorphic_sn
#for subj in `ls *spd_aff.nii.gz`
#do
#       echo $subj >> $subj_list_file"_aff".txt
#done

echo ~~~Diffeo registration of the subject to the template~~~
BinaryThresholdImageFilter $template_tr mask.nii.gz 0.01 100 1 0
dti_diffeomorphic_reg $template $out mask.nii.gz 1 6 0.002
