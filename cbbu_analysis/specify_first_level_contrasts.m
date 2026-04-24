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

% faces > houses
c = zeros(size(names));
c(contains(names,'faces*bf(1)')) = 1;
c(contains(names,'houses*bf(1)')) = -1;
matlabbatch{1}.spm.stats.con.consess{1}.tcon.name = 'faces>houses';
matlabbatch{1}.spm.stats.con.consess{1}.tcon.weights = c;
matlabbatch{1}.spm.stats.con.consess{1}.tcon.sessrep = 'none';

% houses>faces
c = zeros(size(names));
c(contains(names,'faces*bf(1)')) = -1;
c(contains(names,'houses*bf(1)')) = 1;
matlabbatch{1}.spm.stats.con.consess{2}.tcon.name = 'houses>faces';
matlabbatch{1}.spm.stats.con.consess{2}.tcon.weights = c;
matlabbatch{1}.spm.stats.con.consess{2}.tcon.sessrep = 'none';

% faces>baseline
c = zeros(size(names));
c(contains(names,'faces*bf(1)')) = 1;
matlabbatch{1}.spm.stats.con.consess{3}.tcon.name = 'faces>baseline';
matlabbatch{1}.spm.stats.con.consess{3}.tcon.weights = c;
matlabbatch{1}.spm.stats.con.consess{3}.tcon.sessrep = 'none';

% houses>baseline
c = zeros(size(names));
c(contains(names,'houses*bf(1)')) = 1;
matlabbatch{1}.spm.stats.con.consess{4}.tcon.name = 'houses>baseline';
matlabbatch{1}.spm.stats.con.consess{4}.tcon.weights = c;
matlabbatch{1}.spm.stats.con.consess{4}.tcon.sessrep = 'none';

% save batch
save(output_batch_fname, 'matlabbatch');

% run
if runjob
    spm('Defaults','fMRI');
    spm_jobman('initcfg');
    spm_jobman('run', matlabbatch);
end

