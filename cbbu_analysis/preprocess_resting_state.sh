#!/bin/bash
#SBATCH -D /home/tom29/rds/hpc-work/cbbu_analysis/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 6
#SBATCH -a 1-44
#SBATCH -p cclake
#SBATCH -t 6:00:00
#SBATCH --mem 16G
#SBATCH -o preprocess_resting_state_logs/preprocess_resting_state_%A_%a.out



set -euo pipefail

if [ ! -d "preprocess_resting_state_logs" ]; then
    mkdir "preprocess_resting_state_logs"
fi

module load fsl/6.0.7
module load spm/spm12


# Runs all preprocessing of resting_state data, in parallel.
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
BIDS_root=/home/tom29/rds/hpc-work/cbbu_BIDS

# Specify centre_images script directory
centre_dir=/home/tom29/rds/hpc-work/cbbu_analysis/centre_images

# Get subject ID for this job (e.g. "sub-01")
sub_id=$(printf "sub-%02d" $SLURM_ARRAY_TASK_ID)

# Specify file names here
rs_fname="${BIDS_root}/${sub_id}/func/${sub_id}_task-rest_dir-PA_bold"
uni_fname="${BIDS_root}/${sub_id}/anat/${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred"
invPE_fname="${BIDS_root}/${sub_id}/func/${sub_id}_task-rest_dir-AP_bold"
SBref_fname="${BIDS_root}/${sub_id}/func/${sub_id}_task-rest_dir-PA_sbref"

# Transformations
idx=$(( SLURM_ARRAY_TASK_ID-1 )) # deals with the weird index at the end of the transformation files (i.e. sub-01 -> 0, sub-02 -> 1, sub-44 -> 43)
MP2RAGE_to_template_affine="/home/tom29/rds/hpc-work/cbbu_analysis/study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}0GenericAffine.mat"
MP2RAGE_to_template_SyN="/home/tom29/rds/hpc-work/cbbu_analysis/study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}1Warp.nii.gz"
template_to_MNI_affine="/home/tom29/rds/hpc-work/cbbu_analysis/study_template/CBBU_template_5iter-to-MNI0GenericAffine.mat"
template_to_MNI_SyN="/home/tom29/rds/hpc-work/cbbu_analysis/study_template/CBBU_template_5iter-to-MNI1Warp.nii.gz"
centre_transform_mat="${BIDS_root}/${sub_id}/anat/${sub_id}_affine-transform-to-centre.mat"

# Check for missing files before running anything
for f in \
    "${rs_fname}.nii.gz" \
    "${invPE_fname}.nii.gz" \
    "${uni_fname}.nii.gz" \
    "${uni_fname}_WMmask.nii.gz" \
    "${SBref_fname}.nii.gz" \
    "${MP2RAGE_to_template_affine}" \
    "${MP2RAGE_to_template_SyN}" \
    "${template_to_MNI_affine}" \
    "${template_to_MNI_SyN}" \
    "${centre_transform_mat}"; do
    [ -f "$f" ] || { echo "ERROR: Missing file $f"; exit 1; }
done


#------------------------------------------------------------------------------------------------#
# Centre images
echo "----------CENTRING IMAGES----------"

matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${rs_fname}.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 
matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${invPE_fname}.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 
matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${SBref_fname}.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 

#------------------------------------------------------------------------------------------------#
# Correct for susceptibility induced distortions
echo "----------SUSCEPTIBILITY DISTORTION CORRECTION----------"

# extract last 5 vols (PA)
PA_5vols_fname="${BIDS_root}/${sub_id}/func/rest_PA_5vols"
fslroi "${rs_fname}_centred.nii.gz" "${PA_5vols_fname}.nii.gz" $(( $(fslnvols "${rs_fname}.nii.gz") - 5 )) 5

# get 5 vols of invPE (AP)
AP_5vols_fname="${BIDS_root}/${sub_id}/func/rest_AP_5vols"
fslroi "${invPE_fname}_centred.nii.gz" "${AP_5vols_fname}.nii.gz" 0 5

# create merged files (15/08 - put PA first as fieldmap is aligned with first image - see topup docs)
PA_AP_fname="${BIDS_root}/${sub_id}/func/rest_PA_AP"
fslmerge -t "${PA_AP_fname}.nii.gz" "${PA_5vols_fname}.nii.gz" "${AP_5vols_fname}.nii.gz"

# use topup to estimate distortion
topup --imain="${PA_AP_fname}.nii.gz" \
    --datain="/home/tom29/rds/hpc-work/cbbu_analysis/topup_acquisition_params.txt" \
    --config="/home/tom29/rds/hpc-work/cbbu_analysis/topup_b0_sk.cnf" \
    --out="${BIDS_root}/${sub_id}/func/${sub_id}_topup_rest_results" \
    --iout="${PA_AP_fname}_unwarped.nii.gz" \
    --fout="${BIDS_root}/${sub_id}/func/${sub_id}_topup_rest_field_Hz.nii.gz" \
    --nthr=$SLURM_CPUS_PER_TASK \
    --verbose

# use topup to apply correction to EPI sequence
applytopup --imain="${rs_fname}_centred.nii.gz" \
    --topup="${BIDS_root}/${sub_id}/func/${sub_id}_topup_rest_results" \
    --datain="/home/tom29/rds/hpc-work/cbbu_analysis/topup_acquisition_params.txt" \
    --inindex=1 \
    --out="${rs_fname}_centred_unwarped.nii.gz" \
    --method=jac

# use topup to apply correction to SB ref
applytopup --imain="${SBref_fname}_centred.nii.gz" \
    --topup="${BIDS_root}/${sub_id}/func/${sub_id}_topup_rest_results" \
    --datain="/home/tom29/rds/hpc-work/cbbu_analysis/topup_acquisition_params.txt" \
    --inindex=1 \
    --out="${SBref_fname}_centred_unwarped.nii.gz" \
    --method=jac


#------------------------------------------------------------------------------------------------#
# Realign
echo "----------REALIGNMENT----------"

# get reference volume (vol 1)
#ref_vol_fname="${BIDS_root}/${sub_id}/func/${sub_id}_rest-realignment-reference-vol.nii.gz"
#fslroi "${rs_fname}_centred_unwarped.nii.gz" "${ref_vol_fname}" 0 1

# Realign (coregister to reference volume)
mcflirt -in "${rs_fname}_centred_unwarped.nii.gz"\
    -out "${rs_fname}_centred_unwarped_realigned"\
    -reffile "${SBref_fname}_centred_unwarped.nii.gz"\
    -plots

#------------------------------------------------------------------------------------------------#
# Estimate registration of EPI to anatomical
echo "----------REGISTERING EPI TO ANATOMICAL----------"

#create mean EPI
#fslmaths "${rs_fname}_centred_unwarped_realigned.nii.gz" -Tmean "${rs_fname}_centred_unwarped_realigned_mean.nii.gz"

# Register SBref to MP2RAGE
flirt -in "${SBref_fname}_centred_unwarped.nii.gz"\
    -ref "${uni_fname}.nii.gz"\
    -omat "${BIDS_root}/${sub_id}/func/${sub_id}_rest_to_anatomical.mat"\
    -out "${SBref_fname}_centred_unwarped_coregistered.nii.gz"\
    -dof 6\
    -cost bbr \
    -wmseg "${uni_fname}_WMmask.nii.gz"

# convert FSL affine transformation matrix to ANTS format
/home/tom29/c3d-1.1.0-Linux-x86_64/bin/c3d_affine_tool \
    -ref "${uni_fname}.nii.gz" \
    -src "${SBref_fname}_centred_unwarped.nii.gz" \
    "${BIDS_root}/${sub_id}/func/${sub_id}_rest_to_anatomical.mat" \
    -fsl2ras \
    -oitk "${BIDS_root}/${sub_id}/func/${sub_id}_rest_to_anatomical_ANTS.mat"


#------------------------------------------------------------------------------------------------#
# Normalise to MNI

echo "----------REGISTERING EPI TO MNI----------"

# Apply all transformations in single step. This code (commented out) causes OOM errors.
antsApplyTransforms \
   -d 3 \
   -e 3 \
   --float \
   -i "${rs_fname}_centred_unwarped_realigned.nii.gz" \
   -r "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz" \
   -t "${template_to_MNI_SyN}" \
   -t "${template_to_MNI_affine}" \
   -t "${MP2RAGE_to_template_SyN}" \
   -t "${MP2RAGE_to_template_affine}" \
   -t "${BIDS_root}/${sub_id}/func/${sub_id}_rest_to_anatomical_ANTS.mat" \
   -o "${rs_fname}_centred_unwarped_realigned_normalised.nii.gz" \
   -n Linear


# Instead let's hack it to extract individual volumes, apply the transformations to each,
# save each volume, then concatenate back into 4D (and delete the individual vols)
# nvols=$(fslnvols "${rs_fname}_centred_unwarped_realigned.nii.gz")
# for v in $(seq 0 $((nvols-1))); do
#     echo "Processing volume $v"
#     tmp_vol="${rs_fname}_vol-${v}.nii.gz"
#     fslroi "${rs_fname}_centred_unwarped_realigned.nii.gz" "${tmp_vol}" $v 1

#     antsApplyTransforms \
#         -d 3 \
#         -i "${tmp_vol}" \
#         -r "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz" \
#         -t "${template_to_MNI_SyN}" \
#         -t "${template_to_MNI_affine}" \
#         -t "${MP2RAGE_to_template_SyN}" \
#         -t "${MP2RAGE_to_template_affine}" \
#         -t "${BIDS_root}/${sub_id}/func/${sub_id}_rest_to_anatomical_ANTS.mat" \
#         -o "${rs_fname}_MNI_vol-${v}.nii.gz" \
#         -n Linear
#     rm "${tmp_vol}"
# done

# # Merge back to 4D
# fslmerge -t "${rs_fname}_centred_unwarped_realigned_normalised.nii.gz" \
#     ${rs_fname}_MNI_vol-*.nii.gz
# rm ${rs_fname}_MNI_vol-*.nii.gz



#------------------------------------------------------------------------------------------------#
# Smooth images
echo "----------SMOOTHING----------"
matlab -batch "try, smooth_images('${rs_fname}_centred_unwarped_realigned_normalised.nii.gz', '${rs_fname}_centred_unwarped_realigned_normalised_smoothed.nii.gz', [6,6,6]); catch ME; rethrow(ME); end ; quit" 
