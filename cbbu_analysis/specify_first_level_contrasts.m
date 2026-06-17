function specify_first_level_contrasts(GLM_root, output_batch_fname)
% function to specify and run first level contrasts. Need to specify
% vectors within this function
% 
% GLM_root = 'C:\Users\Tom\Desktop\cbbu_GLM\sub-20\GLM';
% glm_name = 'No_parametric_modulators';


% get SPM.mat
spmmat = [GLM_root, '\SPM.mat'];
SPM = load(spmmat);
SPM = SPM.SPM;

% regressor names
names = SPM.xX.name;

% Specify spm.mat
matlabbatch{1}.spm.stats.con.spmmat = {spmmat};

% e2
c = zeros(size(names));
c(contains(names,'facesxe2^1*bf(1)')) = 1;
c(contains(names,'housesxe2^1*bf(1)')) = 1;
matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'e2>baseline';
matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = c;
matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';
matlabbatch{1}.spm.stats.con.delete = 1;

% % e3
% c = zeros(size(names));
% c(contains(names,'facesxe3^1*bf(1)')) = 1;
% c(contains(names,'housesxe3^1*bf(1)')) = 1;
% matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'e3>baseline';
% matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = c;
% matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
% matlabbatch{1}.spm.stats.con.delete = 1;

% psi2
c = zeros(size(names));
c(contains(names,'facesxpsi2^1*bf(1)')) = 1;
c(contains(names,'housesxpsi2^1*bf(1)')) = 1;
matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'psi2>baseline';
matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = c;
matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = 'none';
matlabbatch{1}.spm.stats.con.delete = 1;

% % psi3
% c = zeros(size(names));
% c(contains(names,'facesxpsi3^1*bf(1)')) = 1;
% c(contains(names,'housesxpsi3^1*bf(1)')) = 1;
% matlabbatch{1}.spm.stats.con.consess{4}.tcon.name = 'psi3>baseline';
% matlabbatch{1}.spm.stats.con.consess{4}.tcon.weights = c;
% matlabbatch{1}.spm.stats.con.consess{4}.tcon.sessrep = 'none';
% matlabbatch{1}.spm.stats.con.delete = 1;
% 
% % mu3
% c = zeros(size(names));
% c(contains(names,'facesxmu3^1*bf(1)')) = 1;
% c(contains(names,'housesxmu3^1*bf(1)')) = 1;
% matlabbatch{1}.spm.stats.con.consess{5}.tcon.name = 'mu3>baseline';
% matlabbatch{1}.spm.stats.con.consess{5}.tcon.weights = c;
% matlabbatch{1}.spm.stats.con.consess{5}.tcon.sessrep = 'none';
% matlabbatch{1}.spm.stats.con.delete = 1;

% ech
c = zeros(size(names));
c(contains(names,'facesxech^1*bf(1)')) = 1;
c(contains(names,'housesxech^1*bf(1)')) = 1;
matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = 'ech>baseline';
matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = c;
matlabbatch{1}.spm.stats.con.consess{3}.tcon.sessrep = 'none';
matlabbatch{1}.spm.stats.con.delete = 1;

% save batch
save(output_batch_fname, 'matlabbatch');

% run
spm('Defaults','fMRI');
spm_jobman('initcfg');
spm_jobman('run', matlabbatch);


