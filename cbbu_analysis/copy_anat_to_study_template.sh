#!/bin/bash

# script to copy (centred) anatomical files from subject BIDS directories to study_template directory


src_base="/home/tom29/rds/hpc-work/cbbu_BIDS"
dest_dir="/home/tom29/rds/hpc-work/cbbu_analysis/study_template"

for subj in $(seq -w 1 44); do
	src_file="${src_base}/sub-${subj}/anat/sub-${subj}_acq-whole_UNI_MP2RAGE_brain_N4_centred.nii.gz"
	cp "$src_file" "$dest_dir/"
done


