#!/bin/bash
#SBATCH -D /home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis
#SBATCH -A LAWSON-SL3-CPU
#SBATCH -c 4
#SBATCH -p cclake
#SBATCH -t 6:00:00
#SBATCH --mem 32G
#SBATCH -o run_LC_CNR_logs/LC_CNR.out


set -euo pipefail


BIDS_root="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/cbbu_BIDS"
LC_atlas_dir="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/LC_7T_prob/"
output_csv="/home/tom29/rds/rds-pal_lab-WJZDLUY2Dhw/CBBU_imaging_analysis/cbbu_analysis/LC_integrity_results.csv"

module load spm/spm12

# Create CSV header
echo "subject,\
CNR_LC0_bi,CNR_LC0_L,CNR_LC0_R,\
CNR_LC5_bi,CNR_LC5_L,CNR_LC5_R,\
CNR_LC25_bi,CNR_LC25_L,CNR_LC25_R" > "$output_csv"


# Loop subjects
for sub in $(seq -w 01 44); do

    sub_id="sub-${sub}"
    MT_on="${BIDS_root}/${sub_id}/anat/${sub_id}_acq-LC_mt-on_MTS_N4_centred_normalised.nii.gz"

    if [ ! -f "$MT_on" ]; then
        echo "Missing MT_on for ${sub_id} — skipping"
        continue
    fi

    echo "Processing ${sub_id}"

    matlab -batch "try; \
        [ CNR_LC0_bi,CNR_LC0_L,CNR_LC0_R, CNR_LC5_bi,CNR_LC5_L,CNR_LC5_R, CNR_LC25_bi,CNR_LC25_L,CNR_LC25_R ] = \
        LC_integrity('$MT_on','$LC_atlas_dir'); \
        fid = fopen('$output_csv','a'); \
        fprintf(fid,'%s,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f,%.6f\n', \
            '$sub_id', \
            CNR_LC0_bi,CNR_LC0_L,CNR_LC0_R, \
            CNR_LC5_bi,CNR_LC5_L,CNR_LC5_R, \
            CNR_LC25_bi,CNR_LC25_L,CNR_LC25_R); \
        fclose(fid); \
        catch ME; disp(getReport(ME)); exit(1); end; exit;"

    echo "Finished ${sub_id}"

done

echo "All done."

