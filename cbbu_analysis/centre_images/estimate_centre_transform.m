function estimate_centre_transform(vol, modality, output_mat)
% script to set origin to centre of intensity and coregister with MNI
% 
% input:
%   vols (file name of volume with path). At the moment it only works on
%       single volume (e.g. not 4D EPI sequence)
%   modality ('T1', 'T2', or 'EPI')
%   output_mat (file name and path for output matrix)

spm('Defaults', 'FMRI');
spm_jobman('initcfg');

% gunzip if necessary
if strcmp(vol(end-2:end), '.gz')
    compressed_input = true;
    gunzip(vol);
    vol = vol(1:end-3); % remove '.gz'
else
    compressed_input = false;
end

% read hdr and img
hdr_original = spm_vol(vol);
img = spm_read_vols(hdr_original);

% get voxel index grid
[xs, ys, zs] = ndgrid(1:size(img,1), 1:size(img,2), 1:size(img,3));

% find centre of intensity (as voxel index)
Y = img - min(img(:));
Y(isnan(Y)) = 0;
sumI = sum(Y(:));
coivox = [
    sum(xs(:) .* Y(:)) / sumI;
    sum(ys(:) .* Y(:)) / sumI;
    sum(zs(:) .* Y(:)) / sumI;
    1];

% convert to world coords
world_centre = hdr_original.mat * coivox;

% get translation matrix (move origin)
centre_shift_world = eye(4);
centre_shift_world(1:3, 4) = -world_centre(1:3);

% load target header
if strcmp(modality, 'T1')
    target = fullfile(spm('Dir'),'canonical','avg152T1.nii');
elseif strcmp(modality, 'T2')
    target = fullfile(spm('Dir'),'canonical','avg152T2.nii');
elseif strcmp(modality, 'EPI')
    target  = fullfile(spm('Dir'),'toolbox','OldNorm','EPI.nii');
end
target_hdr = spm_vol(target);  % MNI template

% set coregistration settings
coreg_params.sep = [4 2];
coreg_params.cost_fun = 'nmi';
coreg_params.tol = [0.02 0.02 0.02 0.001 0.001 0.001 0.01 0.01 0.01 0.001 0.001 0.001];
coreg_params.fwhm = [7 7];

% Run rigid body coregistration
hdr_set_origin = hdr_original;
hdr_set_origin.mat = centre_shift_world*hdr_set_origin.mat;
x = spm_coreg(target_hdr, hdr_set_origin, coreg_params);

% final transformation matrix (world space)
mat = inv(spm_matrix(x)) * centre_shift_world;

% save matrix
save(output_mat, 'mat');


% recompress if necessary
if compressed_input
    delete(vol); % delete uncompressed input file (we uncompressed it)
end

end