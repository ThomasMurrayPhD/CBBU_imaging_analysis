#!/bin/bash
#SBATCH -D /home/tom29/rds/hpc-work/cbbu_analysis/test/
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -o logs/test_preprocess.log
#SBATCH -c 1
#SBATCH -p cclake-himem
#SBATCH -t 3:00:00
#SBATCH --mem 68400M





############# TO DO ###############
# Update MP2RAGE to UNI in file names
# Use MP2RAGE-to-template and template-to-MNI transformations from LC script
# Remove skull strip / segmentation (this will already have been performed)
# Need to ACPC functional runs
#   Use this:
#   matlab -batch "try,addpath('$crop_dir'); crop_images({'${file}.nii.gz'},0,3); catch ME; rethrow(ME); end ; quit"


#eval "$(conda shell.bash hook)"
#source $CONDA_PREFIX/etc/profile.d/conda.sh
#conda activate cbbu


module load spm/spm12
module load fsl


### Specify subject, file names, etc
sub=5
sub_BIDS=$(printf "sub-%02d" "$sub") #e.g. "sub-05"
sub_root="$(pwd)/${sub_BIDS}"
run1_fname="${sub_root}/func/${sub_BIDS}_task-facehouse_acq-1_dir-PA"
run2_fname="${sub_root}/func/${sub_BIDS}_task-facehouse_acq-2_dir-PA"

# Specify crop script directory
crop_dir=/home/tom29/rds/hpc-work/cbbu_analysis/crop/


echo "SUBJECT: ${sub}"
echo "DIRECTORY: ${sub_root}"

### Slice time correction # Not sure if needed...
TR=3000
#echo "---SLICE TIME CORRECTION---"
#matlab -nodisplay -r "slice_time_correction $run1_fname $TR; quit" # this won't work due to extension
#matlab -nodisplay -r "slice_time_correction $run2_fname $TR; quit" 

### Correct for susceptibility induced distiortions (topup)
#echo "---SUSCEPTIBILITY DISTORTION CORRECTION---"
# create directory
#mkdir "${sub_root}/fmap"

# extract last 5 vols of run 2 (PA)
# Last 5 vols as these are closest in time to the invPE
#last_5_idx=$(( $(fslnvols "${run2_fname}_bold.nii.gz") - 5 ))
#PA_5vols_fname="${sub_root}/func/facehouse_PA_5vols"
#fslroi "${run1_fname}_bold.nii.gz" "${PA_5vols_fname}.nii.gz" $last_5_idx 5

# get 5 vols of invPE (AP)
#invPE_fname="${sub_root}/func/${sub_BIDS}_acq-LC_dir-AP_bold"
#AP_5vols_fname="${sub_root}/func/facehouse_AP_5vols"
#fslroi "${invPE_fname}.nii.gz" "${AP_5vols_fname}.nii.gz" 0 5

# create merged files (15/08 - put PA first as fieldmap is aligned with first image - see topup docs)
#PA_AP_fname="${sub_root}/func/facehouse_PA_AP"
#fslmerge -t "${PA_AP_fname}.nii.gz" "${PA_5vols_fname}.nii.gz" "${AP_5vols_fname}.nii.gz"

# use topup to estimate distortion
#acq_params_fname="../topup_acquisition_params.txt"
#config_fname="../topup_b0_sk.cnf"
#topup --imain="${PA_AP_fname}.nii.gz" \
#    --datain="$acq_params_fname" \
#    --config="$config_fname" \
#    --out=topup_facehouse_results \
#    --iout=topup_facehouse_imain_unwarped \
#    --fout=topup_facehouse_field_Hz \
#    --nthr=$SLURM_CPUS_PER_TASK \
#    --verbose

# use topup to apply correction (to both runs)
run1_unwarped_fname="${run1_fname}_unwarped"
run2_unwarped_fname="${run2_fname}_unwarped"
#applytopup --imain="${run1_fname}_bold.nii.gz" \
#    --topup=topup_facehouse_results \
#    --datain="$acq_params_fname" \
#    --inindex=1 \
#    --out="${run1_unwarped_fname}_bold.nii.gz" \
#    --method=jac
#applytopup --imain="${run2_fname}_bold.nii.gz" \
#    --topup=topup_facehouse_results \
#    --datain="$acq_params_fname" \
#    --inindex=1 \
#    --out="${run2_unwarped_fname}_bold.nii.gz" \
#    --method=jac

# move all the topup output files to fmap folder
#mv topup_* "${sub_root}/fmap"

### Realignment
#echo "---REALIGNMENT---"

# get reference volume (vol 1 from run 1)
ref_vol_fname="${sub_root}/func/${sub_BIDS}_task-facehouse_realignment_reference_vol.nii.gz"
#fslroi "${run1_unwarped_fname}_bold.nii.gz" "${ref_vol_fname}" 0 1

# Realign both runs (coregister to reference volume)
run1_motioncorrected_fname="${run1_unwarped_fname}_realigned"
run2_motioncorrected_fname="${run2_unwarped_fname}_realigned"
#mcflirt -in "${run1_unwarped_fname}_bold.nii.gz"\
#    -out "${run1_motioncorrected_fname}_bold.nii.gz"\
#    -reffile $ref_vol_fname\
#    -plots
#mcflirt -in "${run2_unwarped_fname}_bold.nii.gz"\
#    -out "${run2_motioncorrected_fname}_bold.nii.gz"\
#    -reffile $ref_vol_fname\
#    -plots

# concatenate runs
#echo "concatenating runs"
concat_fname="${sub_root}/func/${sub_BIDS}_task-facehouse_acq-both_dir-PA_unwarped_realigned"
#fslmerge -t "${concat_fname}_bold.nii.gz" "${run1_motioncorrected_fname}_bold.nii.gz" "${run2_motioncorrected_fname}_bold.nii.gz"


#----- STRUCTURAL PREPROCESSING -----#

### Brain extraction
#echo "---BRAIN EXTRACTION---"

# extract the brain using inv-02
#mp2rage_inv02_fname="${sub_root}/anat/${sub_BIDS}_acq-whole_inv-02_MP2RAGE"
#bet "${mp2rage_inv02_fname}.nii.gz" "${mp2rage_inv02_fname}_brain.nii.gz" -m -f .4 -g .2 -R

# apply mask to inv-03 
mp2rage_UNI_fname="${sub_root}/anat/${sub_BIDS}_acq-whole_inv-03_MP2RAGE"
#fslmaths "${mp2rage_UNI_fname}.nii.gz" -mas "${mp2rage_inv02_fname}_brain_mask.nii.gz" "${mp2rage_UNI_fname}_brain.nii.gz"

### White matter segmentation
#echo "---Tissue segmentation---"
#fast -n 3\
#    -o "${mp2rage_UNI_fname}_brain"\
#    -b "${mp2rage_UNI_fname}_brain_bias_field"\
#    -t 1\
#    "${mp2rage_UNI_fname}_brain.nii.gz"


#------------------------------------#


### Coregistration of EPI sequence
# https://fsl.fmrib.ox.ac.uk/fsl/docs/#/registration/flirt/user_guide?id=using-flirt-to-register-a-few-fmri-slices
concat_standardised_fname="${concat_fname}_standardised"
# whole_EPI_fname="${sub_root}/func/${sub_BIDS}_acq-whole_dir-PA"

#create mean EPI
# fslmaths "${concat_fname}_bold.nii.gz" -Tmean "${concat_fname}_mean_bold.nii.gz"


### Let's just try registering the mean EPI to the anatomical...
# 1 Register mean EPI to MP2RAGE
#echo "registering mean EPI to anatomical..."
#flirt -in "${concat_fname}_mean_bold.nii.gz"\
#    -ref "${mp2rage_UNI_fname}_brain.nii.gz"\
#    -omat "${sub_root}/func/func_to_anatomical.mat"\
#    -out "${concat_fname}_mean_coregistered_bold.nii.gz"\ ### don't need this
#    -dof 12\
#    -cost bbr \
#    -wmseg "${mp2rage_UNI_fname}_brain_pve_2.nii.gz"

#### Ok so here we should register MP2RAGE to the study template, then register the template to MNI. We can use the transformations from the LC analyses

# 2 Register MP2RAGE to standard (affine transformation)
#echo "registering anatomical to standard (affine)..."
#flirt -in "${mp2rage_UNI_fname}_brain.nii.gz"\
#    -ref "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz" \
#    -out "${mp2rage_UNI_fname}_brain_standardised.nii.gz" \
#    -dof 12\
#    -cost mutualinfo\
#    -omat "${sub_root}/func/anatomical_to_standard.mat"

# 3 Concatenate transformations
#convert_xfm "${sub_root}/func/func_to_anatomical.mat" -concat "${sub_root}/func/anatomical_to_standard.mat" -omat "${sub_root}/func/func_to_standard.mat" 

# 4 Register concatenated run to standard using transformations
#echo "registering concatenated functional runs to standard..."
#flirt -in "${concat_fname}_bold.nii.gz"\
#    -ref "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz"\
#    -applyxfm -init "${sub_root}/func/func_to_standard.mat"\
#    -nosearch \
#    -out "${concat_standardised_fname}_bold.nii.gz"



### Normalise
# https://neurostars.org/t/fnirt-registration-problem-into-mni-1mm-space/25555/4
#https://www.jiscmail.ac.uk/cgi-bin/webadmin?A2=fsl;d14e5a9d.1105 <- this one
#
# Maybe use ANTS to normalise - look at Jacobs paper. 
# They use antsRegistrationSyN.sh, and perform rigid+affine+SyN registration from T1 to MNI in single step. 
# May not need steps 2,3 above...
# Jacobs et al use BBR (with flirt/epi_reg) to get the EPI->T1 transformation matrix, then use ants to get the T1->MNI transformation
# then combine the transformations with this c3d thing - apparently I can also do that with ants
echo "---NORMALISE---"

cd "${sub_root}/anat/"
#antsRegistrationSyN.sh \
#    -d 3 \
#    -f "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz" \
#    -m "$(basename "$mp2rage_UNI_fname")_brain.nii.gz" \
#    -o "T1_to_MNI_" \
#    -n $SLURM_CPUS_PER_TASK \
#    -t s

cd ../..


# convert FSL affine transformation matrix to ANTS format
/home/tom29/c3d-1.1.0-Linux-x86_64/bin/c3d_affine_tool \
    -ref "${mp2rage_UNI_fname}_brain.nii.gz" \
    -src "${concat_fname}_mean_bold.nii.gz" \
    "${sub_root}/func/func_to_anatomical.mat" \
    -fsl2ras \
    -oitk "${sub_root}/func/c3d_func_to_anatomical.txt"

# Concatenate transformations and apply to mean EPI (to test)
antsApplyTransforms \
    -d 3 \
    -i "${concat_fname}_mean_bold.nii.gz"\
    -r "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz"\
    -t "${sub_root}/anat/T1_to_MNI_1Warp.nii.gz" \
    -t "${sub_root}/anat/T1_to_MNI_0GenericAffine.mat" \
    -t "${sub_root}/func/c3d_func_to_anatomical.txt" \
    -o "${sub_root}/func/ANTS_mean_coregistered_bold2.nii.gz"\
    -n Linear

# Concatenate transformations and apply to whole EPI sequence
# seff 62897244
# Memory Utilized: 62.85GB
antsApplyTransforms \
    -d 3 \
    -e 3\
    -i "${concat_fname}_bold.nii.gz" \
    -r "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz" \
    -t "${sub_root}/anat/T1_to_MNI_1Warp.nii.gz" \
    -t "${sub_root}/anat/T1_to_MNI_0GenericAffine.mat" \
    -t "${sub_root}/func/c3d_func_to_anatomical.txt" \
    -o "${concat_standardised_fname}_bold.nii.gz" \
    -n Linear


### Smoothing

### Correct for physiological noise (after smoothing?)


# Delete unwanted files
# ref_vol_fname





################## Retired code....

# COREGISTRATION VIA WHOLE BRAIN EPI
# 1 Register reference vol to quick whole brain EPI
# bear in mind the whole brain EPI is not unwarped (and we can't unwarp it)
# fsl docs say to register partial view to whole brain using limited (3DOF) FLIRT registration - When running, I get an error "Erroneous dof 3 : using 6 instead"
#echo "registering reference volumne to whole brain EPI..."
#flirt -in "${ref_vol_fname}"\
#    -ref "${whole_EPI_fname}_bold.nii.gz"\
#    -omat "${sub_root}/func/func_to_whole.mat"\
#    -dof 6\
#    -noresample \
#    -cost mutualinfo

# 2 Register whole brain EPI to MP2RAGE
#echo "registering whole brain EPI to anatomical..."
#flirt -in "${concat_fname}_mean_bold.nii.gz"\
#    -ref "${mp2rage_UNI_fname}_brain.nii.gz"\
#    -omat "${sub_root}/func/whole_to_anatomical.mat"\
#    -dof 6\
#    -cost bbr \
#    -wmseg "${mp2rage_UNI_fname}_brain_pve_2.nii.gz"

# 3 Register MP2RAGE to standard (affine transformation)
#echo "registering anatomical to standard (affine)..."
#flirt -in "${mp2rage_UNI_fname}_brain.nii.gz"\
#    -ref "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz" \
#    -out "${mp2rage_UNI_fname}_brain_standardised.nii.gz" \
#    -dof 12\
#    -cost mutualinfo\
#    -omat "${sub_root}/func/anatomical_to_standard.mat"

# 4 Concatenate transformations
#convert_xfm "${sub_root}/func/func_to_whole.mat" -concat "${sub_root}/func/whole_to_anatomical.mat" -omat "${sub_root}/func/func_to_anatomical.mat" 
#convert_xfm "${sub_root}/func/func_to_anatomical.mat" -concat "${sub_root}/func/anatomical_to_standard.mat" -omat "${sub_root}/func/func_to_standard.mat" 

# 5 Register concatenated run to standard using transformations
#echo "registering concatenated functional runs to standard..."
#flirt -in "${concat_fname}_bold.nii.gz"\
#    -ref "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz"\
#    -applyxfm -init "${sub_root}/func/func_to_standard.mat"\
#    -nosearch \
#    -out "${concat_standardised_fname}_bold.nii.gz"

# 6 register whole brain EPI to standard (to check where/if anything has gone wrong)
#convert_xfm -omat "${sub_root}/func/whole_to_standard.mat" -concat "${sub_root}/func/whole_to_anatomical.mat" "${sub_root}/func/anatomical_to_standard.mat"
#flirt -in "${whole_EPI_fname}_bold.nii.gz"\
#    -ref "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz"\
#    -applyxfm -init "${sub_root}/func/whole_to_standard.mat"\
#    -nosearch \
#    -out "${whole_EPI_fname}_coregistered_bold.nii.gz"