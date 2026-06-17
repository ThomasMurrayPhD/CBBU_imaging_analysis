

# script to run normalisation of images in subject space to MNI on lab PC

set -euo pipefail

if [ ! -d "normalise_subject_to_MNI_logs" ]; then
    mkdir "normalise_subject_to_MNI_logs"
fi


# loop through subjects
for sub in $(seq -w 01 44); do

    sub_num=$((10#$sub)) # convert to number to avoid issues with leading zeros (i.e. sub-01 -> 1, sub-02 -> 2, sub-44 -> 44)
    sub_id=$(printf "sub-%02d" "$sub_num") # convert back to string with leading zeros (i.e. 1 -> sub-01, 2 -> sub-02, 44 -> sub-44)
    

    # Specify BIDS root directory here
    BIDS_root='/mnt/f/cbbu_BIDS'

    # Transformations
    idx=$((sub_num - 1))  # deals with the weird index at the end of the transformation files (i.e. sub-01 -> 0, sub-02 -> 1, sub-44 -> 43)
    MP2RAGE_to_template_affine="/mnt/f/cbbu_study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}0GenericAffine.mat"
    MP2RAGE_to_template_SyN="/mnt/f/cbbu_study_template/ANTs_iteration_5/T1TMP_${sub_id}_acq-whole_UNI_MP2RAGE_brain_N4_centred${idx}1Warp.nii.gz"
    template_to_1mm_MNI_affine="/mnt/f/cbbu_study_template/CBBU_template_5iter-to-1mmMNI0GenericAffine.mat"
    template_to_1mm_MNI_SyN="/mnt/f/cbbu_study_template/CBBU_template_5iter-to-1mmMNI1Warp.nii.gz"

    functional_to_anatomical_affine="${BIDS_root}/${sub_id}/func/${sub_id}_func_to_anatomical_ANTS.mat"

    # List of input images to normalise
    input_images=(
        "${BIDS_root}/${sub_id}/GLM/uHGF_2level_parametric_modulators/con_0001.nii"
        "${BIDS_root}/${sub_id}/GLM/uHGF_2level_parametric_modulators/con_0002.nii"
        "${BIDS_root}/${sub_id}/GLM/uHGF_2level_parametric_modulators/con_0003.nii"
    )
    

    # Loop over input images and normalise each one
    for input_image in "${input_images[@]}"; do

        if [ ! -f "$input_image" ]; then
            echo "Missing input image ${input_image} for ${sub_id} — skipping"
            continue
        fi

        echo "Normalising ${input_image} for ${sub_id}"

        # Apply all transformations in single step.
        antsApplyTransforms \
            -d 3 \
            -e 0 \
            --float \
            -i "$input_image" \
            -r "${FSLDIR}/data/standard/MNI152_T1_1mm_brain.nii.gz" \
            -t "${template_to_1mm_MNI_SyN}" \
            -t "${template_to_1mm_MNI_affine}" \
            -t "${MP2RAGE_to_template_SyN}" \
            -t "${MP2RAGE_to_template_affine}" \
            -t "${functional_to_anatomical_affine}" \
            -o "${input_image%.nii}_normalised.nii.gz" \
            -n Linear

        echo "Finished normalising ${input_image} for ${sub_id}"

    done
done