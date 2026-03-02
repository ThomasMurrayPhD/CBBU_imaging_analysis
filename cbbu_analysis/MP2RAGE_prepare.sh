#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 4
#SBATCH -a 37
#SBATCH -p cclake
#SBATCH -t 00:30:00
#SBATCH --mem 32G
#SBATCH -o MP2RAGE_prepare_logs/MP2RAGE_prepare_%A_%a.out


### set -a to 1-N when ready


set -euo pipefail

if [ ! -d "MP2RAGE_prepare_logs" ]; then
    mkdir "MP2RAGE_prepare_logs"
fi

module load fsl/6.0.7
module load spm/spm12

# Performs N4 bias correction, brain extraction, segmentation, and ACPC on MP2RAGE imeages, in parallel
#----------------------------------------------------------------------------------------------#

# Specify BIDS root directory here
BIDS_root=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS

# Specify centre_images script directory
centre_dir=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/centre_images/

# Get subject ID for this job (e.g. "sub-01")
sub_id=$(printf "sub-%02d" $SLURM_ARRAY_TASK_ID)

# Set paths and file names here (to stop using full path in all functions)
inv02_fname="${BIDS_root}/${sub_id}/anat/${sub_id}_acq-whole_inv-02_MP2RAGE"
uni_fname="${BIDS_root}/${sub_id}/anat/${sub_id}_acq-whole_UNI_MP2RAGE"

# use synthstrip to extract INV02 brain (no csf)
mri_synthstrip \
    -i "${inv02_fname}.nii.gz"\
    -o "${inv02_fname}_brain.nii.gz"\
    -m "${BIDS_root}/${sub_id}/anat/${sub_id}_mask.nii.gz"\
    --no-csf

# apply mask to UNI
fslmaths \
    "${uni_fname}.nii.gz" \
    -mas "${BIDS_root}/${sub_id}/anat/${sub_id}_mask.nii.gz" \
    "${uni_fname}_brain.nii.gz"

# Run N4 bias correction
N4BiasFieldCorrection \
    -d 3 \
    -i "${uni_fname}_brain.nii.gz" \
    -r 1 \
    -c [50x50x30x20,1e-6] \
    -o "${uni_fname}_brain_N4.nii.gz"

# Centre (set origin) UNI and Mask
centre_transform_mat="${BIDS_root}/${sub_id}/anat/${sub_id}_affine-transform-to-centre.mat"
matlab -batch "try,addpath('$centre_dir'); estimate_centre_transform('${uni_fname}_brain_N4.nii.gz', 'T1', '${centre_transform_mat}'); catch ME; rethrow(ME); end ; quit" 
matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${uni_fname}_brain_N4.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 
matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${inv02_fname}_brain.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit" 
matlab -batch "try,addpath('$centre_dir'); affine_transform_nii('${centre_transform_mat}', '${BIDS_root}/${sub_id}/anat/${sub_id}_mask.nii.gz', 'centred'); catch ME; rethrow(ME); end ; quit"


# Segment
mri_synthseg \
    --i "${uni_fname}_brain_N4_centred.nii.gz" \
    --o "${uni_fname}_brain_N4_centred_segmented.nii.gz" \
    --parc \
    --robust \
    --threads $SLURM_CPUS_PER_TASK


# Extract white matter from segmentation image
fslmaths "${uni_fname}_brain_N4_centred_segmented.nii.gz" -thr 2 -uthr 2 -bin "${uni_fname}_WMmask_L.nii.gz"
fslmaths "${uni_fname}_brain_N4_centred_segmented.nii.gz" -thr 41 -uthr 41 -bin "${uni_fname}_WMmask_R.nii.gz"
fslmaths "${uni_fname}_WMmask_L.nii.gz" -add "${uni_fname}_WMmask_R.nii.gz" "${uni_fname}_brain_N4_centred_WMmask.nii.gz"
rm "${uni_fname}_WMmask_L.nii.gz"
rm "${uni_fname}_WMmask_R.nii.gz"