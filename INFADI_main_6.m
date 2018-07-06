%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subFolder = '04b_eyecor/';
  cfg.filename  = 'INFADI_d01_04b_eyecor';
  sessionStr    = sprintf('%03d', INFADI_getSessionNum( cfg ));             % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01905/eegData/DualEEG_INFADI_processedData/';         % destination path for processed data 
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in eyecor data folder
  sourceList    = dir([strcat(desPath, '04b_eyecor/'), ...
                       strcat('*_', sessionStr, '.mat')]);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                    strcat('INFADI_d%d_04b_eyecor_', sessionStr, '.mat'));
  end
end

%% part 6

cprintf([1,0.4,1], '<strong>[6] - Narrow band filtering and Hilbert transform</strong>\n');
fprintf('\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% bandpass filtering

for i = numOfPart
  fprintf('<strong>Dyad %d</strong>\n', i);
  
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '04b_eyecor/');
  cfg.filename    = sprintf('INFADI_d%02d_04b_eyecor', i);
  cfg.sessionStr  = sessionStr;
  
  fprintf('Load eye-artifact corrected data...\n\n');
  INFADI_loadData( cfg );
  
  filtCoeffDiv = 500 / data_eyecor.experimenter.fsample;                    % estimate sample frequency dependent divisor of filter length

  % bandpass filter data at theta (4-7 Hz)
  cfg           = [];
  cfg.bpfreq    = [4 7];
  cfg.filtorder = fix(500 / filtCoeffDiv);
  cfg.channel   = {'all', '-REF', '-EOGV', '-EOGH', '-V1', '-V2'};
  
  data_bpfilt_theta = INFADI_bpFiltering(cfg, data_eyecor);
  
  % export the filtered data into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '06a_bpfilt/');
  cfg.filename    = sprintf('INFADI_d%02d_06a_bpfiltTheta', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving bandpass filtered data (theta: 4-7Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_bpfilt_theta', data_bpfilt_theta);
  fprintf('Data stored!\n\n');
  clear data_bpfilt_theta
  
  % bandpass filter data at alpha (8-12 Hz)
  cfg           = [];
  cfg.bpfreq    = [8 12];
  cfg.filtorder = fix(250 / filtCoeffDiv);
  cfg.channel   = {'all', '-REF', '-EOGV', '-EOGH', '-V1', '-V2'};
  
  data_bpfilt_alpha = INFADI_bpFiltering(cfg, data_eyecor);
  
  % export the filtered data into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '06a_bpfilt/');
  cfg.filename    = sprintf('INFADI_d%02d_06a_bpfiltAlpha', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving bandpass filtered data (alpha: 8-12Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_bpfilt_alpha', data_bpfilt_alpha);
  fprintf('Data stored!\n\n');
  clear data_bpfilt_alpha

  % bandpass filter data at beta (13-30Hz)
  cfg           = [];
  cfg.bpfreq    = [13 30];
  cfg.filtorder = fix(250 / filtCoeffDiv);
  cfg.channel   = {'all', '-REF', '-EOGV', '-EOGH', '-V1', '-V2'};
  
  data_bpfilt_beta = INFADI_bpFiltering(cfg, data_eyecor);

  % export the filtered data into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '06a_bpfilt/');
  cfg.filename    = sprintf('INFADI_d%02d_06a_bpfiltBeta', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving bandpass filtered data (beta: 13-30Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_bpfilt_beta', data_bpfilt_beta);
  fprintf('Data stored!\n\n');
  clear data_bpfilt_beta
  
  % bandpass filter data at gamma (31-48Hz)
  cfg           = [];
  cfg.bpfreq    = [31 48];
  cfg.filtorder = fix(250 / filtCoeffDiv);
  cfg.channel   = {'all', '-REF', '-EOGV', '-EOGH', '-V1', '-V2'};
  
  data_bpfilt_gamma = INFADI_bpFiltering(cfg, data_eyecor);

  % export the filtered data into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '06a_bpfilt/');
  cfg.filename    = sprintf('INFADI_d%02d_06a_bpfiltGamma', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving bandpass filtered data (beta: 31-48Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_bpfilt_gamma', data_bpfilt_gamma);
  fprintf('Data stored!\n\n');
  clear data_bpfilt_gamma data_eyecor
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% hilbert phase calculation

for i = numOfPart
  fprintf('<strong>Dyad %d</strong>\n\n', i);
    
  % calculate hilbert phase at theta (4-7Hz)
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '06a_bpfilt/');
  cfg.filename    = sprintf('INFADI_d%02d_06a_bpfiltTheta', i);
  cfg.sessionStr  = sessionStr;
  fprintf('Load the at theta (4-7Hz) bandpass filtered data...\n');
  INFADI_loadData( cfg );
  
  data_hilbert_theta = INFADI_hilbertPhase(data_bpfilt_theta);
  
  % export the hilbert phase data into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '06b_hilbert/');
  cfg.filename    = sprintf('INFADI_d%02d_06b_hilbertTheta', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving Hilbert phase data (theta: 4-7Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_hilbert_theta', data_hilbert_theta);
  fprintf('Data stored!\n\n');
  clear data_hilbert_theta data_bpfilt_theta
  
  % calculate hilbert phase at alpha (8-12Hz)
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '06a_bpfilt/');
  cfg.filename    = sprintf('INFADI_d%02d_06a_bpfiltAlpha', i);
  cfg.sessionStr  = sessionStr;
  fprintf('Load the at alpha (8-12Hz) bandpass filtered data ...\n');
  INFADI_loadData( cfg );
  
  data_hilbert_alpha = INFADI_hilbertPhase(data_bpfilt_alpha);
  
  % export the hilbert phase data into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '06b_hilbert/');
  cfg.filename    = sprintf('INFADI_d%02d_06b_hilbertAlpha', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving Hilbert phase data (alpha: 8-12Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_hilbert_alpha', data_hilbert_alpha);
  fprintf('Data stored!\n\n');
  clear data_hilbert_alpha data_bpfilt_alpha
  
  % calculate hilbert phase at beta (13-30Hz)
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '06a_bpfilt/');
  cfg.filename    = sprintf('INFADI_d%02d_06a_bpfiltBeta', i);
  cfg.sessionStr  = sessionStr;
  fprintf('Load the at beta (13-30 Hz) bandpass filtered data ...\n');
  INFADI_loadData( cfg );
  
  data_hilbert_beta = INFADI_hilbertPhase(data_bpfilt_beta);
  
  % export the hilbert phase data into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '06b_hilbert/');
  cfg.filename    = sprintf('INFADI_d%02d_06b_hilbertBeta', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving Hilbert phase data (beta: 13-30Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_hilbert_beta', data_hilbert_beta);
  fprintf('Data stored!\n\n');
  clear data_hilbert_beta data_bpfilt_beta
  
  % calculate hilbert phase at gamma (31-48Hz)
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '06a_bpfilt/');
  cfg.filename    = sprintf('INFADI_d%02d_06a_bpfiltGamma', i);
  cfg.sessionStr  = sessionStr;
  fprintf('Load the at gamma (31-48 Hz) bandpass filtered data ...\n');
  INFADI_loadData( cfg );
  
  data_hilbert_gamma = INFADI_hilbertPhase(data_bpfilt_gamma);
  
  % export the hilbert phase data into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '06b_hilbert/');
  cfg.filename    = sprintf('INFADI_d%02d_06b_hilbertGamma', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving Hilbert phase data (gamma: 31-48Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_hilbert_gamma', data_hilbert_gamma);
  fprintf('Data stored!\n\n');
  clear data_hilbert_gamma data_bpfilt_gamma
end

%% clear workspace
clear cfg file_path numOfSources sourceList i filtCoeffDiv 
