% script to specify second level contrasts for No_parametric_modulators glm

subs = [1:18, 20:44];

con_0001_scans = arrayfun(@(x) ['F:\cbbu_BIDS\sub-', num2str(x, '%02i'), '\GLM\No_parametric_modulators\con_0001_normalised.nii,1'], subs, 'UniformOutput', false)';
con_0002_scans = arrayfun(@(x) ['F:\cbbu_BIDS\sub-', num2str(x, '%02i'), '\GLM\No_parametric_modulators\con_0002_normalised.nii,1'], subs, 'UniformOutput', false)';
con_0003_scans = arrayfun(@(x) ['F:\cbbu_BIDS\sub-', num2str(x, '%02i'), '\GLM\No_parametric_modulators\con_0003_normalised.nii,1'], subs, 'UniformOutput', false)';
con_0004_scans = arrayfun(@(x) ['F:\cbbu_BIDS\sub-', num2str(x, '%02i'), '\GLM\No_parametric_modulators\con_0004_normalised.nii,1'], subs, 'UniformOutput', false)';

% Need to gunzip them (if necessary)
% for i = 1:numel(con_0001_scans)
%     fprintf('\n%i/%i...', i, numel(subs));
%     gunzip([extractBefore(con_0001_scans{i}, ','), '.gz']);
%     gunzip([extractBefore(con_0002_scans{i}, ','), '.gz']);
%     gunzip([extractBefore(con_0003_scans{i}, ','), '.gz']);
%     gunzip([extractBefore(con_0004_scans{i}, ','), '.gz']);
% end


% con_0001 - faces>houses
matlabbatch{1}.spm.stats.factorial_design.dir                   = {'F:\cbbu_SPM\No_parametric_modulators\con_0001'};
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans          = con_0001_scans;
matlabbatch{1}.spm.stats.factorial_design.cov                   = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im            = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em            = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit        = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no= 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm       = 1;

% con_0002 - houses>faces
matlabbatch{2}.spm.stats.factorial_design.dir                   = {'F:\cbbu_SPM\No_parametric_modulators\con_0002'};
matlabbatch{2}.spm.stats.factorial_design.des.t1.scans          = con_0002_scans;
matlabbatch{2}.spm.stats.factorial_design.cov                   = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{2}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{2}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
matlabbatch{2}.spm.stats.factorial_design.masking.im            = 1;
matlabbatch{2}.spm.stats.factorial_design.masking.em            = {''};
matlabbatch{2}.spm.stats.factorial_design.globalc.g_omit        = 1;
matlabbatch{2}.spm.stats.factorial_design.globalm.gmsca.gmsca_no= 1;
matlabbatch{2}.spm.stats.factorial_design.globalm.glonorm       = 1;

% con_0003 - faces>baseline
matlabbatch{3}.spm.stats.factorial_design.dir                   = {'F:\cbbu_SPM\No_parametric_modulators\con_0003'};
matlabbatch{3}.spm.stats.factorial_design.des.t1.scans          = con_0003_scans;
matlabbatch{3}.spm.stats.factorial_design.cov                   = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{3}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{3}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
matlabbatch{3}.spm.stats.factorial_design.masking.im            = 1;
matlabbatch{3}.spm.stats.factorial_design.masking.em            = {''};
matlabbatch{3}.spm.stats.factorial_design.globalc.g_omit        = 1;
matlabbatch{3}.spm.stats.factorial_design.globalm.gmsca.gmsca_no= 1;
matlabbatch{3}.spm.stats.factorial_design.globalm.glonorm       = 1;

% con_0004 - houses>baseline
matlabbatch{4}.spm.stats.factorial_design.dir                   = {'F:\cbbu_SPM\No_parametric_modulators\con_0004'};
matlabbatch{4}.spm.stats.factorial_design.des.t1.scans          = con_0004_scans;
matlabbatch{4}.spm.stats.factorial_design.cov                   = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{4}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{4}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
matlabbatch{4}.spm.stats.factorial_design.masking.im            = 1;
matlabbatch{4}.spm.stats.factorial_design.masking.em            = {''};
matlabbatch{4}.spm.stats.factorial_design.globalc.g_omit        = 1;
matlabbatch{4}.spm.stats.factorial_design.globalm.gmsca.gmsca_no= 1;
matlabbatch{4}.spm.stats.factorial_design.globalm.glonorm       = 1;

save('no_parametric_modulators_batch.mat', 'matlabbatch');
