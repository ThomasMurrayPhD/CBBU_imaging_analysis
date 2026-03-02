function smooth_images(input_fname, output_fname, kernel)

% check compressed input
if strcmp(input_fname(end-2:end), '.gz')
    compressed_input = true;
    gunzip(input_fname);
    input_fname = input_fname(1:end-3); % .nii
else
    compressed_input = false;
end

% check compressed output
if strcmp(output_fname(end-2:end), '.gz')
    compressed_output = true;
    output_fname = output_fname(1:end-3); %.nii
else
    compressed_output = false;
end

% run smoothing
spm_smooth(input_fname,output_fname,kernel,0)

% re-compress and delete if necessary
if compressed_input
    delete(input_fname); % delete .nii
end

% compress output if necessary
if compressed_output
    gzip(output_fname); % create .nii.gz
    delete(output_fname); % delete .nii
end

end% end function