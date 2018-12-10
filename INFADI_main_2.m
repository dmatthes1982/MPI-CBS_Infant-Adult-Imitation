%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subFolder = '01_raw/';
  cfg.filename  = 'INFADI_d01_01_raw';
  sessionStr    = sprintf('%03d', INFADI_getSessionNum( cfg ));             % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01905/eegData/DualEEG_INFADI_processedData/';         % destination path for processed data
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in segmented data folder
  sourceList    = dir([strcat(desPath, '01_raw/'), ...
                       strcat('*_', sessionStr, '.mat')]);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                    strcat('INFADI_d%d_01_raw_', sessionStr, '.mat'));
  end
end

%% part 2
% 1. select bad/noisy channels
% 2. filter the good channels (basic bandpass filtering)

cprintf([1,0.4,1], '<strong>[2] - Preproc I: bad channel detection, filtering</strong>\n');
fprintf('\n');

% Create settings file if not existing
settings_file = [desPath '00_settings/' ...
                  sprintf('settings_%s', sessionStr) '.xls'];
if ~(exist(settings_file, 'file') == 2)                                     % check if settings file already exist
  cfg = [];
  cfg.desFolder   = [desPath '00_settings/'];
  cfg.type        = 'settings';
  cfg.sessionStr  = sessionStr;
  
  INFADI_createTbl(cfg);                                                    % create settings file
end

% Load settings file
T = readtable(settings_file);
warning off;
T.dyad(numOfPart) = numOfPart;
warning on;

for i = numOfPart
  fprintf('<strong>Dyad %d</strong>\n\n', i);

  %% selection of corrupted channels %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('<strong>Selection of corrupted channels</strong>\n\n');

  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '01_raw/');
  cfg.filename    = sprintf('INFADI_d%02d_01_raw', i);
  cfg.sessionStr  = sessionStr;

  fprintf('Load raw data...\n');
  INFADI_loadData( cfg );
  
  % concatenated raw trials to a continuous stream
  cfg = [];
  cfg.part = 'both';

  data_continuous = INFADI_concatData( cfg, data_raw );

  fprintf('\n');

  % detect noisy channels automatically
  data_noisy = INFADI_estNoisyChan( data_continuous );

  fprintf('\n');

  % select corrupted channels
  data_badchan = INFADI_selectBadChan( data_continuous, data_noisy );
  clear data_noisy

  % export the bad channels in a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '02a_badchan/');
  cfg.filename    = sprintf('INFADI_d%02d_02a_badchan', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('Bad channels of dyad %d will be saved in:\n', i);
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_badchan', data_badchan);
  fprintf('Data stored!\n\n');
  clear data_continuous

  % add bad labels of bad channels to the settings file
  if isempty(data_badchan.experimenter.badChan)
    badChanPart1 = {'---'};
  else
    badChanPart1 = {strjoin(data_badchan.experimenter.badChan,',')};
  end
  if isempty(data_badchan.child.badChan)
    badChanPart2 = {'---'};
  else
    badChanPart2 = {strjoin(data_badchan.child.badChan,',')};
  end
  warning off;
  T.badChanPart1(i) = badChanPart1;
  T.badChanPart2(i) = badChanPart2;
  warning on;

  % store settings table
  delete(settings_file);
  writetable(T, settings_file);

  %% basic bandpass filtering of good channels %%%%%%%%%%%%%%%%%%%%%%%%%%%%
  fprintf('<strong>Basic preprocessing of good channels</strong>\n');

  cfg                   = [];
  cfg.bpfreq            = [1 48];                                           % passband from 1 to 48 Hz
  cfg.bpfilttype        = 'but';
  cfg.bpinstabilityfix  = 'split';
  cfg.expBadChan        = data_badchan.experimenter.badChan';
  cfg.childBadChan      = data_badchan.child.badChan';

  ft_info off;
  data_preproc1 = INFADI_preprocessing( cfg, data_raw);
  ft_info on;

  cfg             = [];
  cfg.desFolder   = strcat(desPath, '02b_preproc1/');
  cfg.filename    = sprintf('INFADI_d%02d_02b_preproc1', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');

  fprintf('The bandpass filtered data of dyad %d will be saved in:\n', i);
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_preproc1', data_preproc1);
  fprintf('Data stored!\n\n');
  clear data_preproc1 data_raw data_badchan
end

%% clear workspace
clear file_path cfg sourceList numOfSources i selection badChanPart1 ...
      badChanPart2 T settings_file
