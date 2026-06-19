% script to specify second level for uHGF_3level_parametric_modulators GLM

subs = [1:18, 20:44];

con_0001_scans = arrayfun(@(x) ['F:\cbbu_BIDS\sub-', num2str(x, '%02i'), '\GLM\uHGF_3level_comb_obs2_parametric_modulators\con_0001_normalised.nii,1'], subs, 'UniformOutput', false)';
con_0002_scans = arrayfun(@(x) ['F:\cbbu_BIDS\sub-', num2str(x, '%02i'), '\GLM\uHGF_3level_comb_obs2_parametric_modulators\con_0002_normalised.nii,1'], subs, 'UniformOutput', false)';
con_0003_scans = arrayfun(@(x) ['F:\cbbu_BIDS\sub-', num2str(x, '%02i'), '\GLM\uHGF_3level_comb_obs2_parametric_modulators\con_0003_normalised.nii,1'], subs, 'UniformOutput', false)';
con_0004_scans = arrayfun(@(x) ['F:\cbbu_BIDS\sub-', num2str(x, '%02i'), '\GLM\uHGF_3level_comb_obs2_parametric_modulators\con_0004_normalised.nii,1'], subs, 'UniformOutput', false)';
con_0005_scans = arrayfun(@(x) ['F:\cbbu_BIDS\sub-', num2str(x, '%02i'), '\GLM\uHGF_3level_comb_obs2_parametric_modulators\con_0005_normalised.nii,1'], subs, 'UniformOutput', false)';
con_0006_scans = arrayfun(@(x) ['F:\cbbu_BIDS\sub-', num2str(x, '%02i'), '\GLM\uHGF_3level_comb_obs2_parametric_modulators\con_0006_normalised.nii,1'], subs, 'UniformOutput', false)';

% Need to gunzip them (if necessary)
for i = 1:numel(con_0001_scans)
    fprintf('\n%i/%i...', i, numel(subs));
    gunzip([extractBefore(con_0001_scans{i}, ','), '.gz']);
%     gunzip([extractBefore(con_0002_scans{i}, ','), '.gz']);
%     gunzip([extractBefore(con_0003_scans{i}, ','), '.gz']);
%     gunzip([extractBefore(con_0004_scans{i}, ','), '.gz']);
%     gunzip([extractBefore(con_0005_scans{i}, ','), '.gz']);
%     gunzip([extractBefore(con_0006_scans{i}, ','), '.gz']);
end


% con_0001 - e2
matlabbatch{1}.spm.stats.factorial_design.dir                   = {'F:\cbbu_SPM\uHGF_3level_comb_obs2_parametric_modulators\con_0001'};
matlabbatch{1}.spm.stats.factorial_design.des.t1.scans          = con_0001_scans;
matlabbatch{1}.spm.stats.factorial_design.cov                   = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{1}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.im            = 1;
matlabbatch{1}.spm.stats.factorial_design.masking.em            = {''};
matlabbatch{1}.spm.stats.factorial_design.globalc.g_omit        = 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.gmsca.gmsca_no= 1;
matlabbatch{1}.spm.stats.factorial_design.globalm.glonorm       = 1;

% con_0002 - e3
matlabbatch{2}.spm.stats.factorial_design.dir                   = {'F:\cbbu_SPM\uHGF_3level_comb_obs2_parametric_modulators\con_0002'};
matlabbatch{2}.spm.stats.factorial_design.des.t1.scans          = con_0002_scans;
matlabbatch{2}.spm.stats.factorial_design.cov                   = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{2}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{2}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
matlabbatch{2}.spm.stats.factorial_design.masking.im            = 1;
matlabbatch{2}.spm.stats.factorial_design.masking.em            = {''};
matlabbatch{2}.spm.stats.factorial_design.globalc.g_omit        = 1;
matlabbatch{2}.spm.stats.factorial_design.globalm.gmsca.gmsca_no= 1;
matlabbatch{2}.spm.stats.factorial_design.globalm.glonorm       = 1;

% con_0003 - psi2
matlabbatch{3}.spm.stats.factorial_design.dir                   = {'F:\cbbu_SPM\uHGF_3level_comb_obs2_parametric_modulators\con_0003'};
matlabbatch{3}.spm.stats.factorial_design.des.t1.scans          = con_0003_scans;
matlabbatch{3}.spm.stats.factorial_design.cov                   = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{3}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{3}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
matlabbatch{3}.spm.stats.factorial_design.masking.im            = 1;
matlabbatch{3}.spm.stats.factorial_design.masking.em            = {''};
matlabbatch{3}.spm.stats.factorial_design.globalc.g_omit        = 1;
matlabbatch{3}.spm.stats.factorial_design.globalm.gmsca.gmsca_no= 1;
matlabbatch{3}.spm.stats.factorial_design.globalm.glonorm       = 1;

% con_0004 - psi3
matlabbatch{4}.spm.stats.factorial_design.dir                   = {'F:\cbbu_SPM\uHGF_3level_comb_obs2_parametric_modulators\con_0004'};
matlabbatch{4}.spm.stats.factorial_design.des.t1.scans          = con_0004_scans;
matlabbatch{4}.spm.stats.factorial_design.cov                   = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{4}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{4}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
matlabbatch{4}.spm.stats.factorial_design.masking.im            = 1;
matlabbatch{4}.spm.stats.factorial_design.masking.em            = {''};
matlabbatch{4}.spm.stats.factorial_design.globalc.g_omit        = 1;
matlabbatch{4}.spm.stats.factorial_design.globalm.gmsca.gmsca_no= 1;
matlabbatch{4}.spm.stats.factorial_design.globalm.glonorm       = 1;

% con_0005 - mu3
matlabbatch{5}.spm.stats.factorial_design.dir                   = {'F:\cbbu_SPM\uHGF_3level_comb_obs2_parametric_modulators\con_0005'};
matlabbatch{5}.spm.stats.factorial_design.des.t1.scans          = con_0005_scans;
matlabbatch{5}.spm.stats.factorial_design.cov                   = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{5}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{5}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
matlabbatch{5}.spm.stats.factorial_design.masking.im            = 1;
matlabbatch{5}.spm.stats.factorial_design.masking.em            = {''};
matlabbatch{5}.spm.stats.factorial_design.globalc.g_omit        = 1;
matlabbatch{5}.spm.stats.factorial_design.globalm.gmsca.gmsca_no= 1;
matlabbatch{5}.spm.stats.factorial_design.globalm.glonorm       = 1;

% con_0006 - ech
matlabbatch{6}.spm.stats.factorial_design.dir                   = {'F:\cbbu_SPM\uHGF_3level_comb_obs2_parametric_modulators\con_0006'};
matlabbatch{6}.spm.stats.factorial_design.des.t1.scans          = con_0006_scans;
matlabbatch{6}.spm.stats.factorial_design.cov                   = struct('c', {}, 'cname', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{6}.spm.stats.factorial_design.multi_cov             = struct('files', {}, 'iCFI', {}, 'iCC', {});
matlabbatch{6}.spm.stats.factorial_design.masking.tm.tm_none    = 1;
matlabbatch{6}.spm.stats.factorial_design.masking.im            = 1;
matlabbatch{6}.spm.stats.factorial_design.masking.em            = {''};
matlabbatch{6}.spm.stats.factorial_design.globalc.g_omit        = 1;
matlabbatch{6}.spm.stats.factorial_design.globalm.gmsca.gmsca_no= 1;
matlabbatch{6}.spm.stats.factorial_design.globalm.glonorm       = 1;

save('uHGF_3level_comb_obs2_parametric_modulators_batch.mat', 'matlabbatch');
