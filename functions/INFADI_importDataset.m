function [ data ] = INFADI_importDataset(cfg)
% INFADI_IMPORTDATASET imports one specific dataset recorded with a device 
% from brain vision.
%
% Use as
%   [ data ] = INFADI_importDataset(cfg)
%
% The configuration options are
%   cfg.path          = source path' (i.e. '/data/pt_01905/eegData/DualEEG_INFADI_rawData/')
%   cfg.dyad          = number of dyad
%   cfg.noichan       = channels which are not of interest (default: [])
%   cfg.continuous    = 'yes' or 'no' (default: 'no')
%   cfg.prestim       = define pre-Stimulus offset in seconds (default: 0)
%   cfg.rejectoverlap = reject first of two overlapping trials, 'yes' or 'no' (default: 'yes')
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
noichan       = ft_getopt(cfg, 'noichan', []);
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
  eventvalues   = generalDefinitions.condMark;
  stopvalues    = generalDefinitions.stopMark;
              
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

  cfg = ft_definetrial(cfg);                                                % extract condition marker
  if isfield(cfg, 'notification')
    cfg = rmfield(cfg, {'notification'});                                   % workarround for mergeconfig bug
  end

  cfgStop                     = [];
  cfgStop.dataset             = headerfile;
  cfgStop.trialfun            = 'ft_trialfun_general';
  cfgStop.trialdef.eventtype  = 'Stimulus';
  cfgStop.trialdef.prestim    = prestim;
  cfgStop.showcallinfo        = 'no';
  cfgStop.feedback            = 'error';
  cfgStop.trialdef.eventvalue = stopvalues;

  cfgStop = ft_definetrial(cfgStop);                                        % extract stop marker

  for i = 1:1:size(cfg.trl, 1) - 1                                          % generate config for segmentation
    row = find((cfg.trl(i, 1) < cfgStop.trl(:,1)) & ...
                (cfg.trl(i+1, 1) > cfgStop.trl(:,1)), 1);
    if ~isempty(row)
      cfg.trl(i,2) = cfgStop.trl(row,1);
    else
      error('Some stop markers are missing, modify the corresponding vmrk files first!');
    end
  end
  row = find((cfg.trl(end, 1) < cfgStop.trl(:,1)), 1);
  if ~isempty(row)
    cfg.trl(end,2) = cfgStop.trl(row,1);
  else
    error('Some stop markers are missing, modify the corresponding vmrk files first!');
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
if ~isempty(noichan)
  noichan = cellfun(@(x) strcat('-', x), noichan, ...
                          'UniformOutput', false);
  noichanp1 = cellfun(@(x) strcat(x, '_1'), noichan, ...
                          'UniformOutput', false);
  noichanp2 = cellfun(@(x) strcat(x, '_2'), noichan, ...
                          'UniformOutput', false);
  cfg.channel = [{'all'} noichanp1 noichanp2 ...                            % exclude channels which are not of interest
                {'-V2_1'}];                                                 % V2 is not connected with children, reject them always
else
  cfg.channel = {'all', '-V2_1'};
end

dataTmp = ft_preprocessing(cfg);                                            % import data

numOfChan = (numel(dataTmp.label) - 1)/2;

data.experimenter = dataTmp;                                                % split dataset into two datasets, one for each participant
data.experimenter.label = strrep(dataTmp.label(numOfChan+1:end), '_2', '');
for i=1:1:length(dataTmp.trial)
  data.experimenter.trial{i} = dataTmp.trial{i}(numOfChan+1:end,:);
end

data.child = dataTmp;
data.child.label = strrep(dataTmp.label(1:numOfChan), '_1', '');
for i=1:1:length(dataTmp.trial)                                           
  data.child.trial{i} = dataTmp.trial{i}(1:numOfChan,:);
end

end
