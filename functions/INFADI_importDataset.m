function [ data, cfg_manart ] = INFADI_importDataset(cfg)
% INFADI_IMPORTDATASET imports one specific dataset recorded with a device 
% from brain vision.
%
% Use as
%   [ data, cfg_manart ] = INFADI_importDataset(cfg)
%
% The configuration options are
%   cfg.path          = source path' (i.e. '/data/pt_01905/eegData/DualEEG_INFADI_rawData/')
%   cfg.dyad          = number of dyad
%   cfg.continuous    = 'yes' or 'no' (default: 'no')
%   cfg.prestim       = define pre-Stimulus offset in seconds (default: 0)
%   cfg.rejectoverlap = reject first of two overlapping trials, 'yes' or 'no' (default: 'yes')
%
% The second output variable holds the manual during testing defined
% artifacts.
%
% You can use relativ path specifications (i.e. '../../MATLAB/data/') or 
% absolute path specifications like in the example. Please be aware that 
% you have to mask space signs of the path names under linux with a 
% backslash char (i.e. '/home/user/test\ folder')
%
% This function requires the fieldtrip toolbox.
%
% See also FT_PREPROCESSING, INFADI_DATASTRUCTURE

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
path          = ft_getopt(cfg, 'path', []);
dyad          = ft_getopt(cfg, 'dyad', []);
continuous    = ft_getopt(cfg, 'continuous', 'no');
prestim       = ft_getopt(cfg, 'prestim', 0);
rejectoverlap = ft_getopt(cfg, 'rejectoverlap', 'yes');

if isempty(path)
  error('No source path is specified!');
end

if isempty(dyad)
  error('No specific participant is defined!');
end

headerfile = sprintf('%sINFADI_%02d.vhdr', path, dyad);

if strcmp(continuous, 'no')
  % -----------------------------------------------------------------------
  % Load general definitions
  % -------------------------------------------------------------------------
  filepath = fileparts(mfilename('fullpath'));
  load(sprintf('%s/../general/INFADI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');

  % definition of all possible stimuli, two for each condition, the first 
  % on is the original one and the second one handles the 'video trigger 
  % bug'
  eventvalues = generalDefinitions.condMark;
  artfctvalues = generalDefinitions.artfctMark;
  samplingRate = 500;
  dur = (generalDefinitions.duration + prestim) * samplingRate;
              
  % -----------------------------------------------------------------------
  % Generate trial definition
  % -----------------------------------------------------------------------
  % basis configuration for data import
  cfg                     = [];
  cfg.dataset             = headerfile;
  cfg.trialfun            = 'ft_trialfun_general';
  cfg.trialdef.eventtype  = 'Stimulus';
  cfg.trialdef.prestim    = prestim;
  cfg.showcallinfo        = 'no';
  cfg.feedback            = 'error';
  cfg.trialdef.eventvalue = eventvalues;

  cfg = ft_definetrial(cfg);                                                % generate config for segmentation
  if isfield(cfg, 'notification')
    cfg = rmfield(cfg, {'notification'});                                   % workarround for mergeconfig bug
  end

  for i = 1:1:size(cfg.trl, 1)                                              % set specific trial lengths
    element = generalDefinitions.condNum == cfg.trl(i,4);
    cfg.trl(i, 2) = dur(element) + cfg.trl(i, 1) - 1;
  end

  % -----------------------------------------------------------------------
  % Extract artifacts
  % -----------------------------------------------------------------------
  cfgArtfct                     = [];
  cfgArtfct.dataset             = headerfile;
  cfgArtfct.trialfun            = 'ft_trialfun_general';
  cfgArtfct.trialdef.eventtype  = 'Stimulus';
  cfgArtfct.showcallinfo        = 'no';
  cfgArtfct.feedback            = 'error';
  cfgArtfct.trialdef.eventvalue = artfctvalues;

  try
    cfgArtfct = ft_definetrial(cfgArtfct);                                  % extract manual artifact markers
  catch
    cfgArtfct = [];
  end

  if ~isempty(cfgArtfct)
    hdr = ft_read_header(headerfile);                                       % read header file

    artifact     = cfgArtfct.trl;
    numOfArtfct = size(artifact, 1);

    if mod(numOfArtfct, 2)                                                  % if the last artStop marker is missing, add one at the last data sample
      artifact(numOfArtfct + 1, :) = [hdr.nSamples hdr.nSamples 0 7];
      numOfArtfct = numOfArtfct + 1;
    end

    locStart = ismember(artifact(:,4), 6);                                  % check if every artStart marker has one corresponding artStop marker
    locStop = ismember(artifact(:,4), 7);
    if ~all(locStart == circshift(locStop,1))
      error(['Problems with manual artifact markers! Not every ' ...
              '''S  6'' has a corresponding ''S  7''.']);
    end

    artifact(locStart, 2) = artifact(locStop, 1);
    artifact = artifact(locStart, :);
    numOfArtfct = numOfArtfct/2;
    artifact(:,3) = artifact(:,2) - artifact(:,1) + 1;

    % ---------------------------------------------------------------------
    % Adapt trial size
    % ---------------------------------------------------------------------
    for i = 1:1:numOfArtfct
      locArt = (artifact(i,1) >= cfg.trl(:,1) & ...
                artifact(i,1) <= cfg.trl(:,2)   );
      cfg.trl(locArt, 2) = cfg.trl(locArt,2) + artifact(i,3);
      if(sum(locArt) > 1)
        error(['Something weird happend! One manual artifact could ' ...
                'not be assigned to only one particular trial']);
      end
      if cfg.trl(locArt,2) > hdr.nSamples
        cfg.trl(locArt,2) = hdr.nSamples;
      end
    end

    % ---------------------------------------------------------------------
    % Generate artifact config
    % ---------------------------------------------------------------------
    cfg_manart = [];
    cfg_manart.experimenter.artfctdef.xxx.artifact = artifact(:,1:2);
    cfg_manart.child.artfctdef.xxx.artifact = artifact(:,1:2);
  else
    % ---------------------------------------------------------------------
    % Adapt trial size, if recording was aborted
    % ---------------------------------------------------------------------
    hdr = ft_read_header(headerfile);                                       % read header file
    if cfg.trl(end,2) > hdr.nSamples
      cfg.trl(end,2) = hdr.nSamples;
    end

    % ---------------------------------------------------------------------
    % Generate artifact config
    % ---------------------------------------------------------------------
    cfg_manart = [];
    cfg_manart.experimenter.artfctdef.xxx.artifact = [];
    cfg_manart.child.artfctdef.xxx.artifact = [];
  end
  
  % -----------------------------------------------------------------------
  % Reject overlapping trials
  % -----------------------------------------------------------------------
  if strcmp(rejectoverlap, 'yes')                                           % if overlapping trials should be rejected
    overlapping = find(cfg.trl(1:end-1,2) > cfg.trl(2:end, 1));             % in case of overlapping trials, remove the first of theses trials
    if ~isempty(overlapping)
      for i = 1:1:length(overlapping)
        warning off backtrace;
        warning(['trial %d with marker ''S%3d''  will be removed due to '...
               'overlapping data with its successor.'], ...
               overlapping(i), cfg.trl(overlapping(i), 4));
        warning on backtrace;
      end
      cfg.trl(overlapping, :) = [];
    end
  end
else
  cfg                     = [];
  cfg.dataset             = headerfile;
  cfg.showcallinfo        = 'no';
  cfg.feedback            = 'no';
end

% -------------------------------------------------------------------------
% Data import
% -------------------------------------------------------------------------
cfg.channel = {'all', '-T7_1', '-T7_2', '-T8_1', '-T8_2', ...               % exclude all general bad channels
               '-PO9_1', '-PO9_2', '-PO10_1','-PO10_2', ...
               '-P7_1', '-P7_2', '-P8_1', '-P8_2', ...
               '-TP10_1', '-TP10_2', '-V1_1', '-V2_1'};                     % V1 and V2 are not connected with children
dataTmp = ft_preprocessing(cfg);                                            % import data

data.experimenter = dataTmp;                                                % split dataset into two datasets, one for each participant
data.experimenter.label = strrep(dataTmp.label(24:48), '_2', '');
for i=1:1:length(dataTmp.trial)
  data.experimenter.trial{i} = dataTmp.trial{i}(24:48,:);
end

data.child = dataTmp;
data.child.label = strrep(dataTmp.label(1:23), '_1', '');
for i=1:1:length(dataTmp.trial)                                           
  data.child.trial{i} = dataTmp.trial{i}(1:23,:);
end

end
