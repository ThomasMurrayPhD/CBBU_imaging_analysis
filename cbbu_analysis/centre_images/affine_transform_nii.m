function fname_new = affine_transform_nii(mat, nii, suffix)
% script that applies affine transformation too .nii file by adjusting
% header matrix. New .nii file is saved appended with suffix.
% 
% Input:
%   mat     = 4x4 matrix, or .mat file containing 4x4 matrix in
%       'mat' variable. Transformation specified in world space (mm)
%   nii     = file name (including path).
%   suffix  = string to append to file name


% get matrix
if isstring(mat) || ischar(mat)
    mat=importdata(mat);
end

% gunzip if necessary
if strcmp(nii(end-2:end), '.gz')
    compressed_input = true;
    gunzip(nii);
    nii = nii(1:end-3); % remove '.gz'
else
    compressed_input = false;
end

% get image
hdr = spm_vol(nii);

if numel(hdr) == 1
    img = spm_read_vols(hdr);

    % transform
    hdr.mat = mat * hdr.mat;
    
    % write new image
    [path, name, ext] = fileparts(nii);
    fname_new = [path, '/', name, '_', suffix, ext];
    hdr.fname = fname_new;
    spm_write_vol(hdr, img);
else

    [path, name, ext] = fileparts(nii);
    fname_new = [path, '/', name, '_', suffix, ext];

    for i = 1:numel(hdr)
        img = spm_read_vols(hdr(i));
        hdr(i).mat = mat*hdr(i).mat;
        hdr(i).fname = fname_new;
        spm_write_vol(hdr(i), img);
    end
    
end


% print
fprintf('\nWritten new image at:')
fprintf('\n\t%s\n\n', fname_new)

% compress if necessary
if compressed_input
    gzip(fname_new);
    delete(nii); % delete uncompressed input file
    delete(fname_new); % delete uncompressed output file
end

end



