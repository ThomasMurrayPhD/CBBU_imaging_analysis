#!/bin/bash
#SBATCH -D /home/tom29/rds/hpc-work/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 4
#SBATCH -p cclake
#SBATCH -t 1:00:00
#SBATCH --mem 8GB

IDs=("40651"
    "39643"
    "40658"
    "40659"
    "40660"
    "29289"
    "33386"
    "40691"
    "40662"
    "40663"
    "40664"
    "40674"
    "40727"
    "40661"
    "40675"
)


for ID in "${IDs[@]}"; do
    output_dir="/home/tom29/rds/hpc-work/cbbu_young/dcm/$ID"
    mkdir -p "$output_dir"
    dcmconv.pl -remoteae P00594 -id "$ID" -outtype dicom10 -outdir "$output_dir" -all

done
