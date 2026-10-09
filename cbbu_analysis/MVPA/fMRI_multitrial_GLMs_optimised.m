function [Beta,res,Z] = fMRI_multitrial_GLMs_optimised(S)
%
% High-resolution version of fMRI_multitrial_GLMs
%
% Based on Rik Henson's original script:
% https://github.com/MRC-CBU/riksneurotools/blob/master/GLM/fMRI_multitrial_GLMs.m
%
% Matlab function to return single-trial Betas from GLM using LSA, LSS
% or L2-regularised LSA fit to fMRI timeseries from a scan x ROI/voxel
% data matrix, given onsets and durations of events.
%
% This version is designed for high-resolution fMRI data with potentially
% hundreds of thousands of voxels.
%
% IMPORTANT:
%   - Data and large GLM matrices are handled in single precision.
%   - Voxels are processed in batches to avoid large temporary arrays.
%   - Residuals are NOT calculated or stored.
%
% Inputs (fields of structure S):
%
%    Required:
%           S.d = Ns scan x Nr ROI (or Nr voxels) matrix of fMRI data
%           S.events = cell array of event onsets and durations
%
%    Optional:
%           S.method = 'LSU', 'LSA' or 'LSS'
%                      default = 'LSA'
%           S.lambda = regularisation parameter
%                      default = 0
%           S.XC = confounding regressors
%           S.coi = conditions of interest
%           S.TR = TR
%                      default = 2
%           S.units = 'secs' or 'scans'
%                      default = 'secs'
%           S.T = microtime resolution
%                      default = 16
%           S.T0 = reference timebin
%                      default = round(T/2)
%           S.bf = HRF basis functions
%                      default = SPM canonical HRF
%           S.HC = highpass cutoff
%                      default = 128
%           S.zflag = whether to Z-score regressors
%                      default = 0
%           S.voxel_batch_size = number of voxels processed at once
%                      default = 10000
%
% Outputs:
%
%    Beta = Cell array containing trial-by-voxel parameter estimates
%           for each condition of interest.
%
%    res  = Empty. Residuals are not calculated/stored in this version.
%
%    Z    = Design matrix from the final GLM. For LSS this corresponds
%           to the final trial fitted.
%

%% ------------------------------------------------------------------------
%  Get data
%  ------------------------------------------------------------------------

try
    d = S.d;
catch
    error('Please provide ROI fMRI data in S.d')
end

% Ensure fMRI data are single precision.
% This is particularly important for high-resolution data.
if ~isa(d,'single')
    d = single(d);
end

Ns = size(d,1);
Nr = size(d,2);

if Ns <= 1
    error('Need at least 2 scans (rows of S.d)');
end


%% ------------------------------------------------------------------------
%  Voxel batch size
%  ------------------------------------------------------------------------

try
    voxel_batch_size = S.voxel_batch_size;
catch
    voxel_batch_size = 10000;
end

if voxel_batch_size < 1 || ~isscalar(voxel_batch_size)
    error('S.voxel_batch_size must be a positive scalar');
end

voxel_batch_size = round(voxel_batch_size);


%% ------------------------------------------------------------------------
%  TR
%  ------------------------------------------------------------------------

try
    TR = S.TR;
catch
    TR = 2;
end


%% ------------------------------------------------------------------------
%  Events
%  ------------------------------------------------------------------------

try
    events = S.events;
catch
    error('Please provide SPM event-structure in S.events');
end


%% ------------------------------------------------------------------------
%  Units
%  ------------------------------------------------------------------------

try
    units = S.units;
catch
    warning('Assuming units are seconds');
    units = 'secs';
end


%% ------------------------------------------------------------------------
%  Microtime resolution
%  ------------------------------------------------------------------------

try
    T = S.T;
catch
    T = 16;
end

dt = TR/T;


if strcmp(units,'secs')
    st = T/TR;
elseif strcmp(units,'scans')
    st = T;
else
    error('Units must be secs or scans');
end

Nt = Ns*T;


%% ------------------------------------------------------------------------
%  Reference time bin
%  ------------------------------------------------------------------------

try
    T0 = S.T0;
catch
    warning('Synchronising events with middle of scan');
    T0 = round(T/2);
end

if T0 < 1 || T0 > T
    error('T0 %d must lie between 1 and T %d',T0,T);
end


%% ------------------------------------------------------------------------
%  Event information
%  ------------------------------------------------------------------------

sots = events.ons;
Nj = length(sots);

if Nj < 1
    error('Need at least 1 trial-type');
end


%% ------------------------------------------------------------------------
%  Conditions of interest
%  ------------------------------------------------------------------------

try
    coi = S.coi;
catch
    coi = 1:Nj;
end

Ncoi = length(coi);


%% ------------------------------------------------------------------------
%  Durations
%  ------------------------------------------------------------------------

try
    durs = S.events.dur;
catch

    durs = cell(1,Nj);

    for j = 1:Nj
        durs{j} = zeros(1,length(sots{j}));
    end

end


%% ------------------------------------------------------------------------
%  Basis functions
%  ------------------------------------------------------------------------

try
    bf = S.bf;
catch
    bf = 'hrf';
end


if ischar(bf) || isstring(bf)

    xBF.dt     = dt;
    xBF.name   = bf;
    xBF.length = 30;
    xBF.order  = round(30/TR);

    bf = spm_get_bf(xBF);
    bf = bf.bf;

    bf = bf/max(bf(:));

end

% Convert basis functions to single precision
bf = single(bf);

Nk = size(bf,2);


%% ------------------------------------------------------------------------
%  High-pass filter
%  ------------------------------------------------------------------------

try
    HC = S.HC;
catch
    HC = 128;
end


if HC > 0

    HO = fix(2*(Ns*TR)/HC+1);

    % SPM returns double precision; convert to single afterwards
    K = single(spm_dctmtx(Ns,HO));

else

    K = zeros(Ns,0,'single');

end


%% ------------------------------------------------------------------------
%  Confound regressors
%  ------------------------------------------------------------------------

try
    XC = S.XC;

    if ~isempty(XC) && ~isa(XC,'single')
        XC = single(XC);
    end

catch
    XC = zeros(Ns,0,'single');
end


%% ------------------------------------------------------------------------
%  Method
%  ------------------------------------------------------------------------

try
    meth = S.method;
catch
    meth = 'LSA';
end


if strcmp(meth,'LSS') && Nk > 1
    error('Not implemented LSS yet for more than 1 basis function');
end


%% ------------------------------------------------------------------------
%  Regularisation
%  ------------------------------------------------------------------------

try
    lambda = S.lambda;
catch
    lambda = 0;
end


%% ------------------------------------------------------------------------
%  Z-scoring
%  ------------------------------------------------------------------------

try
    zflag = S.zflag;
catch
    zflag = 0;
end


%% ------------------------------------------------------------------------
%  General setup
%  ------------------------------------------------------------------------

% Scan reference points in microtime space
s = T0:T:Nt;

% Number of voxels
Nr = size(d,2);

% Number of voxel batches
nBatches = ceil(Nr/voxel_batch_size);

fprintf('\nGLM: %d scans x %d voxels',Ns,Nr);
fprintf('\nVoxel batch size: %d (%d batches)',voxel_batch_size,nBatches);


%% =========================================================================
%  LSU
%  =========================================================================

switch meth

    case 'LSU'

        %% Preallocate design matrices

        nX  = sum(cellfun(@numel,sots(coi))) * Nk;

        nonCoi = setdiff(1:Nj,coi);

        nX0 = sum(cellfun(@numel,sots(nonCoi))) * Nk;

        X  = zeros(Ns,nX,'single');
        X0 = zeros(Ns,nX0,'single');

        xCount  = 0;
        x0Count = 0;


        %% Build design matrix

        for j = 1:Nj

            u = zeros(Nt,1,'single');

            Ni = length(sots{j});

            for i = 1:Ni

                t1 = round(sots{j}(i)*st) + 1;
                t2 = t1 + round(durs{j}(i)*st);

                u(t1:t2) = 1;

            end


            for k = 1:Nk

                b = conv(u,bf(:,k));

                b = b(s);

                if ismember(j,coi)

                    xCount = xCount + 1;
                    X(:,xCount) = b;

                else

                    x0Count = x0Count + 1;
                    X0(:,x0Count) = b;

                end

            end

        end


        %% Full design matrix

        Z = [X X0 XC K];

        if zflag
            Z = single(zscore(Z));
        end


        %% Estimate GLM

        Nji = length(coi)*Nk;

        if lambda == 0

            pX = pinv(Z);

        else

            Np = size(Z,2);

            R = zeros(Np,Np,'single');
            R(1:Nji,1:Nji) = eye(Nji,'single');

            pX = (Z'*Z + single(lambda)*R)\Z';

        end


        %% Allocate output

        Beta = cell(Nji,1);


        for j = 1:Nji
            Beta{j} = zeros(1,Nr,'single');
        end


        %% Process voxels in batches

        for bIdx = 1:nBatches

            firstVoxel = (bIdx-1)*voxel_batch_size + 1;
            lastVoxel  = min(bIdx*voxel_batch_size,Nr);

            voxelIdx = firstVoxel:lastVoxel;

            fprintf('\n\tBatch %d/%d: voxels %d-%d', ...
                bIdx,nBatches,firstVoxel,lastVoxel);

            B = pX*d(:,voxelIdx);


            for j = 1:Nji
                Beta{j}(voxelIdx) = B(j,:);
            end

        end


        % Residuals deliberately not calculated
        res = [];


    %% =========================================================================
    %  LSA
    %  =========================================================================

    case 'LSA'

        %% Preallocate design matrices

        nX = sum(cellfun(@numel,sots(coi))) * Nk;

        nonCoi = setdiff(1:Nj,coi);

        nX0 = sum(cellfun(@numel,sots(nonCoi))) * Nk;

        X  = zeros(Ns,nX,'single');
        X0 = zeros(Ns,nX0,'single');

        ri = cell(Ncoi,1);

        lastri = 0;

        xCount  = 0;
        x0Count = 0;


        %% Build design matrix

        for j = 1:Nj

            coiIdx = find(coi == j,1);

            if ~isempty(coiIdx)

                Ni = length(sots{j});

                u = zeros(Nt,Ni,'single');

                for i = 1:Ni

                    t1 = round(sots{j}(i)*st) + 1;
                    t2 = t1 + round(durs{j}(i)*st);

                    u(t1:t2,i) = 1;

                end


                ri{coiIdx} = (1:(Ni*Nk)) + lastri;
                lastri = ri{coiIdx}(end);


                for i = 1:Ni

                    for k = 1:Nk

                        b = conv(u(:,i),bf(:,k));

                        xCount = xCount + 1;
                        X(:,xCount) = b(s);

                    end

                end


            else

                u = zeros(Nt,1,'single');

                u(round(sots{j}*st)+1) = 1;

                for k = 1:Nk

                    b = conv(u,bf(:,k));

                    x0Count = x0Count + 1;
                    X0(:,x0Count) = b(s);

                end

            end

        end


        %% Full design matrix

        Z = [X X0 XC K];

        if zflag
            Z = single(zscore(Z));
        end


        %% Estimate GLM

        Nji = length(coi)*Nk;

        if lambda == 0

            pX = pinv(Z);

        else

            Np = size(Z,2);

            R = zeros(Np,Np,'single');
            R(1:Nji,1:Nji) = eye(Nji,'single');

            pX = (Z'*Z + single(lambda)*R)\Z';

        end


        %% Allocate beta output

        Beta = cell(Nji,1);

        for j = 1:Nji
            Beta{j} = zeros(size(ri{j},2),Nr,'single');
        end


        %% Process voxels in batches

        for bIdx = 1:nBatches

            firstVoxel = (bIdx-1)*voxel_batch_size + 1;
            lastVoxel  = min(bIdx*voxel_batch_size,Nr);

            voxelIdx = firstVoxel:lastVoxel;

            fprintf('\n\tBatch %d/%d: voxels %d-%d', ...
                bIdx,nBatches,firstVoxel,lastVoxel);

            B = pX*d(:,voxelIdx);


            for j = 1:Nji

                Beta{j}(:,voxelIdx) = B(ri{j},:);

            end

        end


        % Residuals deliberately not calculated
        res = [];


    %% =========================================================================
    %  LSS
    %  =========================================================================

    case 'LSS'

        %% Preallocate design matrices

        nX = sum(cellfun(@numel,sots(coi))) * Nk;

        nonCoi = setdiff(1:Nj,coi);

        nX0 = sum(cellfun(@numel,sots(nonCoi))) * Nk;

        X  = zeros(Ns,nX,'single');
        X0 = zeros(Ns,nX0,'single');

        ri = cell(Ncoi,1);

        lastri = 0;

        xCount  = 0;
        x0Count = 0;


        %% Build design matrix

        for j = 1:Nj

            coiIdx = find(coi == j,1);

            if ~isempty(coiIdx)

                Ni = length(sots{j});

                if Ni > 0

                    u = zeros(Nt,Ni,'single');

                    for i = 1:Ni

                        t1 = round(sots{j}(i)*st) + 1;
                        t2 = t1 + round(durs{j}(i)*st);

                        u(t1:t2,i) = 1;

                    end


                    ri{coiIdx} = (1:(Ni*Nk)) + lastri;
                    lastri = ri{coiIdx}(end);


                    for i = 1:Ni

                        for k = 1:Nk

                            b = conv(u(:,i),bf(:,k));

                            xCount = xCount + 1;
                            X(:,xCount) = b(s);

                        end

                    end

                end

            else

                u = zeros(Nt,1,'single');

                u(round(sots{j}*st)+1) = 1;

                for k = 1:Nk

                    b = conv(u,bf(:,k));

                    x0Count = x0Count + 1;
                    X0(:,x0Count) = b(s);

                end

            end

        end


        %% Precompute combined regressors from other conditions

        Xl = cell(Ncoi,1);

        for j = 1:Ncoi

            otherConditions = setdiff(1:Ncoi,j);
            nOther = length(otherConditions);

            if nOther > 0

                Xl{j} = zeros(Ns,nOther,'single');

                for k = 1:nOther

                    Xl{j}(:,k) = ...
                        sum(X(:,ri{otherConditions(k)}),2);

                end

            else

                Xl{j} = zeros(Ns,0,'single');

            end

        end


        %% Allocate beta output

        Beta = cell(Ncoi,1);

        for j = 1:Ncoi

            Ni = length(sots{coi(j)});

            Beta{j} = zeros(Ni,Nr,'single');

        end


        %% Number of trials

        totalTrials = sum(cellfun(@numel,sots(coi)));

        trialCounter = 0;


        %% Fit one GLM per trial

        for j = 1:Ncoi

            condition = coi(j);
            Ni = length(sots{condition});

            if Ni == 0
                continue
            end


            Xl_j = Xl{j};


            for i = 1:Ni

                trialCounter = trialCounter + 1;

                fprintf('\n\tTrial %d/%d (condition %d, trial %d)', ...
                    trialCounter,totalTrials,condition,i);


                %% Trial-of-interest regressor

                Xs = zeros(Ns,1 + (Ni > 1),'single');

                Xs(:,1) = X(:,ri{j}(i));


                %% Other trials from same condition

                if Ni > 1

                    % Equivalent to:
                    %
                    % sum(X(:,setdiff(ri{j},ri{j}(i))),2)
                    %
                    % but avoids setdiff and repeated indexing.

                    Xs(:,2) = sum(X(:,ri{j}),2) - Xs(:,1);

                end


                %% Full design matrix

                Z = [Xs Xl_j X0 XC K];

                if zflag
                    Z = single(zscore(Z));
                end


                %% GLM pseudoinverse

                pX = pinv(Z);


                %% Process voxels in batches

                for bIdx = 1:nBatches

                    firstVoxel = (bIdx-1)*voxel_batch_size + 1;
                    lastVoxel  = min(bIdx*voxel_batch_size,Nr);

                    voxelIdx = firstVoxel:lastVoxel;


                    % Only this batch of voxels enters the matrix
                    % multiplication.

                    B = pX*d(:,voxelIdx);


                    % The first row of B is the beta for the
                    % trial-of-interest.

                    Beta{j}(i,voxelIdx) = B(1,:);

                end

            end

        end


        % Residuals deliberately not calculated
        res = [];


    %% =========================================================================
    %  Unknown method
    %  =========================================================================

    otherwise

        error('unknown estimation method')

end


fprintf('\n');

return

