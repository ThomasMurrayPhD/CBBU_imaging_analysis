% script to compute pattern similarity of outcome categories in searchlight
% analysis.
% 
% 4 metrics are computed, for each trial:
%   F_between:  dissimilarity of representation of this FACE trial to average representation of all HOUSE trials
%   F_within:   dissimilarity of representation of this FACE trial to LOO-average of other FACE trials
%   H_between:  dissimilarity of representation of this HOUSE trial to average representation of all FACE trials
%   H_within:   dissimilarity of representation of this HOUSE trial to LOO-average of other HOUSE trials
% 
% These metrics are computed using a 5mm spherical searchlight.


BIDS_root = 'F:\cbbu_BIDS\';
subs = [1:18, 20:44];

fprintf('\n---Correlation distances between outcomes via searchlight---');


% Define searchlight
searchlightRad_mm = 5;
voxSize_mm = [1,1,1];

% from RSA toolbox
rad_vox=searchlightRad_mm./voxSize_mm;
minMargin_vox=floor(rad_vox);
[x,y,z]=meshgrid(-minMargin_vox(1):minMargin_vox(1), -minMargin_vox(2):minMargin_vox(2), -minMargin_vox(3):minMargin_vox(3));
sphere=((x*voxSize_mm(1)).^2+(y*voxSize_mm(2)).^2+(z*voxSize_mm(3)).^2)<=(searchlightRad_mm^2);

% Percentage completion at which to print progress
print_step = 1;

% for each sub
for iSub = 1%subs
    
    fprintf('\n\tSub: %i', iSub);

    % load the mask
    mask = spm_read_vols(spm_vol([BIDS_root, 'sub-', num2str(iSub, '%02i'), '\GLM\No_parametric_modulators\mask.nii']));

    % pad the mask
    mask_padded = padarray(mask, [minMargin_vox, 0]);

    % idx of positive mask values
    [xm,ym,zm] = ind2sub(size(mask_padded), find(mask_padded(:)>0));
    mask_idx_xyz = [xm, ym, zm];
    
    % number of voxels in mask
    nVox = size(mask_idx_xyz,1);

    % initialise (empty) mask for searchlight
    searchlight_mask_init = zeros(size(mask_padded));

    % for each run
    for iRun = 1:2
        fprintf('\n\t\tRun: %i', iRun);

        % load the data
        fprintf('\n\t\t\tLoading data...');
        multitrial_glm_fname = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\GLM\multitrial\betas_run', num2str(iRun), '.mat'];
        multitrial_glm_data = load(multitrial_glm_fname);
        F_betas = multitrial_glm_data.betas{1};
        H_betas = multitrial_glm_data.betas{2};


        % pad the betas
        F_betas_padded = padarray(F_betas, [minMargin_vox, 0]);
        H_betas_padded = padarray(H_betas, [minMargin_vox, 0]);

        % vectorise - reshapes to nVox * nTrials
        F_betas_padded_v = reshape(F_betas_padded, [], size(F_betas_padded,4));
        H_betas_padded_v = reshape(H_betas_padded, [], size(H_betas_padded,4));

        % preallocate space for similarity metrics
        [F_within, F_between] = deal(zeros(size(F_betas), 'single'));
        [H_within, H_between] = deal(zeros(size(H_betas), 'single'));


        % for each voxel within mask
        fprintf('\n\t\t\tRunning searchlight...');
        
        % Initialise progress timer
        progress_tic = tic;
        next_print = print_step;
        for iVox = 1:nVox
            
            % Print progress and estimated completion time
            progress = 100 * iVox / nVox;
            if progress >= next_print || iVox == nVox
                elapsed_time = toc(progress_tic);
                estimated_total_time = elapsed_time / (iVox / nVox); % Estimate total time based on current processing rate
                estimated_remaining_time = estimated_total_time - elapsed_time; % Estimate remaining time
                estimated_finish = datetime('now') + seconds(estimated_remaining_time); % Estimated clock time at completion
                fprintf(['\n\t\t\t\t%5.1f%% (%d/%d voxels) | ' ...
                         'Elapsed: %s | Remaining: %s | ETA: %s'], ...
                         progress, iVox, nVox, ...
                         format_time(elapsed_time), ...
                         format_time(estimated_remaining_time), ...
                         datestr(estimated_finish, 'HH:MM:SS'));
                next_print = next_print + print_step;
            end

            % place sphere on this voxel
            iVox_xyz = mask_idx_xyz(iVox, :);
            searchlight_mask_iVox = logical(searchlight_mask_init);
            searchlight_mask_iVox(...
                iVox_xyz(1)-minMargin_vox(1):iVox_xyz(1)+minMargin_vox(1),...
                iVox_xyz(2)-minMargin_vox(2):iVox_xyz(2)+minMargin_vox(2),...
                iVox_xyz(3)-minMargin_vox(3):iVox_xyz(3)+minMargin_vox(3)) = sphere;

            % multiply with main mask to exclude voxels outside brain AND searchlight
            searchlight_mask_iVox = logical(searchlight_mask_iVox .* mask_padded);
            
            % only if at least 5 voxels contribute to searchlight
            if nnz(searchlight_mask_iVox) > 5

                % Extract searchlight data
                % Rows = voxels, columns = trials
                F = F_betas_padded_v(searchlight_mask_iVox(:), :);
                H = H_betas_padded_v(searchlight_mask_iVox(:), :);


                % F patterns
                nF = size(F, 2); % Number of F trials
                F_c = F - mean(F, 1); % Centre each trial across voxels
                F_norm = sqrt(sum(F_c.^2, 1)); % Norm of each centred F pattern
                F_c_sum = sum(F_c, 2); % Sum of centred F patterns

                F_mean = mean(F, 2); % Mean F pattern
                F_mean_c = F_mean - mean(F_mean); % Centre F mean across voxels
                F_mean_norm = sqrt(sum(F_mean_c.^2)); % Norm of F mean

                % H patterns
                nH = size(H, 2); % Number of H trials
                H_c = H - mean(H, 1); % Centre each trial across voxels 
                H_norm = sqrt(sum(H_c.^2, 1)); % Norm of each centred H pattern
                H_c_sum = sum(H_c, 2); % Sum of centred H patterns


                H_mean = mean(H, 2); % Mean H pattern
                H_mean_c = H_mean - mean(H_mean); % Centre H mean across voxels 
                H_mean_norm = sqrt(sum(H_mean_c.^2)); % Norm of H mean


                % ---- F WITHIN ----
                F_loo_c = (F_c_sum - F_c) / (nF - 1); % Leave-one-out mean for each F trial.
                F_loo_norm = sqrt(sum(F_loo_c.^2, 1)); % Norm of each leave-one-out mean pattern
                F_within_r = sum(F_c .* F_loo_c, 1) ./ (F_norm .* F_loo_norm); % Correlation between each F trial and its leave-one-out mean
                F_within_i = 1 - F_within_r; % Pearson distance


                % ---- F BETWEEN ----
                F_between_r = (F_c' * H_mean_c) ./ (F_norm' * H_mean_norm); % Correlation between every F trial and H mean
                F_between_i = 1 - F_between_r; % Pearson distance

                % ---- H WITHIN ----
                H_loo_c = (H_c_sum - H_c) / (nH - 1); % Leave-one-out mean for each H trial
                H_loo_norm = sqrt(sum(H_loo_c.^2, 1)); % Norm of each leave-one-out mean pattern
                H_within_r = sum(H_c .* H_loo_c, 1) ./ (H_norm .* H_loo_norm); % Correlation between each H trial and its leave-one-out mean
                H_within_i = 1 - H_within_r; % Pearson distance


                % ---- H BETWEEN ----
                H_between_r = (H_c' * F_mean_c) ./ (H_norm' * F_mean_norm); % Correlation between every H trial and F mean
                H_between_i = 1 - H_between_r; % Pearson distance


                % Store results
                F_within(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), :)  = F_within_i;
                F_between(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), :) = F_between_i;
                H_within(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), :)  = H_within_i;
                H_between(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), :) = H_between_i;
            
            else %if <5 voxels
                F_within(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), :)  = 0;
                F_between(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), :) = 0;
                H_within(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), :)  = 0;
                H_between(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), :) = 0;
                
            end%if nnz

        end%vox

        % unpad the arrays
        unpad = @(x) x(...
            minMargin_vox(1)+1:end-minMargin_vox(1), ...
            minMargin_vox(2)+1:end-minMargin_vox(2), ...
            minMargin_vox(3)+1:end-minMargin_vox(3), ...
            :);

        F_within  = unpad(F_within);
        F_between = unpad(F_between);
        H_within  = unpad(H_within);
        H_between = unpad(H_between);

        % Save
        output_dir = [BIDS_root, 'sub-', num2str(iSub, '%02i'), '\GLM\multitrial'];
        save([output_dir, '\pearson_distance_run', num2str(iRun), '.mat'], 'F_within', 'F_between', 'H_within', 'H_between', 'searchlightRad_mm', '-v7.3');

    end%run

end%sub


% function for printing progress
function str = format_time(seconds)
    if seconds < 60
        str = sprintf('%.0fs', seconds);
    elseif seconds < 3600
        str = sprintf('%.1fm', seconds / 60);
    else
        str = sprintf('%.1fh', seconds / 3600);
    end
end



%% Old code
% The 'manual' way of running this in a loop. Kept here to demonstrate the
% logic...
% 
% %% Old way of running loop
% 
% tic;
% 
% % preallocate space for similarity metrics
% [F_within, F_between, H_within, H_between] = deal(zeros(size(F_betas), 'single'));
% 
% % for each voxel within mask
% for iVox = 1:size(mask_idx_xyz,1)
% 
%     % place sphere on this voxel
%     iVox_xyz = mask_idx_xyz(iVox, :);
%     searchlight_mask_iVox = logical(searchlight_mask_init);
%     searchlight_mask_iVox(...
%         iVox_xyz(1)-minMargin_vox(1):iVox_xyz(1)+minMargin_vox(1),...
%         iVox_xyz(2)-minMargin_vox(2):iVox_xyz(2)+minMargin_vox(2),...
%         iVox_xyz(3)-minMargin_vox(3):iVox_xyz(3)+minMargin_vox(3)) = sphere;
% 
% 
%     % multiply with main mask to exclude voxels outside brain AND searchlight
%     searchlight_mask_iVox = logical(searchlight_mask_iVox .* mask_padded);
% 
%     % extract voxels across trials (nVox x nTrials)
%     F_betas_searchlight = F_betas_padded_v(searchlight_mask_iVox(:), :);
%     H_betas_searchlight = H_betas_padded_v(searchlight_mask_iVox(:), :);
% 
% 
%     % find means
%     F_mean = mean(F_betas_searchlight, 2);
%     H_mean = mean(H_betas_searchlight, 2);
% 
%     % For each face trial
%     for iT = 1:size(F_betas,4)
%         i_F = F_betas_searchlight(:,iT);
% 
%         % average of all F excluding this one
%         i_F_mean = mean(F_betas_searchlight(:,[1:iT-1, iT+1:size(F_betas,4)]), 2);
% 
%         % Calculate correlation distance and add to array
%         F_between(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), iT) = 1 - corr(i_F, H_mean);
%         F_within(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), iT) = 1 - corr(i_F, i_F_mean);
%     end
% 
%     % For each house trial
%     for iT = 1:size(H_betas,4)
%         i_H = H_betas_searchlight(:,iT);
% 
%         % average of all F excluding this one
%         i_H_mean = mean(H_betas_searchlight(:,[1:iT-1, iT+1:size(H_betas,4)]), 2);
% 
%         % Calculate correlation distance and add to array
%         H_between(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), iT) = 1 - corr(i_H, F_mean);
%         H_within(iVox_xyz(1), iVox_xyz(2), iVox_xyz(3), iT) = 1 - corr(i_H, i_H_mean);
%     end
% 
% 
% end
% 
% loop_secs = toc;


