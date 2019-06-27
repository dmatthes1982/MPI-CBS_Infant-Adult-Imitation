function [ data_peak ] = INFADI_findPeak(cfg)
% INFADI_FINDPEAK searches for peaks in a certain passband of single or
% multiple electrodes. The most prominent peak will be returned.
%
% Use as
%   [ data_peak ] = INFADI_findPeak( cfg )
%
% where the input data is the result from RA_POW
%
% The configuration options are
%   cfg.srcFolder   = source folder (default: '/data/pt_01905/eegData/DualEEG_INFADI_processedData/08b_pwelch/')
%   cfg.sessionStr  = session string (default: '001')
%   cfg.part        = participant identifier, options: 'experimenter' or 'child' (default: 'child')
%   cfg.condition   = options: 'WarmUpPhase', 'Baseline', 'ContImi' or 'ContOtherAct' (default: 'WarmUpPhase', 5)
%                     the equivalent conditions numbers 5,4,2,3 can also be used with cfg.condition
%   cfg.freqrange   = frequency range: [begin end], unit = Hz (default: [6 9])
%   cfg.electrode   = select a certain or multiple components (i.e. 'C3', 'P4', {'C3', 'P4'}, 9, 20, [9, 20]),
%                     channel labels as well as channel numbers are supported (default: 'C3'),
%                     if multiple components are defined, the averaged signal will be used for peak detection
%
% This function requires the fieldtrip toolbox
%
% See also FINDPEAKS

% Copyright (C) 2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get config options
% -------------------------------------------------------------------------
srcFolder   = ft_getopt(cfg, 'srcFolder', '/data/pt_01905/eegData/DualEEG_INFADI_processedData/08b_pwelch/');
sessionStr  = ft_getopt(cfg, 'sessionStr', '001');
part        = ft_getopt(cfg, 'part', 'child');
condition   = ft_getopt(cfg, 'condition', 'WarmUpPhase');
freqrange   = ft_getopt(cfg, 'freqrange', [6 9]);
elec        = ft_getopt(cfg, 'electrode', {'C3'});

% -------------------------------------------------------------------------
% Path settings
% -------------------------------------------------------------------------
fprintf('Select Dyads...\n\n');
fileList     = dir([srcFolder 'INFADI_d*_08b_pwelch_' sessionStr '.mat']);
fileList     = struct2cell(fileList);
fileList     = fileList(1,:);                                               % generate list with file names of all existing dyads
numOfFiles   = length(fileList);

listOfDyad = zeros(numOfFiles, 1);

for i = 1:1:numOfFiles
  listOfDyad(i) = sscanf(fileList{i}, ['INFADI_d%d_08b_pwelch_' ...         % generate a list of all available numbers of dyads
                                        sessionStr '.mat']);
end

listOfDyadStr = num2cell(listOfDyad);
listOfDyadStr = cellfun(@(x) num2str(x), listOfDyadStr, ...
                        'UniformOutput', false);
dyad = listdlg('ListString', listOfDyadStr);                                % open the dialog window --> the user can select the dyads of interest

fileList      = fileList(ismember(1:1:numOfFiles, dyad));                   % reduce file list to selection
listOfDyad    = listOfDyad(ismember(1:1:numOfFiles, dyad));
numOfFiles    = length(fileList);                                           % estimate actual number of files (participants)

% -------------------------------------------------------------------------
% Check part, condition, freqrange and electrode
% -------------------------------------------------------------------------
filepath = fileparts(mfilename('fullpath'));
addpath(sprintf('%s/utilities', filepath));

if ~ismember(part, {'experimenter', 'child'})                               % check cfg.part definition
  error('cfg.part has to be either ''experimenter'' or ''child''.');
end

condition = INFADI_checkCondition( condition );                             % check cfg.condition definition and translate it into trl number    

if(length(freqrange) ~= 2)
  error('Specify a frequency range: [freqLow freqHigh]');
end

load([srcFolder fileList{1}], 'data_pwelch');                               % load data of first dyad

switch part                                                                 % extract data of specified participant
  case 'experimenter'
    data_pwelch = data_pwelch.experimenter;                                 %#ok<NODEF>
  case 'child'
    data_pwelch = data_pwelch.child;                                        %#ok<NODEF>
end

begCol = find(data_pwelch.freq >= freqrange(1), 1, 'first');                % estimate desired powspctrm colums
endCol = find(data_pwelch.freq <= freqrange(2), 1, 'last');

label     = data_pwelch.label;                                              % get labels 
if isnumeric(elec)                                                          % check cfg.electrode
  for i=1:length(elec)
    if elec(i) < 1 || elec(i) > 32
      error('cfg.elec has to be a numbers between 1 and 32 or a existing labels like {''Cz''}.');
    end
  end
else
  tmpElec = zeros(1, length(elec));
  for i=1:length(elec)
    tmpElec(i) = find(strcmp(label, elec{i}));
    if isempty(tmpElec(i))
      error('cfg.elec has to be a cell array of existing labels like ''Cz''or a vector of numbers between 1 and 32.');
    end
  end
  elec = tmpElec;
end

labelString = data_pwelch.label(elec);

if begCol == endCol
  error('Selected range results in one frequency, please select a larger range');
else
  freqCols = begCol:endCol;
  actFreqRange = data_pwelch.freq(begCol:endCol);                           % Calculate actual frequency range
end

clear data_pwelch

% -------------------------------------------------------------------------
% Find largest peak in specified range
% -------------------------------------------------------------------------
peakFreq{numOfFiles} = [];

f = waitbar(0,'Please wait...');

for i=1:1:numOfFiles
  load([srcFolder fileList{i}], 'data_pwelch');
  waitbar(i/numOfFiles, f, 'Please wait...');
  
  switch part                                                               % extract data of specified participant
    case 'experimenter'
      data_pwelch = data_pwelch.experimenter;
    case 'child'
      data_pwelch = data_pwelch.child;
  end
  
  trl = find(data_pwelch.trialinfo == condition, 1);                        % if condition is existing
  if ~isempty(trl)
    data = squeeze(mean(data_pwelch.powspctrm(trl, elec, freqCols),1));
    [pks, locs, ~, p] = findpeaks(data);
    if length(pks) > 1
      [~, maxLocs] = max(p);                                                % select always the most prominent peak
      peakFreq{i} = actFreqRange(locs(maxLocs));
    else
      peakFreq{i} = actFreqRange(locs);
    end
  end
  
  clear data_pwelch
end

close(f);                                                                   % close waitbar

data_peak.part      = part;
data_peak.condition = condition;
data_peak.label     = labelString;
data_peak.freq      = actFreqRange;
data_peak.dyad      = listOfDyad';
data_peak.peakFreq  = peakFreq;

end
