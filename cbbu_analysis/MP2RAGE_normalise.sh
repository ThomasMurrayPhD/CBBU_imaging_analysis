#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 4
#SBATCH -a 1-44
#SBATCH -p cclake
#SBATCH -t 01:30:00
#SBATCH --mem 32G
#SBATCH -o MP2RAGE_normalise_logs/1mm_MP2RAGE_normalise_%A_%a.out



# Normalises MP2RAGE to MNI space via the study template in parallel
# IMPORTANT: Need to have run MP2RAGE_prepare.sh and template_normalise.sh
# 
# 
# Run MP2RAGE_prepare.sh, then create template, then template_normalise.sh, then this script.
#
#   
#------------------------------------------------------------------------------------------------#


set -euo pipefail

if [ ! -d "MP2RAGE_normalise_logs" ]; then
    mkdir "MP2RAGE_normalise_logs"
fi

module load fsl/6.0.7


# Specify BIDS root directory here
BIDS_root="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS"

# Get subject ID for this job (e.g. "sub-01")
sub_id=$(printf "sub-%02d" $SLURM_ARRAY_TASK_ID)

# Specify UNI file name
uni_fname="${BIDS_root}/${sub_id}/anat/${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred"

# Specify target MNI name
MNI_05mm_fname="${FSLDIR}/data/standard/MNI152_T1_0.5mm.nii.gz"
MNI_1mm_fname="${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz"

# Specify subject's MP2RAGE-to-template transformation (already done when creating the template)
idx=$(( SLURM_ARRAY_TASK_ID-1 )) # deals with the weird index at the end of the transformation files (i.e. sub-01 -> 0, sub-02 -> 1, sub-44 -> 43)
MP2RAGE_to_template_affine="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}0GenericAffine.mat"
MP2RAGE_to_template_SyN="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}1Warp.nii.gz"

# Specify template-to-MNI transformation (0.5mm)
template_to_05mm_MNI_affine="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/study_template/CBBU_template_5iter-to-05mmMNI0GenericAffine.mat"
template_to_05mm_MNI_SyN="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/study_template/CBBU_template_5iter-to-05mmMNI1Warp.nii.gz"

# Specify template-to-MNI transformation (1mm)
template_to_1mm_MNI_affine="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/CBBU_template_5iter-to-1mmMNI0GenericAffine.mat"
template_to_1mm_MNI_SyN="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/CBBU_template_5iter-to-1mmMNI1Warp.nii.gz"

# Concatenate and apply MP2RAGE-to-template and template-to-MNI transformations (0.5mm)
# antsApplyTransforms \
#     -d 3 \
#     -e 0 \
#     -i "${uni_fname}.nii.gz" \
#     -r "${MNI_05mm_fname}" \
#     -t "${template_to_05mm_MNI_SyN}" \
#     -t "${template_to_05mm_MNI_affine}" \
#     -t "${MP2RAGE_to_template_SyN}" \
#     -t "${MP2RAGE_to_template_affine}" \
#     -o "${uni_fname}_05mm_normalised.nii.gz" \
#     -n Linear

# Concatenate and apply MP2RAGE-to-template and template-to-MNI transformations (1mm)
antsApplyTransforms \
    -d 3 \
    -e 0 \
    -i "${uni_fname}.nii.gz" \
    -r "${MNI_1mm_fname}" \
    -t "${template_to_1mm_MNI_SyN}" \
    -t "${template_to_1mm_MNI_affine}" \
    -t "${MP2RAGE_to_template_SyN}" \
    -t "${MP2RAGE_to_template_affine}" \
    -o "${uni_fname}_1mm_normalised.nii.gz" \
    -n Linear