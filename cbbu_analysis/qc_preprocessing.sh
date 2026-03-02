#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_analysis/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 1
#SBATCH -p cclake
#SBATCH -t 02:00:00
#SBATCH --mem=32G
#SBATCH -o /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_QC/logs/QC_%A_%a.log
#SBATCH --array=1-44

set -euo pipefail

module load fsl/6.0.7

BIDS_ROOT=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS
QC_DIR=/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_QC

MNI_05MM=${FSLDIR}/data/standard/MNI152_T1_0.5mm.nii.gz
MNI_1MM=${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz

mkdir -p "${QC_DIR}/pngs"
mkdir -p "${QC_DIR}/tmp"
mkdir -p "${QC_DIR}/logs"

# ============================
# GET SUBJECT FOR THIS ARRAY TASK
# ============================

SUBJECTS=(${BIDS_ROOT}/sub-*)
subdir=${SUBJECTS[$SLURM_ARRAY_TASK_ID-1]}
sub=$(basename "$subdir")

echo "Running QC for $sub"

anat_dir="${subdir}/anat"
func_dir="${subdir}/func"

CSV="${QC_DIR}/${sub}_qc_summary.csv"
echo "sub,run,mean_FD,max_FD,FD_outliers,epi_mni_corr,t1_mni_corr,flag" > "$CSV"

# ----------------------------
# T1 QC
# ----------------------------

T1_MNI="${anat_dir}/${sub}_acq-whole_UNI_MP2RAGE_brain_N4_centred_normalised.nii.gz"

if [[ -f "$T1_MNI" ]]; then
    t1_corr=$(fslcc "$T1_MNI" "$MNI_05MM" | awk '{print $3}' | head -n1)

    slicer "$T1_MNI" "$MNI_05MM" \
        -a "${QC_DIR}/pngs/${sub}_T1_MNI.png"
else
    echo "Missing T1 for $sub"
    exit 1
fi

# ----------------------------
# FUNCTIONAL RUNS
# ----------------------------

for run in 1 2; do

    FUNC="${func_dir}/${sub}_task-facehouse_acq-${run}_dir-PA_bold_centred_unwarped_realigned_normalised.nii.gz"
    RP="${func_dir}/${sub}_task-facehouse_acq-${run}_dir-PA_bold_centred_unwarped_realigned.par"

    if [[ ! -f "$FUNC" || ! -f "$RP" ]]; then
        echo "Missing func or RP for $sub run $run"
        continue
    fi

    meanEPI="${QC_DIR}/tmp/${sub}_run${run}_meanEPI.nii.gz"
    fslmaths "$FUNC" -Tmean "$meanEPI"

    epi_corr=$(fslcc "$meanEPI" "$MNI_1MM" | awk '{print $3}' | head -n1)

    slicer "$meanEPI" "$MNI_1MM" \
        -a "${QC_DIR}/pngs/${sub}_run${run}_EPI_MNI.png"

    fd_file="${QC_DIR}/tmp/${sub}_run${run}_fd.txt"

    fsl_motion_outliers \
        -i "$FUNC" \
        --fd \
        -o /dev/null \
        -s "$fd_file"

    mean_fd=$(awk '{s+=$1} END {print s/NR}' "$fd_file")
    max_fd=$(sort -nr "$fd_file" | head -n1)
    fd_outliers=$(awk '$1>0.5 {c++} END {print c+0}' "$fd_file")

    flag="OK"

    if [[ -z "$epi_corr" || -z "$t1_corr" ]]; then
        flag="CHECK"
    elif awk "BEGIN {exit !($epi_corr < 0.4 || $t1_corr < 0.5 || $mean_fd > 0.5)}"; then
        flag="CHECK"
    fi

    echo "${sub},${run},${mean_fd},${max_fd},${fd_outliers},${epi_corr},${t1_corr},${flag}" >> "$CSV"

done

echo "QC complete for $sub"