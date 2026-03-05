#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 4
#SBATCH -a 1-44
#SBATCH -p cclake
#SBATCH -t 4:00:00
#SBATCH --mem 32G
#SBATCH -o preprocess_functional_logs/preprocess_functional_%A_%a.out



set -euo pipefail

if [ ! -d "preprocess_functional_logs" ]; then
    mkdir "preprocess_functional_logs"
fi

module load fsl/6.0.7
module load spm/spm12


# Runs all preprocessing of functional data, in parallel.
# IMPORTANT: Need to have run MP2RAGE_prepare.sh, template_normalise.sh, and MP2RAGE_normalise.sh
# 
# Run MP2RAGE_prepare.sh, then create template, then template_normalise.sh, then MP2RAGE_normalise.sh, then this script.
#
# Preprocessing steps:
#   Centre & align (use centre transformation from MP2RAGE_prepare)
#   Correct for susceptibility induced distortion (topup)
#   Realign all EPIs to SBref
#   Coregister with subject anatomical
#   Normalise to MNI (using transformations from MP2RAGE_normalise.sh and template_normalise.sh)
#   
#------------------------------------------------------------------------------------------------#



# Specify BIDS root directory here
BIDS_root=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS

# Specify centre_images script directory
centre_dir=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/centre_images

# Get subject ID for this job (e.g. "sub-01")
sub_id=$(printf "sub-%02d" $SLURM_ARRAY_TASK_ID)

# Specify file names here
run1_fname="${BIDS_root}/${sub_id}/func/${sub_id}_task-facehouse_acq-1_dir-PA_bold"
run2_fname="${BIDS_root}/${sub_id}/func/${sub_id}_task-facehouse_acq-2_dir-PA_bold"
uni_fname="${BIDS_root}/${sub_id}/anat/${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred"
invPE_fname="${BIDS_root}/${sub_id}/func/${sub_id}_acq-LC_dir-AP_bold"
SBref_fname="${BIDS_root}/${sub_id}/func/${sub_id}_task-facehouse_acq-1_dir-PA_sbref"

# Transformations
idx=$(( SLURM_ARRAY_TASK_ID-1 )) # deals with the weird index at the end of the transformation files (i.e. sub-01 -> 0, sub-02 -> 1, sub-44 -> 43)
MP2RAGE_to_template_affine="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}0GenericAffine.mat"
MP2RAGE_to_template_SyN="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}1Warp.nii.gz"
template_to_1mm_MNI_affine="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/study_template/CBBU_template_5iter-to-1mmMNI0GenericAffine.mat"
template_to_1mm_MNI_SyN="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/study_template/CBBU_template_5iter-to-1mmMNI1Warp.nii.gz"
centre_transform_mat="${BIDS_root}/${sub_id}/anat/${sub_id}_affine-transform-to-centre.mat"

# Check for missing files before running anything
for f in \
    "${run1_fname}.nii.gz" \
    "${run2_fname}.nii.gz" \
    "${invPE_fname}.nii.gz" \
    "${uni_fname}.nii.gz" \
    "${uni_fname}_WMmask.nii.gz" \
    "${SBref_fname}.nii.gz" \
    "${MP2RAGE_to_template_affine}" \
    "${MP2RAGE_to_template_SyN}" \
    "${template_to_1mm_MNI_affine}" \
    "${template_to_1mm_MNI_SyN}" \
    "${centre_transform_mat}"; do
    [ -f "$f" ] || { echo "ERROR: Missing file $f"; exit 1; }
done


# #------------------------------------------------------------------------------------------------#
# # Centre images
# echo "----------CENTRING IMAGES----------"

# matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${run1_fname}.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 
# matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${run2_fname}.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 
# matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${invPE_fname}.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 
# matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${SBref_fname}.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 

# #------------------------------------------------------------------------------------------------#
# # Correct for susceptibility induced distortions
# echo "----------SUSCEPTIBILITY DISTORTION CORRECTION----------"

# # extract last 5 vols of run 2 (PA)
# PA_5vols_fname="${BIDS_root}/${sub_id}/func/facehouse_PA_5vols"
# fslroi "${run2_fname}_centred.nii.gz" "${PA_5vols_fname}.nii.gz" $(( $(fslnvols "${run2_fname}.nii.gz") - 5 )) 5

# # get 5 vols of invPE (AP)
# AP_5vols_fname="${BIDS_root}/${sub_id}/func/facehouse_AP_5vols"
# fslroi "${invPE_fname}_centred.nii.gz" "${AP_5vols_fname}.nii.gz" 0 5

# # create merged files (15/08 - put PA first as fieldmap is aligned with first image - see topup docs)
# PA_AP_fname="${BIDS_root}/${sub_id}/func/facehouse_PA_AP"
# fslmerge -t "${PA_AP_fname}.nii.gz" "${PA_5vols_fname}.nii.gz" "${AP_5vols_fname}.nii.gz"

# # use topup to estimate distortion
# topup --imain="${PA_AP_fname}.nii.gz" \
#     --datain="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/topup_acquisition_params.txt" \
#     --config="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/topup_b0_sk.cnf" \
#     --out="${BIDS_root}/${sub_id}/func/${sub_id}_topup_facehouse_results" \
#     --iout="${PA_AP_fname}_unwarped.nii.gz" \
#     --fout="${BIDS_root}/${sub_id}/func/${sub_id}_topup_facehouse_field_Hz.nii.gz" \
#     --nthr=$SLURM_CPUS_PER_TASK \
#     --verbose

# # use topup to apply correction (to both runs and SBref)
# applytopup --imain="${run1_fname}_centred.nii.gz" \
#     --topup="${BIDS_root}/${sub_id}/func/${sub_id}_topup_facehouse_results" \
#     --datain="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/topup_acquisition_params.txt" \
#     --inindex=1 \
#     --out="${run1_fname}_centred_unwarped.nii.gz" \
#     --method=jac
# applytopup --imain="${run2_fname}_centred.nii.gz" \
#     --topup="${BIDS_root}/${sub_id}/func/${sub_id}_topup_facehouse_results" \
#     --datain="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/topup_acquisition_params.txt" \
#     --inindex=1 \
#     --out="${run2_fname}_centred_unwarped.nii.gz" \
#     --method=jac
# applytopup --imain="${SBref_fname}_centred.nii.gz" \
#     --topup="${BIDS_root}/${sub_id}/func/${sub_id}_topup_facehouse_results" \
#     --datain="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/topup_acquisition_params.txt" \
#     --inindex=1 \
#     --out="${SBref_fname}_centred_unwarped.nii.gz" \
#     --method=jac


# #------------------------------------------------------------------------------------------------#
# # Realign
# echo "----------REALIGNMENT----------"

# # use SBref as reference

# # Realign both runs (coregister to reference volume)
# mcflirt -in "${run1_fname}_centred_unwarped.nii.gz"\
#     -out "${run1_fname}_centred_unwarped_realigned"\
#     -reffile "${SBref_fname}_centred_unwarped.nii.gz"\
#     -plots
# mcflirt -in "${run2_fname}_centred_unwarped.nii.gz"\
#     -out "${run2_fname}_centred_unwarped_realigned"\
#     -reffile "${SBref_fname}_centred_unwarped.nii.gz"\
#     -plots


# #------------------------------------------------------------------------------------------------#
# # Estimate registration of EPI to anatomical
# echo "----------REGISTERING EPI TO ANATOMICAL----------"

# # I've added bounds on the rotations after a few problem alignments (24/02/26)

# # Register SBref to MP2RAGE
# flirt -in "${SBref_fname}_centred_unwarped.nii.gz"\
#     -ref "${uni_fname}.nii.gz"\
#     -omat "${BIDS_root}/${sub_id}/func/${sub_id}_func_to_anatomical.mat"\
#     -out "${SBref_fname}_centred_unwarped_coregistered.nii.gz"\
#     -dof 6\
#     -cost bbr \
#     -searchrx -30 30 \
#     -searchry -30 30 \
#     -searchrz -30 30 \
#     -wmseg "${uni_fname}_WMmask.nii.gz"


# # convert FSL affine transformation matrix to ANTS format
# /home/tom29/c3d-1.1.0-Linux-x86_64/bin/c3d_affine_tool \
#     -ref "${uni_fname}.nii.gz" \
#     -src "${SBref_fname}_centred_unwarped.nii.gz" \
#     "${BIDS_root}/${sub_id}/func/${sub_id}_func_to_anatomical.mat" \
#     -fsl2ras \
#     -oitk "${BIDS_root}/${sub_id}/func/${sub_id}_func_to_anatomical_ANTS.mat"



#------------------------------------------------------------------------------------------------#
# Normalise to MNI
echo "----------REGISTERING EPI TO MNI----------"

# Check missing files
for f in \
  "${run1_fname}_centred_unwarped_realigned.nii.gz" \
  "${run2_fname}_centred_unwarped_realigned.nii.gz"; do
    fslnvols "$f" >/dev/null || { echo "ERROR: bad or corrupt file $f"; exit 1; }
done

# Apply all transformations in single step.
# Run 1
antsApplyTransforms \
    -d 3 \
    -e 3 \
    --float \
    -i "${run1_fname}_centred_unwarped_realigned.nii.gz" \
    -r "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz" \
    -t "${template_to_1mm_MNI_SyN}" \
    -t "${template_to_1mm_MNI_affine}" \
    -t "${MP2RAGE_to_template_SyN}" \
    -t "${MP2RAGE_to_template_affine}" \
    -t "${BIDS_root}/${sub_id}/func/${sub_id}_func_to_anatomical_ANTS.mat" \
    -o "${run1_fname}_centred_unwarped_realigned_normalised.nii.gz" \
    -n Linear

# Run 2
antsApplyTransforms \
    -d 3 \
    -e 3 \
    --float \
    -i "${run2_fname}_centred_unwarped_realigned.nii.gz" \
    -r "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz" \
    -t "${template_to_1mm_MNI_SyN}" \
    -t "${template_to_1mm_MNI_affine}" \
    -t "${MP2RAGE_to_template_SyN}" \
    -t "${MP2RAGE_to_template_affine}" \
    -t "${BIDS_root}/${sub_id}/func/${sub_id}_func_to_anatomical_ANTS.mat" \
    -o "${run2_fname}_centred_unwarped_realigned_normalised.nii.gz" \
    -n Linear
    

#------------------------------------------------------------------------------------------------#
# Smooth images
echo "----------SMOOTHING----------"
matlab -batch "try, smooth_images('${run1_fname}_centred_unwarped_realigned_normalised.nii.gz', '${run1_fname}_centred_unwarped_realigned_normalised_smoothed.nii.gz', [6,6,6]); catch ME; rethrow(ME); end ; quit" 
matlab -batch "try, smooth_images('${run2_fname}_centred_unwarped_realigned_normalised.nii.gz', '${run2_fname}_centred_unwarped_realigned_normalised_smoothed.nii.gz', [6,6,6]); catch ME; rethrow(ME); end ; quit" 