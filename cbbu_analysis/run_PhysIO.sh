#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 1
#SBATCH -a 1-44
#SBATCH -p cclake
#SBATCH -t 0:10:00
#SBATCH --mem 16G
#SBATCH -o run_PhysIO_logs/run_PhysIO_%A_%a.out


# Script to get physiological regressors with PhysIO toolbox


set -euo pipefail
module load spm/spm12

# Get subject ID for this job (e.g. "sub-01")
sub_id=$(printf "sub-%02d" $SLURM_ARRAY_TASK_ID)

# Specify sub root
sub_root="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS/${sub_id}/func/"

# Specify physio toolbox directory
physio_root=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/PhysIO
physio_path=${physio_root}/code

# Specify output directory
physio_output="${sub_root}/physio_output/"


# Run analysis separately for each run
for run in {1..2}; do

    echo "---- Processing run ${run} for ${sub_id} ----"

    # Specify cardiac data
    c_data="${sub_root}/${sub_id}_task-facehouse_acq-${run}_dir-PA_recording-cardiac_physio.tsv.gz"

    # Specify respiratory data
    r_data="${sub_root}/${sub_id}_task-facehouse_acq-${run}_dir-PA_recording-respiratory_physio.tsv.gz"

    # Specify realignment parameters
    rp="${sub_root}/${sub_id}_task-facehouse_acq-${run}_dir-PA_bold_centred_unwarped_realigned.par"

    # Check inputs exist
    for f in "$c_data" "$r_data" "$rp"; do
        [ -f "$f" ] || { echo "ERROR: Missing file $f"; exit 1; }
    done

    # Run matlab script
    matlab -batch "try, addpath('$physio_path'); addpath('$physio_root'); cbbu_get_physio_regressors('${physio_path}', '${physio_output}', '${c_data}', '${r_data}', '${rp}'); catch ME; rethrow(ME); end; quit"

done