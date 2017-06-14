#!/bin/bash
# 2016
# Dan Grupe & Do Tromp
# Extract FA (or other scalar values) from subregions of the cingulum tract (could be modified for other regions)
#make sure structures are located in ${basedir}/STRUCTURES/

if [ $# -lt 3 ]
then
	echo
	echo ERROR, not enough input variables
	echo
	echo Create weighted mean for multiple subjects, for multiple structures, for multiple scalars;
	echo Usage:
	echo sh weighted_mean.sh {process_dir} {structures_text_file} {scalars_text_file} {scalar_dir} {subjects}
	echo eg:
	echo
	echo weighted_mean.sh /Volumes/Vol5/processed_DTI/NOMOM structures_all.txt scalars_all.txt /Volumes/etc r15022 r16002 
	echo
else
	baseDir=$1
	echo "Output directory "$baseDir
	structures=`cat $2`
	echo "Structures to be run "$structures
	scalars=`cat $3`
	echo "Scalars to be run "$scalars
	scalar_dir=$4
	echo "Directory with scalars "$scalar_dir
	cd ${baseDir}
	mkdir -p -v ${baseDir}/weighted_scalars
	finalLoc=${baseDir}/weighted_scalars
	
	shift 4 
	subject=$*
	echo
	echo ~~~Create Weighted Mean~~~;
	for sub in ${subject};
	do
		cd ${baseDir};
		for region in ${structures};
		do
			img=${baseDir}/STRUCTURES/${region};
			final_img=${finalLoc}/${region}_weighted;
			for scalar in ${scalars};
			do
				if [ ! -f ${final_img}_${sub}_${scalar}.nii.gz ];
				then
					scalar_image=${scalar_dir}/*${sub}_*_${scalar}.nii*
					#~~Calculate voxelwise weighting factor (number of tracks passing through voxel)/(total number of tracks passing through all voxels)~~
					#~~First calculate total number of tracks - roundabout method because there is no 'sum' feature in fslstats~~
					echo
					echo ~Subject: ${sub}, Region: ${region}, Scalar: ${scalar}~
					totalVolume=`fslstats ${img} -V | awk '{ print $1 }'`;
					echo avgDensity=`fslstats ${img} -M`;
					avgDensity=`fslstats ${img} -M`;
					echo totalTracksFloat=`echo "$totalVolume * $avgDensity" | bc`;
					totalTracksFloat=`echo "$totalVolume * $avgDensity" | bc`;
					echo totalTracks=${totalTracksFloat/.*};
					totalTracks=${totalTracksFloat/.*};
					#~~Then divide number of tracks passing through each voxel by total number of tracks to get voxelwise weighting factor~~
					echo fslmaths ${img} -div ${totalTracks} ${final_img};
					fslmaths ${img} -div ${totalTracks} ${final_img};
					#~~Multiply weighting factor by scalar of each voxel to get the weighted scalar value of each voxel~~
					echo fslmaths ${final_img} -mul ${scalar_image} -mul 10000 ${final_img}_${sub}_${scalar};
					fslmaths ${final_img} -mul ${scalar_image} -mul 10000 ${final_img}_${sub}_${scalar};
				else
					echo "${region} already completed for subject ${sub}";
				fi;
				#~~Sum together these weighted scalar values for each voxel in the region~~
				#~~Again, roundabout method because no 'sum' feature~~
				echo totalVolume=`fslstats ${img} -V | awk '{ print $1 }'`;
				totalVolume=`fslstats ${img} -V | awk '{ print $1 }'`;
				echo avgWeightedScalar=`fslstats ${final_img}_${sub}_${scalar} -M`;
				avgWeightedScalar=`fslstats ${final_img}_${sub}_${scalar} -M`;
				value=`echo "${totalVolume} * ${avgWeightedScalar}"|bc`;
				echo ${sub}, ${region}, ${scalar}, ${value} >> ${final_img}_output.txt;
				echo ${sub}, ${region}, ${scalar}, ${value};
				#~~ Remember to divide final output by 10000 ~~
				#~~ and MD/tr also by 3 ~~
			done;
		done;
	done;
fi
