% script to get task data

root = 'C:\Users\Tom\OneDrive - University of Cambridge\Cambridge\CBBU\DATA\';
for i = 95:99
    d = dir([root, '\sub-', num2str(i, '%02i'), '\task_fmri\*.mat']);
    mkdir(['sub-', num2str(i, '%02i')]);
    for k = 1:numel(d)
        copyfile(fullfile(d(k).folder, d(k).name), [pwd, '\', 'sub-', num2str(i, '%02i')]);
    end
end