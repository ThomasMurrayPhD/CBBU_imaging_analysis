#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 4
#SBATCH -a 95-99
#SBATCH -p cclake
#SBATCH -t 8:00:00
#SBATCH --mem 32G
#SBATCH -o dropout_MP2RAGE_to_template_logs/dropout_MP2RAGE_to_template_%A_%a.out



# Estimates nonlinear transformation from MP2RAGE to template for dropout subjects


set -euo pipefail

if [ ! -d "dropout_MP2RAGE_to_template_logs" ]; then
    mkdir "dropout_MP2RAGE_to_template_logs"
fi

module load fsl/6.0.7
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$SLURM_CPUS_PER_TASK

# Specify BIDS root directory here
BIDS_root=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS_dropouts

# Get subject ID for this job (e.g. "sub-01")
sub_id=$(printf "sub-%02d" $SLURM_ARRAY_TASK_ID)

# Get subject-specific file names
MP2RAGE_fname="${BIDS_root}/${sub_id}/anat/${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred.nii.gz"

# Specify template name
template_fname=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/CBBU_template_5iter.nii.gz


# Print
echo "Starting ANTS Registration..."


# Linear and nonlinear registration of MP2RAGE to template
antsRegistration \
    --verbose 1 \
    --dimensionality 3 \
    --float 1 \
    --random-seed 1234 \
    --collapse-output-transforms 1 \
    --output [ "/${BIDS_root}/${sub_id}/anat/MP2RAGE_centred_to_template","/${BIDS_root}/${sub_id}/anat/MP2RAGE_centred_to_template.nii.gz" ]\
    --interpolation Linear \
    --winsorize-image-intensities [ 0.005,0.995 ] \
    --use-histogram-matching 0  \
    --initial-moving-transform [ "$template_fname","$MP2RAGE_fname",2 ] \
    --transform Rigid[0.1] \
    --metric MI[ "$template_fname","$MP2RAGE_fname",1,32,Regular,0.25 ] \
    --convergence [ 1000x500x250x100,1e-6,10 ] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox \
    --transform Affine[0.1] \
    --metric MI[ "$template_fname","$MP2RAGE_fname",1,32,Regular,0.25 ] \
    --convergence [ 1000x500x250x100,1e-6,10 ] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox \
    --transform SyN[0.1,1] \
    --metric CC[ "$template_fname","$MP2RAGE_fname",1,2 ] \
    --convergence [ 100x70x50x20,1e-6,10 ] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox

echo "ANTS Registration complete!"



