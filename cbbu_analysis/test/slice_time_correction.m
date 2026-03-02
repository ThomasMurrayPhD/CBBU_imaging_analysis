function slice_time_correction(fname, TR)
% function to run slice time correction on the HPC
% inputs:
%   sub_ID = BIDS ID of sub (number only, as it appears in file (e.g. 05))
%   fname_ = rest of file name
%   TR = TR in ms

disp(['File: ' fname]);

disp('Getting slice times...')
params = spm_jsonread([fname, '.json']);
sts = 1000*params.SliceTiming;

TR = str2double(TR);

reftime = TR/2;
[~,ind] = min(abs(sts - reftime));
nreftime = sts(ind);

if exist([fname, '.nii.gz'], 'file')
    disp('Unzipping nii file...')
    gunzip([fname, '.nii.gz']); % uncompress .gz file
end

disp('Running slice time correction...')
spm_slice_timing([fname, '.nii'], sts, nreftime, [0 TR], 'a_');

end