#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 4
#SBATCH -p cclake
#SBATCH -t 8:00:00
#SBATCH --mem 32G
#SBATCH -o template_normalise_logs/1mm_template_normalise.log



# Normalises study template to MNI space
# IMPORTANT: Need to have run MP2RAGE_prepare.sh
# 
#------------------------------------------------------------------------------------------------#


set -euo pipefail

if [ ! -d "template_normalise_logs" ]; then
    mkdir "template_normalise_logs"
fi

module load fsl/6.0.7
export ITK_GLOBAL_DEFAULT_NUMBER_OF_THREADS=$SLURM_CPUS_PER_TASK


# Specify template name
template_fname=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/CBBU_template_5iter.nii.gz

# Specify MNI target name
MNI_05mm_fname="${FSLDIR}/data/standard/MNI152_T1_0.5mm.nii.gz"
MNI_1mm_fname="${FSLDIR}/data/standard/MNI152_T1_1mm.nii.gz"

# Print
echo "Starting ANTS Registration..."

# Linear and nonlinear registrations (to 0.5mm MNI template)
# antsRegistration \
#     --verbose 1 \
#     --dimensionality 3 \
#     --float 1 \
#     --random-seed 1234 \
#     --collapse-output-transforms 1 \
#     --output [ "/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/CBBU_template_5iter-to-MNI","/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/CBBU_template_5iter-to-MNI.nii.gz" ]\
#     --interpolation Linear \
#     --winsorize-image-intensities [ 0.005,0.995 ] \
#     --use-histogram-matching 0  \
#     --initial-moving-transform [ "$MNI_05mm_fname","$template_fname",2 ] \
#     --transform Rigid[0.1] \
#     --metric MI[ "$MNI_05mm_fname","$template_fname",1,32,Regular,0.25 ] \
#     --convergence [ 1000x500x250x100,1e-6,10 ] \
#     --shrink-factors 8x4x2x1 \
#     --smoothing-sigmas 3x2x1x0vox \
#     --transform Affine[0.1] \
#     --metric MI[ "$MNI_05mm_fname","$template_fname",1,32,Regular,0.25 ] \
#     --convergence [ 1000x500x250x100,1e-6,10 ] \
#     --shrink-factors 8x4x2x1 \
#     --smoothing-sigmas 3x2x1x0vox \
#     --transform SyN[0.1,1] \
#     --metric CC[ "$MNI_05mm_fname","$template_fname",1,2 ] \
#     --convergence [ 100x70x50x20,1e-6,10 ] \
#     --shrink-factors 8x4x2x1 \
#     --smoothing-sigmas 3x2x1x0vox



# Linear registration to 1mm MNI template (for use with SPM)
antsRegistration \
    --verbose 1 \
    --dimensionality 3 \
    --float 1 \
    --random-seed 1234 \
    --collapse-output-transforms 1 \
    --output [ "/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/CBBU_template_5iter-to-1mmMNI","/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_study_template/CBBU_template_5iter-to-1mmMNI.nii.gz" ]\
    --interpolation Linear \
    --winsorize-image-intensities [ 0.005,0.995 ] \
    --use-histogram-matching 0  \
    --initial-moving-transform [ "$MNI_1mm_fname","$template_fname",2 ] \
    --transform Rigid[0.1] \
    --metric MI[ "$MNI_1mm_fname","$template_fname",1,32,Regular,0.25 ] \
    --convergence [ 1000x500x250x100,1e-6,10 ] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox \
    --transform Affine[0.1] \
    --metric MI[ "$MNI_1mm_fname","$template_fname",1,32,Regular,0.25 ] \
    --convergence [ 1000x500x250x100,1e-6,10 ] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox \
    --transform SyN[0.1,1] \
    --metric CC[ "$MNI_1mm_fname","$template_fname",1,2 ] \
    --convergence [ 100x70x50x20,1e-6,10 ] \
    --shrink-factors 8x4x2x1 \
    --smoothing-sigmas 3x2x1x0vox

echo "ANTS Registration complete!"