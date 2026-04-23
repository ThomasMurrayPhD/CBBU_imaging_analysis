

GLM_root = 'C:\Users\Tom\Desktop\cbbu_GLM\sub-20\GLM';

% Specify GLM name
glm_name = 'No_parametric_modulators';



% get SPM.mat
SPM = load([GLM_root, '\', glm_name, '\SPM.mat']);
SPM = SPM.SPM;

% regressor names
names = SPM.xX.name;

% faces > houses
c = zeros(size(names));
c(contains(names,'faces*bf(1)')) = 1;
c(contains(names,'houses*bf(1)')) = -1;

spm_contrasts(SPM, c);