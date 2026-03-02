# -*- coding: utf-8 -*-
"""
Script to loop through functional files (in BIDS directory) and get relevant 
physio file (from dicom directory)

Created on Thu Jan 25 15:09:30 2024

@author: Tom
"""

import os
import glob
import json
import argparse
from bidsphysio.dcm2bids import dcm2bidsphysio



def convert_physio(sub_path, dicom_path):
    
    d_list = glob.glob(dicom_path + '/*.dcm')
    _, d_name = os.path.split(d_list[0])
    scanID = d_name.split('_')[0]
    sub_ID = sub_path.split('/')[-1]
    
    # loop through task files in BIDS structure
    for task in ['facehouse', 'rest']:
        f_list = glob.glob(sub_path + '/func/' + sub_ID + '_task-' + task + '*bold.json')
        for f_name in f_list:
            
            if 'dir-PA' in f_name: # if it's an actual run and not the inverse phase encoded
                # Get BIDS prefix (inc path)
                BIDS_prefix = '_'.join(f_name.split('_')[:-1])
                
                # open json file
                with open(f_name, 'r') as f:
                    j_dict = json.load(f)
                
                # Identify series number of physio files
                physio_series_number = j_dict['SeriesNumber'] + 1 # physio is always + 1
                
                # Get physio dicom name
                dcm_f_name = glob.glob(
                    dicom_path + '/' + scanID + '_' + f'{physio_series_number:04}*.dcm')[0]
                
                # convert
                physio_data = dcm2bidsphysio.dcm2bids(dcm_f_name, BIDS_prefix)
                
                # save
                physio_data.save_to_bids_with_trigger(BIDS_prefix)


# Parse input
parser = argparse.ArgumentParser(
    prog = 'Convert physio dicoms')
parser.add_argument('-p', '-subID', help="Path to BIDS subject ID", type=str)
parser.add_argument('-d', '-dicomDir', help='Path to directory containing dicoms for this subject', type=str)
args = parser.parse_args()


# convert and save
convert_physio(args.p, args.d)




