function [ cfgAutoArt ] = INFADI_autoArtifact( cfg, data, varargin )
% INFADI_AUTOARTIFACT marks timeslots as an artifact in which the values of
% specified channels exeeds either a min-max level, a defined range, a
% standard deviation threshold or a defined mutiple of the median absolute
% deviation.
%
% Use as
%   [ cfgAutoArt ] = INFADI_autoArtifact(cfg, data, varargin)
%
% where data have to be a result of INFADI_PREPROCESSING or INFADI_CONCATDATA
%
% The configuration options are
%   cfg.part        = participants which shall be processed: experimenter, child or both (default: both)
%   cfg.channel     = 1x2 cell-array with channel labels for experimenter and child (default: {{'Cz', 'O1', 'O2'}, {'Cz', 'O1', 'O2'}}))
%   cfg.method      = 'minmax', 'range', 'stddev' or 'mad' (default: 'minmax')
%   cfg.deadsegs   = 'yes' or 'no', estimating segments in which at least one channel is dead or in saturation
%                     if cfg.deathsegs = yes, varargin has to be data_raw
%   cfg.sliding     = use a sliding window, 'yes' or 'no', (default: 'no')
%   cfg.winsize     = size of sliding window (default: 200 ms)
%                     only required if cfg.sliding = 'yes'
%   cfg.continuous  = data is continuous ('yes' or 'no', default: 'no')
%                     only required, if cfg.sliding = 'no'
%
% Specify the trial specification, which will later be used with artifact rejection
%   cfg.trllength   = trial length (default: 1000 ms = minimal subtrial length with plv estimation)
%   cfg.overlap     = amount of window overlapping in percentage (default: 0, permitted values: 0 or 50)
%
% Specify at least one of theses thresholds. First value is defined for
% experimenters, the second one for children. If there is only one value
% defined, this value will be used for both participants.
%   cfg.min         = lower limit in uV (default: [-75 -75])
%   cfg.max         = upper limit in uV (default: [75 75])
%   cfg.range       = range in uV (default: [200 200])
%   cfg.stddev      = standard deviation threshold in uV (default: [50 50])
%                     only usable for cfg.sliding = 'yes'
%   cfg.mad         = multiple of median absolute deviation (default: [7 7])
%
% This function requires the fieldtrip toolbox.
%
% See also INFADI_GENTRL, INFADI_PREPROCESSING, INFADI_SEGMENTATION, 
% INFADI_CONCATDATA, FT_ARTIFACT_THRESHOLD

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Load general definitions
% -------------------------------------------------------------------------
filepath = fileparts(mfilename('fullpath'));
load(sprintf('%s/../general/INFADI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
part        = ft_getopt(cfg, 'part', 'both');                               % participant selection
chan        = ft_getopt(cfg, 'channel', ...                                 % channels to test
                          {{'Cz', 'O1', 'O2'},{'Cz', 'O1', 'O2'}});
method      = ft_getopt(cfg, 'method', 'minmax');                           % artifact detection method
deadsegs    = ft_getopt(cfg, 'deadsegs', 'no');                            	% estimating segments in which at least one channel is dead or in saturation
sliding     = ft_getopt(cfg, 'sliding', 'no');                              % use a sliding window

if ~ismember(part, {'experimenter', 'child', 'both'})                       % check cfg.part definition
  error('cfg.part has to either ''experimenter'', ''child'' or ''both''.');
end

if ~(strcmp(sliding, 'no') || strcmp(sliding, 'yes'))                       % validate cfg.sliding
  error('Sliding has to be either ''yes'' or ''no''!');
end

trllength   = ft_getopt(cfg, 'trllength',1000);                             % subtrial length to which the detected artifacts will be extended
overlap     = ft_getopt(cfg, 'overlap', 0);                                 % overlapping between the subtrials

if ~(overlap ==0 || overlap == 50)                                          % only non overlapping or 50% is allowed to simplify this function
  error('Currently there is only overlapping of 0 or 50% permitted');
end

cfgTrl          = [];
cfgTrl.length   = trllength;
cfgTrl.overlap  = overlap;
trl = INFADI_genTrl(cfgTrl, data);                                          % generate subtrial specification

trllength = trllength * data.experimenter.fsample/1000;                     % convert subtrial length from milliseconds into number of samples

switch method                                                               % get and check method dependent config input
  case 'minmax'
    minVal    = ft_getopt(cfg, 'min', [-75 -75]);
    maxVal    = ft_getopt(cfg, 'max', [75 75]);
    if length(minVal) == 1
      minVal(2) = minVal(1);
    end
    if length(maxVal) == 1
      maxVal(2) = maxVal(1);
    end
    if strcmp(sliding, 'no')
      continuous  = ft_getopt(cfg, 'continuous', 'no');
    else
      error('Method ''minmax'' is not supported with option sliding=''yes''');
    end
  case 'range'
    range     = ft_getopt(cfg, 'range', [200 200]);
    if length(range) == 1
      range(2) = range(1);
    end
    if strcmp(sliding, 'no')
      continuous  = ft_getopt(cfg, 'continuous', 0);
    else
      winsize     = ft_getopt(cfg, 'winsize', 200);
    end
  case 'stddev'
    stddev     = ft_getopt(cfg, 'stddev', [50 50]);
    if length(stddev) == 1
      stddev(2) = stddev(1);
    end
    if strcmp(sliding, 'no')
      error('Method ''stddev'' is not supported with option sliding=''no''');
    else
      winsize     = ft_getopt(cfg, 'winsize', 200);
    end
  case 'mad'
    mad     = ft_getopt(cfg, 'mad', [7 7]);
    if length(mad) == 1
      mad(2) = mad(1);
    end
    if strcmp(sliding, 'no')
      error('Method ''mad'' is not supported with option sliding=''no''');
    else
      winsize     = ft_getopt(cfg, 'winsize', 200);
    end
  otherwise
    error('Only ''minmax'', ''range'' and ''stdev'' are supported methods');
end

if strcmp(deadsegs, 'yes')
  data_raw = varargin{1};
end

% -------------------------------------------------------------------------
% Artifact detection settings
% -------------------------------------------------------------------------
cfg = [];
cfg.method                        = method;
cfg.sliding                       = sliding;
cfg.artfctdef.threshold.bpfilter  = 'no';                                   % use no additional bandpass
cfg.artfctdef.threshold.bpfreq    = [];                                     % use no additional bandpass
cfg.artfctdef.threshold.onset     = [];                                     % just defined to get a similar output from ft_artifact_threshold and artifact_threshold
cfg.artfctdef.threshold.offset    = [];                                     % just defined to get a similar output from ft_artifact_threshold and artifact_threshold
cfg.showcallinfo                  = 'no';

switch method                                                               % set method dependent config parameters
  case 'minmax'
    cfg.artfctdef.threshold.min     = minVal(1);                            % minimum threshold
    cfg.artfctdef.threshold.max     = maxVal(1);                            % maximum threshold
    if strcmp(sliding, 'no')
      cfg.continuous = continuous;
      cfg.trl        = trl;
    end
  case 'range'
    cfg.artfctdef.threshold.range   = range(1);                             % range
    if strcmp(sliding, 'yes')
      cfg.artfctdef.threshold.winsize = winsize;
      cfg.artfctdef.threshold.trl = trl;
    else
      cfg.continuous = continuous;
      cfg.trl        = trl;
    end
  case 'stddev'
    cfg.artfctdef.threshold.stddev  = stddev(1);                            % stddev
    if strcmp(sliding, 'yes')
      cfg.artfctdef.threshold.winsize = winsize;
      cfg.artfctdef.threshold.trl = trl;
    end
  case 'mad'
    cfg.artfctdef.threshold.mad  = mad(1);                                  % mad
    if strcmp(sliding, 'yes')
      cfg.artfctdef.threshold.winsize = winsize;
      cfg.artfctdef.threshold.trl = trl;
    end
end

% -------------------------------------------------------------------------
% Estimate artifacts
% -------------------------------------------------------------------------
if ismember(part, {'experimenter', 'both'})
  cfgAutoArt.experimenter = [];                                             % build output structure
  cfgAutoArt.bad1Num = [];
end

if ismember(part, {'child', 'both'})
  cfgAutoArt.child = [];
  cfgAutoArt.bad2Num = [];
end

cfgAutoArt.trialsNum = size(trl, 1);

ft_info off;

if ismember(part, {'experimenter', 'both'})
  fprintf('<strong>Estimate artifacts in experimenter...</strong>\n');      % experimenter
  cfg.artfctdef.threshold.channel   = chan{1};                              % specify channels of interest
  cfgAutoArt.experimenter = artifact_detect(cfg, data.experimenter);
  cfgAutoArt.experimenter = keepfields(cfgAutoArt.experimenter, {'artfctdef', 'showcallinfo'});

  if strcmp(deadsegs, 'yes')
    fprintf('<strong>Run detection of segments in which at least one channel is dead or in saturation (experimenter)...</strong>\n');
    cfg2 = [];
    cfg2.method                        = 'zero';
    cfg2.sliding                       = 'yes';
    cfg2.artfctdef.threshold.channel   = chan{1};                           % specify channels of interest
    cfg2.artfctdef.threshold.bpfilter  = 'no';                              % use no additional bandpass
    cfg2.artfctdef.threshold.bpfreq    = [];                                % use no additional bandpass
    cfg2.artfctdef.threshold.onset     = [];                                % just defined to get a similar output from ft_artifact_threshold and artifact_threshold
    cfg2.artfctdef.threshold.offset    = [];                                % just defined to get a similar output from ft_artifact_threshold and artifact_threshold
    cfg2.artfctdef.threshold.zero      = 1.5;
    cfg2.artfctdef.threshold.winsize   = 200;
    cfg2.artfctdef.threshold.trl       = trl;
    cfg2.showcallinfo                  = 'no';

    cfgDeadSeg = artifact_detect(cfg2, data_raw.experimenter);
    cfgAutoArt.experimenter.artfctdef.threshold.artfctmap = ...             % merge artifact maps
          cellfun(@(X,Y) or(X,Y), ...
          cfgAutoArt.experimenter.artfctdef.threshold.artfctmap, ...
          cfgDeadSeg.artfctdef.threshold.artfctmap, 'UniformOutput', false);
    cfgAutoArt.experimenter.artfctdef.threshold.artifact = ...              % combine artifact list
              [cfgAutoArt.experimenter.artfctdef.threshold.artifact; ...
                cfgDeadSeg.artfctdef.threshold.artifact];
    cfgAutoArt.experimenter.artfctdef.threshold.zero = 1.5;                 % add zero-artifact threshold
  end

  [cfgAutoArt.experimenter.artfctdef.threshold, cfgAutoArt.bad1Num] = ...   % extend artifacts to subtrial definition
                  combineArtifacts( overlap, trllength, cfgAutoArt.experimenter.artfctdef.threshold );
  fprintf('%d segments with artifacts detected!\n', cfgAutoArt.bad1Num);

  if cfgAutoArt.bad1Num == sum(generalDefinitions.trialNum1sec)
    warning('All trials are marked as bad, it is recommended to recheck the channels quality!');
  end

  if isfield(cfgAutoArt.experimenter.artfctdef.threshold, 'artfctmap')
    artfctmap = cfgAutoArt.experimenter.artfctdef.threshold.artfctmap;
    artfctmap = cellfun(@(x) sum(x, 2), artfctmap, 'UniformOutput', false);
    cfgAutoArt.bad1NumChan = nansum(cat(2,artfctmap{:}),2);

    cfgAutoArt.labelExp = ft_channelselection(...
                cfgAutoArt.experimenter.artfctdef.threshold.channel, ...
                data.experimenter.label);
  end
end

if ismember(part, {'child', 'both'})
  switch method                                                             % change threshold for the childs dataset
    case 'minmax'
      cfg.artfctdef.threshold.min     = minVal(2);                          % minimum threshold
      cfg.artfctdef.threshold.max     = maxVal(2);                          % maximum threshold
    case 'range'
      cfg.artfctdef.threshold.range   = range(2);                           % range
    case 'stddev'
      cfg.artfctdef.threshold.stddev  = stddev(2);                          % stddev
    case 'mad'
      cfg.artfctdef.threshold.mad  = mad(2);                                % mad
  end

  fprintf('<strong>Estimate artifacts in child...</strong>\n');             % child
  cfg.artfctdef.threshold.channel   = chan{2};                              % specify channels of interest
  cfgAutoArt.child = artifact_detect(cfg, data.child);
  cfgAutoArt.child = keepfields(cfgAutoArt.child, {'artfctdef', 'showcallinfo'});

   if strcmp(deadsegs, 'yes')
    fprintf('<strong>Run detection of segments in which at least one channel is dead or in saturation (child)...</strong>\n');
    cfg2.artfctdef.threshold.channel   = chan{2};                           % specify channels of interest

    cfgDeadSeg = artifact_detect(cfg2, data_raw.child);
    cfgAutoArt.child.artfctdef.threshold.artfctmap = ...                    % merge artifact maps
          cellfun(@(X,Y) or(X,Y), ...
          cfgAutoArt.child.artfctdef.threshold.artfctmap, ...
          cfgDeadSeg.artfctdef.threshold.artfctmap, 'UniformOutput', false);
    cfgAutoArt.child.artfctdef.threshold.artifact = ...                     % combine artifact list
              [cfgAutoArt.child.artfctdef.threshold.artifact; ...
                cfgDeadSeg.artfctdef.threshold.artifact];
    cfgAutoArt.child.artfctdef.threshold.zero = 1.5;                        % add zero-artifact threshold
  end

  [cfgAutoArt.child.artfctdef.threshold, cfgAutoArt.bad2Num] = ...          % extend artifacts to subtrial definition
                  combineArtifacts( overlap, trllength, cfgAutoArt.child.artfctdef.threshold );
  fprintf('%d segments with artifacts detected!\n', cfgAutoArt.bad2Num);

  if cfgAutoArt.bad2Num == sum(generalDefinitions.trialNum1sec)
    warning('All trials are marked as bad, it is recommended to recheck the channels quality!');
  end

  if isfield(cfgAutoArt.child.artfctdef.threshold, 'artfctmap')
    artfctmap = cfgAutoArt.child.artfctdef.threshold.artfctmap;
    artfctmap = cellfun(@(x) sum(x, 2), artfctmap, 'UniformOutput', false);
    cfgAutoArt.bad2NumChan = nansum(cat(2,artfctmap{:}),2);

    cfgAutoArt.labelChild = ft_channelselection(...
                cfgAutoArt.child.artfctdef.threshold.channel, ...
                data.child.label);
  end
end

ft_info on;

end

% -------------------------------------------------------------------------
% SUBFUNCTION which selects the appropriate artifact detection method based
% on the selected config options
% -------------------------------------------------------------------------
function [ autoart ] = artifact_detect(cfgT, data_in)

method  = cfgT.method;
sliding = cfgT.sliding;
cfgT    = removefields(cfgT, {'method', 'sliding'});

if strcmp(sliding, 'yes')                                                   % sliding window --> use own artifacts_threshold function
  autoart = artifact_sliding_threshold(cfgT, data_in);
elseif strcmp(method, 'minmax')                                             % method minmax --> use own special_minmax_threshold function
  autoart = special_minmax_threshold(cfgT, data_in);
else                                                                        % no sliding window, no minmax method --> use ft_artifacts_threshold function
  autoart = ft_artifact_threshold(cfgT, data_in);
end

end

% -------------------------------------------------------------------------
% SUBFUNCTION which detects artifacts by using a sliding window
% -------------------------------------------------------------------------
function [ autoart ] = artifact_sliding_threshold(cfgT, data_in)

  numOfTrl  = length(data_in.trialinfo);                                    % get number of trials in the data
  winsize   = cfgT.artfctdef.threshold.winsize * data_in.fsample / 1000;    % convert window size from milliseconds to number of samples
  artifact  = zeros(0,2);                                                   % initialize artifact variable
  artfctmap{1,numOfTrl} = [];

  channel = ft_channelselection(cfgT.artfctdef.threshold.channel, ...
              data_in.label);

  for i = 1:1:numOfTrl
    data_in.trial{i} = data_in.trial{i}(ismember(data_in.label, ...         % prune the available data to the channels of interest
                        channel) ,:);
  end

  if isfield(cfgT.artfctdef.threshold, 'range')                             % check for range violations
    for i=1:1:numOfTrl
      tmpmin = movmin(data_in.trial{i}, winsize, 2);                        % get all minimum values
      tmpmin = prune_mat(tmpmin, winsize);                                  % remove useless results from the edges

      tmpmax = movmax(data_in.trial{i}, winsize, 2);                        % get all maximum values
      tmpmax = prune_mat(tmpmax, winsize);                                  % remove useless results from the edges

      tmp = abs(tmpmin - tmpmax);                                           % estimate a moving maximum difference

      artfctmap{i} = tmp > cfgT.artfctdef.threshold.range;                  % find all violations
      [artfctmap{i}, artifact] = estim_artifact_limits(artfctmap{i}, ...    % add artifact to the artifacts matrix, extend the violations in the map to the window size
                                    artifact, data_in.sampleinfo(i,1), ...
                                    channel, winsize);
    end
  elseif isfield(cfgT.artfctdef.threshold, 'stddev')                        % check for standard deviation violations
    for i=1:1:numOfTrl
      tmp = movstd(data_in.trial{i}, winsize, 0, 2);                        % estimate a moving standard deviation
      tmp = prune_mat(tmp, winsize);

      artfctmap{i} = tmp > cfgT.artfctdef.threshold.stddev;                 % find all violations
      [artfctmap{i}, artifact] = estim_artifact_limits(artfctmap{i}, ...    % add artifact to the artifacts matrix, extend the violations in the map to the window size
                                    artifact, data_in.sampleinfo(i,1), ...
                                    channel, winsize);
    end
  elseif isfield(cfgT.artfctdef.threshold, 'zero')                          % check for standard deviation violations which indicating dead channels
    for i=1:1:numOfTrl
      tmp = movstd(data_in.trial{i}, winsize, 0, 2);                        % estimate a moving standard deviation
      tmp = prune_mat(tmp, winsize);                                        % remove useless results from the edges

      artfctmap{i} = tmp < cfgT.artfctdef.threshold.zero;                   % find all violations
      [artfctmap{i}, artifact] = estim_artifact_limits(artfctmap{i}, ...    % add artifact to the artifacts matrix, extend the violations in the map to the window size
                                    artifact, data_in.sampleinfo(i,1), ...
                                    channel, winsize);
    end
  elseif isfield(cfgT.artfctdef.threshold, 'mad')                           % check for median absolute deviation violations
    data_continuous = cat(2, data_in.trial{:});                             % concatenate all trials
    tmpmad = mad(data_continuous, 1, 2);                                    % estimate the median absolute deviation of the whole data
    tmpmedian = median(data_continuous, 2);                                 % estimate the median of the data

    for i=1:1:numOfTrl
      tmpmin = movmin(data_in.trial{i}, winsize, 2);                        % get all minimum values
      tmpmin = prune_mat(tmpmin, winsize);

      tmpmax = movmax(data_in.trial{i}, winsize, 2);                        % get all maximum values
      tmpmax = prune_mat(tmpmax, winsize);

      tmpdiffmax = abs(tmpmax - tmpmedian);                                 % estimate the differences between the maximum values and the median
      tmpdiffmin = abs(tmpmin - tmpmedian);                                 % estimate the differences between the minimum values and the median
      tmp = cat(3, tmpdiffmax, tmpdiffmin);                                 % select always the maximum absolute difference
      tmp = max(tmp, [], 3);

      artfctmap{i} = tmp > cfgT.artfctdef.threshold.mad*tmpmad;             % find all violations
      [artfctmap{i}, artifact] = estim_artifact_limits(artfctmap{i}, ...    % add artifact to the artifacts matrix, extend the violations in the map to the window size
                                    artifact, data_in.sampleinfo(i,1), ...
                                    channel, winsize);
    end
  end

  autoart.artfctdef     = cfgT.artfctdef;                                   % generate output data structure
  autoart.showcallinfo  = cfgT.showcallinfo;
  autoart.artfctdef.threshold.artifact  = artifact;
  autoart.artfctdef.threshold.artfctmap = artfctmap;
  autoart.artfctdef.threshold.sliding   = 'yes';

end

% -------------------------------------------------------------------------
% SUBFUNCTION which prunes useless results from matrix
% -------------------------------------------------------------------------
function [ mat ] = prune_mat(mat, winsize)
  if mod(winsize, 2)                                                        % remove useless results from the edges
    mat = mat(:, (winsize/2 + 1):(end-winsize/2));
  else
    mat = mat(:, (winsize/2 + 1):(end-winsize/2 + 1));
  end
end

% -------------------------------------------------------------------------
% SUBFUNCTION which is estimating the absolut artifact limits from the
% given violations and which is extending the artifactmap entry to the
% trial size
% -------------------------------------------------------------------------
function [map, artifact] = estim_artifact_limits(map, artifact, offset,...
                               channel, winsize)
  [channum, begnum] = find(map);                                            % estimate pairs of channel numbers and begin numbers for each violation
  map = [map false(length(channel), winsize - 1)];                          % extend artfctmap to trial size
  endnum = begnum + winsize - 1;                                            % estimate end numbers for each violation
  for j=1:1:length(channum)
    map(channum(j), begnum(j):endnum(j)) = true;                            % extend the violations in the map to the window size
  end
  if ~isempty(begnum)
    begnum = unique(begnum);                                                % select all unique violations
    begnum = begnum + offset - 1;                                           % convert relative sample number into an absolute one
    begnum(:,2) = begnum(:,1) + winsize - 1;
    artifact = [artifact; begnum];                                          % add results to the artifacts matrix
  end
end

% -------------------------------------------------------------------------
% SUBFUNCTION which detects threshold artifacts by using a minmax threshold
% - it is a replacement of ft_artifact threshold which provides an
% additional artifact map
% -------------------------------------------------------------------------
function [ autoart ] = special_minmax_threshold(cfgT, data_in)

  numOfTrl  = length(data_in.trialinfo);                                    % get number of trials in the data
  artifact  = zeros(0,2);                                                   % initialize artifact variable
  artfctmap{1,numOfTrl} = [];

  channel = ft_channelselection(cfgT.artfctdef.threshold.channel, ...
              data_in.label);

  for i = 1:1:numOfTrl
    data_in.trial{i} = data_in.trial{i}(ismember(data_in.label, ...         % prune the available data to the channels of interest
                        channel) ,:);
  end

  if isfield(cfgT.artfctdef.threshold, 'max')                               % check for range violations
    for i=1:1:numOfTrl
      artfctmap{i} = data_in.trial{i} < cfgT.artfctdef.threshold.min;       % find all min violations
      artfctmap{i} = artfctmap{i} | data_in.trial{i} > ...                  % add all max violations
                      cfgT.artfctdef.threshold.max;
      artval = any(artfctmap{i}, 1);
      begsample = find(diff([false artval])>0) + ...                        % estimates artifact snippets
                    data_in.sampleinfo(i,1) - 1;
      endsample = find(diff([artval false])<0) + ...
                    data_in.sampleinfo(i,1) - 1;
      artifact  = cat(1, artifact, [begsample(:) endsample(:)]);            % add results to the artifacts matrix
    end
  end

  autoart.artfctdef     = cfgT.artfctdef;                                   % generate output data structure
  autoart.showcallinfo  = cfgT.showcallinfo;
  autoart.artfctdef.threshold.artifact  = artifact;
  autoart.artfctdef.threshold.trl = cfgT.trl;
  autoart.artfctdef.threshold.artfctmap = artfctmap;
end


% -------------------------------------------------------------------------
% SUBFUNCTION which extends and combines artifacts according to the
% subtrial definition
% -------------------------------------------------------------------------
function [ threshold, bNum ] = combineArtifacts( overl, trll, threshold )

if isempty(threshold.artifact)                                              % do nothing, if nothing was detected
  bNum = 0;
  return;
end

trlMask   = zeros(size(threshold.trl,1), 1);

for i = 1:size(threshold.trl,1)
  if overl == 0                                                             % if no overlapping was selected
    if any(~(threshold.artifact(:,2) < threshold.trl(i,1)) & ...            % mark artifacts which final points are not less than the trials zero point
            ~(threshold.artifact(:,1) > threshold.trl(i,2)))                % mark artifacts which zero points are not greater than the trials final point
      trlMask(i) = 1;                                                       % mark trial as bad, if both previous conditions are true at least for one artifact
    end
  else                                                                      % if overlapping of 50% was selected
    if any(~(threshold.artifact(:,2) < (threshold.trl(i,1) + trll/2)) & ... % mark artifacts which final points are not less than the trials zero point - trllength/2
            ~(threshold.artifact(:,1) > (threshold.trl(i,2) - trll/2)))     % mark artifacts which zero points are not greater than the trials final point + trllength/2
      trlMask(i) = 1;                                                       % mark trial as bad, if both previous conditions are true at least for one artifact
    end
  end
end

bNum = sum(trlMask);                                                        % calc number of bad segments
threshold.artifact = threshold.trl(logical(trlMask),1:2);                   % if trial contains artifacts, mark whole trial as artifact

if isfield(threshold, 'artfctmap')
  map = [];

  for i=1:1:size(threshold.artfctmap, 2)
    for j = 1:trll:(size(threshold.artfctmap{i},2) - trll + 1)
      map = [map sum(threshold.artfctmap{i}(:,j:j+trll-1) == 1, 2) > 0];    %#ok<AGROW>
    end
    if ~isempty(map)
      threshold.artfctmap{i} = map;
      map = [];
    else
      cprintf([1,0.5,0], 'Trial %d is shorter than %d second (segmentation size).\n', i, trll/500);
      cprintf([1,0.5,0], 'It will be rejected in general. Thus, no artifact information is available.\n');
      threshold.artfctmap{i} = NaN(size(threshold.artfctmap{i}, 1), 1);
    end
  end

end

end
