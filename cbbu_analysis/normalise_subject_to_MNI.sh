#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 4
#SBATCH -a 1-44
#SBATCH -p cclake
#SBATCH -t 2:00:00
#SBATCH --mem 32G
#SBATCH -o normalise_subject_to_MNI_logs/normalise_subject_to_MNI_%A_%a.out


# script to normalise statistical maps to MNI space


set -euo pipefail

if [ ! -d "normalise_subject_to_MNI_logs" ]; then
    mkdir "normalise_subject_to_MNI_logs"
fi


# Transformations
idx=$(( SLURM_ARRAY_TASK_ID-1 )) # deals with the weird index at the end of the transformation files (i.e. sub-01 -> 0, sub-02 -> 1, sub-44 -> 43)
MP2RAGE_to_template_affine="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}0GenericAffine.mat"
MP2RAGE_to_template_SyN="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}1Warp.nii.gz"
template_to_1mm_MNI_affine="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/CBBU_template_5iter-to-1mmMNI0GenericAffine.mat"
template_to_1mm_MNI_SyN="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/CBBU_template_5iter-to-1mmMNI1Warp.nii.gz"
functional_to_anatomical_affine="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS/${sub_id}/func/${sub_id}_func_to_anatomical_ANTS.mat"

# List of input images to normalise
input_images=(
    "${BIDS_root}/${sub_id}/GLM/No_parametric_modulators/beta_001.nii"
    "${BIDS_root}/${sub_id}/GLM/No_parametric_modulators/beta_002.nii"
)


# Loop over input images and normalise each one
for input_image in "${input_images[@]}"; do

    if [ ! -f "$input_image" ]; then
        echo "Missing input image ${input_image} for ${sub_id} — skipping"
        continue
    fi

    echo "Normalising ${input_image} for ${sub_id}"

    # Apply all transformations in single step.
    antsApplyTransforms \
        -d 3 \
        -e 0 \
        --float \
        -i "$input_image" \
        -r "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz" \
        -t "${template_to_1mm_MNI_SyN}" \
        -t "${template_to_1mm_MNI_affine}" \
        -t "${MP2RAGE_to_template_SyN}" \
        -t "${MP2RAGE_to_template_affine}" \
        -t "${functional_to_anatomical_affine}" \
        -o "${input_image%.nii}_normalised.nii.gz" \
        -n Linear

    echo "Finished normalising ${input_image} for ${sub_id}"

done
