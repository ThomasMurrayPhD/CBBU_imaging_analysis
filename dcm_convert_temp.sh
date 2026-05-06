#!/bin/bash
#SBATCH -D /home/tom29/rds/hpc-work/
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
    ["sub-01"]="40651"
    ["sub-02"]="39643"
    ["sub-03"]="40658"
    ["sub-04"]="40659"
    ["sub-05"]="40660"
    ["sub-06"]="29289"
    ["sub-07"]="33386"
    ["sub-08"]="40691"
    ["sub-09"]="40662"
    ["sub-10"]="40663"
    ["sub-11"]="40664"
    ["sub-12"]="40674"
    ["sub-13"]="40727"
    ["sub-14"]="40661"
    ["sub-15"]="40675"
)

# Loop through the dictionary
for sub in "${!subjects[@]}"; do
    dir=${subjects[$sub]}
    subj_id=${sub#sub-}   # removes 'sub-'

    dcm2bids \
      -d "/home/tom29/rds/hpc-work/cbbu_young/dcm/$dir/" \
      -p "$subj_id" \
      -c /home/tom29/rds/hpc-work/cbbu_analysis/BIDS_config.json \
      -o /home/tom29/rds/hpc-work/cbbu_young/BIDS \
      --force_dcm2bids

    python /home/tom29/rds/hpc-work/cbbu_analysis/get_physio_files.py \
      -p "/home/tom29/rds/hpc-work/cbbu_young/BIDS/$sub" \
      -d "/home/tom29/rds/hpc-work/cbbu_young/dcm/$dir"
done
