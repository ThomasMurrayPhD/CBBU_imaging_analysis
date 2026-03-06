#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 1
#SBATCH -a 1-44
#SBATCH -p cclake
#SBATCH -t 1:30:00
#SBATCH --mem 32G
#SBATCH -o fit_GLM_logs/fit_GLM_%A_%a.out



# script to fit first level GLM

# Load SPM (and matlab)
module load spm/spm12

# Specify BIDS root directory
BIDS_root="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS"

# Get subject ID for this job (e.g. "sub-01")
sub_id=$(printf "sub-%02d" $SLURM_ARRAY_TASK_ID)


# Specfiy file names
run1_scans="${BIDS_root}/${sub_id}/func/${sub_id}_task-facehouse_acq-1_dir-PA_bold_centred_unwarped_realigned_normalised_smoothed.nii.gz"
run2_scans="${BIDS_root}/${sub_id}/func/${sub_id}_task-facehouse_acq-2_dir-PA_bold_centred_unwarped_realigned_normalised_smoothed.nii.gz"
run1_trials_fname=$(ls ${BIDS_root}/${sub_id}/beh/${sub_id}_facehouse-MRI_run1_*.mat 2>/dev/null | head -n 1)
run2_trials_fname=$(ls ${BIDS_root}/${sub_id}/beh/${sub_id}_facehouse-MRI_run2_*.mat 2>/dev/null | head -n 1)

if [ -z "$run1_trials_fname" ]; then
    echo "No run1 trials file found for ${sub_id}"
    exit 1
fi

if [ -z "$run2_trials_fname" ]; then
    echo "No run2 trials file found for ${sub_id}"
    exit 1
fi

#run1_modulators="[]"
#run2_modulators="[]"
output_batch_fname="${BIDS_root}/${sub_id}/GLM/first_level_batch.mat"
spm_output_dir="${BIDS_root}/${sub_id}/GLM/"
runjob="true"



# multiple regressors
physio_dir="${BIDS_root}/${sub_id}/func/${sub_id}_facehouse_physio_output"
if [ -d "$physio_dir" ]; then
    echo "Using physio regressors for ${sub_id}"
    run1_multiple_regressors_fname="${physio_dir}/run-1_physio_regressors.txt"
    run2_multiple_regressors_fname="${physio_dir}/run-2_physio_regressors.txt"
else
    echo "No physio found for ${sub_id} — using realignment parameters"
    run1_multiple_regressors_fname="${BIDS_root}/${sub_id}/func/${sub_id}_task-facehouse_acq-1_dir-PA_bold_centred_unwarped_realigned.par"
    run2_multiple_regressors_fname="${BIDS_root}/${sub_id}/func/${sub_id}_task-facehouse_acq-2_dir-PA_bold_centred_unwarped_realigned.par"
fi

echo "Run1 trials file: $run1_trials_fname"
echo "Run2 trials file: $run2_trials_fname"

# Create directory
mkdir -p "${spm_output_dir}"

# specify and fit model
matlab -batch "addpath('/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis'); \
            spm('defaults','fmri'); \
            spm_jobman('initcfg'); \
            try, specify_first_level_2runs( \
            '${run1_scans}', \
            '${run2_scans}', \
            '${run1_trials_fname}', \
            '${run2_trials_fname}', \
            '${run1_multiple_regressors_fname}', \
            '${run2_multiple_regressors_fname}', \
            [], \
            [], \
            '${output_batch_fname}', \
            '${spm_output_dir}', \
            '${runjob}'); catch ME; rethrow(ME); end; quit"

