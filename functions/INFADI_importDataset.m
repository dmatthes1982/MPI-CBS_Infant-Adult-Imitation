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

  for i = size(cfg.trl):-1:2                                                % reject duplicates
    if cfg.trl(i,4) == cfg.trl(i-1,4)
      cfg.trl(i-1,:) = [];
    end
  end
  
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
dataTmp = ft_preprocessing(cfg);                                            % import data

data.experimenter = dataTmp;                                                % split dataset into two datasets, one for each participant
data.experimenter.label = strrep(dataTmp.label(33:64), '_2', '');
for i=1:1:length(dataTmp.trial)
  data.experimenter.trial{i} = dataTmp.trial{i}(33:64,:);
end

data.child = dataTmp;
data.child.label = strrep(dataTmp.label(1:30), '_1', '');                   % V2 is not used with childs, hence V1 has no meaning
for i=1:1:length(dataTmp.trial)                                           
  data.child.trial{i} = dataTmp.trial{i}(1:30,:);                           % as a result both will be removed from the childs dataset  
end

end
