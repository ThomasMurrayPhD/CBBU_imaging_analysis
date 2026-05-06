#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 4
#SBATCH -p cclake
#SBATCH -t 1:00:00
#SBATCH --mem 8GB

eval "$(conda shell.bash hook)"
source $CONDA_PREFIX/etc/profile.d/conda.sh
conda activate cbbu


# map sub-IDs to directory numbers
declare -A subjects=(
    ["sub-95"]="37461"
    ["sub-96"]="37578"
    ["sub-97"]="37517"
    ["sub-98"]="39610"
    ["sub-99"]="39839"
)

# Loop through the dictionary
for sub in "${!subjects[@]}"; do
    dir=${subjects[$sub]}
    subj_id=${sub#sub-}   # removes 'sub-'

    dcm2bids \
      -d "/home/tom29/rds/hpc-work/cbbu_dcm/$dir/" \
      -p "$subj_id" \
      -c /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis/BIDS_config.json \
      -o /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS_dropouts \
      --force_dcm2bids

    python /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis/get_physio_files.py \
      -p "/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS_dropouts/$sub" \
      -d "/home/tom29/rds/hpc-work/cbbu_dcm/$dir"
done
