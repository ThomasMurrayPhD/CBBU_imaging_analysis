#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 1
#SBATCH -a 1-44
#SBATCH -p cclake
#SBATCH -t 30:00
#SBATCH --mem 32G
#SBATCH -o run_contrasts_log/run_contrasts_%A_%a.out


# script to run contrasts on first level GLM results

# Load SPM (and matlab)
module load spm/spm12

# Specify BIDS root directory
BIDS_root="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS"

# Get subject ID for this job (e.g. "sub-01")
sub_id=$(printf "sub-%02d" $SLURM_ARRAY_TASK_ID)

# Specify GLM Root directory for this subject
glm_root="${BIDS_root}/${sub_id}/GLM/No_parametric_modulators"

# Specify output batch file name
output_batch_fname="${BIDS_root}/${sub_id}/GLM/No_parametric_modulators/first_level_contrasts_batch.mat"

# Print some info for logging
echo "Running contrasts for ${sub_id}"
echo "GLM root directory: ${glm_root}"
echo "Output batch file: ${output_batch_fname}"

# Run matlab function to specify and run contrasts
matlab -nodisplay -r "addpath('/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis'); specify_first_level_contrasts('${glm_root}', '${output_batch_fname}'); exit;"

