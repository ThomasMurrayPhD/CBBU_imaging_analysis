#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 4
#SBATCH -a 37
#SBATCH -p cclake
#SBATCH -t 2:00:00
#SBATCH --mem 32G
#SBATCH -o MT_normalise_logs/MT_normalise_%A_%a.out


# Normalises MT images to MNI space via the subject's MP2RAGE and study template in parallel
# IMPORTANT: Need to have run MP2RAGE_prepare.sh, created template, and template_normalise.sh
# 
# 
# Run MP2RAGE_prepare.sh, then create template, then template_normalise.sh, then this script.
#
#   
#------------------------------------------------------------------------------------------------#


set -euo pipefail

if [ ! -d "MT_normalise_logs" ]; then
    mkdir "MT_normalise_logs"
fi

module load spm/spm12
module load fsl/6.0.7




# Specify BIDS root directory here
BIDS_root="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS"

# Specify centre_images directory
centre_dir=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/centre_images/

# Get subject ID for this job (e.g. "sub-01")
sub_id=$(printf "sub-%02d" $SLURM_ARRAY_TASK_ID)

# Specify UNI file name
uni_fname="${BIDS_root}/${sub_id}/anat/${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred"

# Specify MT file names
MTon_fname="${BIDS_root}/${sub_id}/anat/${sub_id}_acq-LC_mt-on_MTS"
MToff_fname="${BIDS_root}/${sub_id}/anat/${sub_id}_acq-LC_mt-off_MTS"

# Specify target MNI name
MNI_fname="${FSLDIR}/data/standard/MNI152_T1_0.5mm.nii.gz"

# Specify subject's MP2RAGE-to-template transformation (already done when creating the template)
idx=$(( SLURM_ARRAY_TASK_ID-1 )) # deals with the weird index at the end of the transformation files (i.e. sub-01 -> 0, sub-02 -> 1, sub-44 -> 43)
MP2RAGE_to_template_affine="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}0GenericAffine.mat"
MP2RAGE_to_template_SyN="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}1Warp.nii.gz"

# Specify template-to-MNI transformation
template_to_MNI_affine="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/study_template/CBBU_template_5iter-to-MNI0GenericAffine.mat"
template_to_MNI_SyN="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/study_template/CBBU_template_5iter-to-MNI1Warp.nii.gz"

# Specify subject's centreing transformation (from MP2RAGE_prepare.sh)
centre_transform_mat="${BIDS_root}/${sub_id}/anat/${sub_id}_affine-transform-to-centre.mat"



#------------------------------------------------------------------------------------------------#
# N4 Bias Correction
echo "N4 bias corrrection"

N4BiasFieldCorrection \
    -d 3 \
    -i "${MToff_fname}.nii.gz" \
    -o "${MToff_fname}_N4.nii.gz" \
    -r 1 \
    -c [50x50x30x20,1e-6] \
    -b [200]

N4BiasFieldCorrection \
    -d 3 \
    -i "${MTon_fname}.nii.gz" \
    -o "${MTon_fname}_N4.nii.gz" \
    -r 1 \
    -c [50x50x30x20,1e-6] \
    -b [200]


#------------------------------------------------------------------------------------------------#
# Centre images using MP2RAGE transformation
echo "Centring images"
matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${MTon_fname}_N4.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 
matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${MToff_fname}_N4.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 


#------------------------------------------------------------------------------------------------#
# Register MTon to MToff
echo "Registering MT-on to MT-off"

antsRegistration \
    --verbose 1 \
    --dimensionality 3 \
    --float 1 \
    --random-seed 1234 \
    --output [ "${BIDS_root}/${sub_id}/anat/${sub_id}_MTon-to-MToff"] \
    --interpolation Linear \
    --use-histogram-matching 0  \
    --winsorize-image-intensities [ 0.005,0.995 ] \
    --transform Rigid[ 0.1 ] \
    --metric MI[ "${MToff_fname}_N4_centred.nii.gz","${MTon_fname}_N4_centred.nii.gz",1,32,Regular,0.25 ] \
    --convergence [ 1000x500x250x100,1e-6,10 ] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox

#    --initial-moving-transform [ "${MToff_fname}_N4_centred.nii.gz","${MTon_fname}_N4_centred.nii.gz",2 ] \
# --output [ "${BIDS_root}/${sub_id}/anat/${sub_id}_MTon-to-MToff","${BIDS_root}/${sub_id}/anat/${sub_id}_MTon-to-MToff_Rigid.nii.gz","${BIDS_root}/${sub_id}/anat/${sub_id}_MTon-to-MToff_InverseRigid.nii.gz" ] \

#------------------------------------------------------------------------------------------------#
# Register MT off to MP2RAGE
echo "Registering MT-off to MP2RAGE"

antsRegistration \
    --verbose 1 \
    --dimensionality 3 \
    --float 1 \
    --random-seed 1234 \
    --output [ "${BIDS_root}/${sub_id}/anat/${sub_id}_MToff-to-UNI" ]\
    --interpolation Linear \
    --winsorize-image-intensities [ 0.005,0.995 ] \
    --use-histogram-matching 0  \
    --masks [ "${BIDS_root}/${sub_id}/anat/${sub_id}_mask_centred.nii.gz", NULL ] \
    --transform Rigid[0.1] \
    --metric MI[ "${uni_fname}.nii.gz","${MToff_fname}_N4_centred.nii.gz",1,32,Regular,0.25 ] \
    --convergence [ 1000x500x250x100,1e-6,10 ] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox 

#    --initial-moving-transform [ "${uni_fname}.nii.gz","${MToff_fname}_N4_centred.nii.gz",2 ] \
#    --output [ "${BIDS_root}/${sub_id}/anat/${sub_id}_MToff-to-UNI","${BIDS_root}/${sub_id}/anat/${sub_id}_MToff-to-UNI_Rigid.nii.gz","${BIDS_root}/${sub_id}/anat/${sub_id}_MToff-to-UNI_InverseRigid.nii.gz" ]\


#------------------------------------------------------------------------------------------------#
# Apply transformations in single step (both MT on and MT off)
echo "Transforming MT-off to MNI"

# MT off
antsApplyTransforms \
    -d 3 \
    -e 0 \
    -i "${MToff_fname}_N4_centred.nii.gz" \
    -r "${MNI_fname}" \
    -t "${template_to_MNI_SyN}" \
    -t "${template_to_MNI_affine}" \
    -t "${MP2RAGE_to_template_SyN}" \
    -t "${MP2RAGE_to_template_affine}" \
    -t "${BIDS_root}/${sub_id}/anat/${sub_id}_MToff-to-UNI0GenericAffine.mat" \
    -o "${MToff_fname}_N4_centred_normalised.nii.gz" \
    -n Linear


echo "Transforming MT-on to MNI"

# MT on (inc. MTon to MT off)
antsApplyTransforms \
    -d 3 \
    -e 0 \
    -i "${MTon_fname}_N4_centred.nii.gz" \
    -r "${MNI_fname}" \
    -t "${template_to_MNI_SyN}" \
    -t "${template_to_MNI_affine}" \
    -t "${MP2RAGE_to_template_SyN}" \
    -t "${MP2RAGE_to_template_affine}" \
    -t "${BIDS_root}/${sub_id}/anat/${sub_id}_MToff-to-UNI0GenericAffine.mat" \
    -t "${BIDS_root}/${sub_id}/anat/${sub_id}_MTon-to-MToff0GenericAffine.mat" \
    -o "${MTon_fname}_N4_centred_normalised.nii.gz" \
    -n Linear