%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subfolder = '04c_preproc2';
  cfg.filename  = 'INFADI_d01_04c_preproc2';
  sessionStr    = sprintf('%03d', INFADI_getSessionNum( cfg ));             % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01905/eegData/DualEEG_INFADI_processedData/';         % destination path for processed data
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in eyecor data folder
  sourceList    = dir([strcat(desPath, '04c_preproc2/'), ...
                       strcat('*_', sessionStr, '.mat')]);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                    strcat('INFADI_d%d_04c_preproc2_', sessionStr, '.mat'));
  end
end

%% part 8
% 1. Calculate TFRs of the preprocessed data
% 2. Calculate the power scpectrum of the processed data

cprintf([1,0.4,1], '<strong>[8] - Power analysis (TFR, pWelch)</strong>\n');
fprintf('\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculation of time-frequency response (TFR)
choise = false;
while choise == false
  cprintf([1,0.4,1], 'Should the time-frequency response calculated?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    choise = true;
    tfr = true;
  elseif strcmp('n', x)
    choise = true;
    tfr = false;
  else
    choise = false;
  end
end
fprintf('\n');

if tfr == true
  for i = numOfPart
    fprintf('<strong>Dyad %d</strong>\n', i);

    cfg             = [];                                                   % load preprocessed data
    cfg.srcFolder   = strcat(desPath, '04c_preproc2/');
    cfg.sessionStr  = sessionStr;
    cfg.filename    = sprintf('INFADI_d%02d_04c_preproc2', i);

    fprintf('Load preprocessed data...\n\n');
    INFADI_loadData( cfg );

    cfg         = [];
    cfg.foi     = 2:1:50;                                                   % frequency of interest
    cfg.toi     = 0:0.5:200;                                                % time of interest

    data_tfr = INFADI_timeFreqanalysis( cfg, data_preproc2 );

    % export TFR data into a *.mat file
    cfg             = [];
    cfg.desFolder   = strcat(desPath, '08a_tfr/');
    cfg.filename    = sprintf('INFADI_d%02d_08a_tfr', i);
    cfg.sessionStr  = sessionStr;

    file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                       '.mat');

    fprintf('Time-frequency response data of dyad %d will be saved in:\n', i); 
    fprintf('%s ...\n', file_path);
    INFADI_saveData(cfg, 'data_tfr', data_tfr);
    fprintf('Data stored!\n\n');
    clear data_tfr data_preproc2
  end
end

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Calculation of the power spectrum using Welch's method (pWelch)
choise = false;
while choise == false
  cprintf([1,0.4,1], 'Should the power spectrum by using Welch''s method be calculated?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    choise = true;
    pwelch = true;
  elseif strcmp('n', x)
    choise = true;
    pwelch = false;
  else
    choise = false;
  end
end
fprintf('\n');

if pwelch == true
  choise = false;
  while choise == false
    cprintf([1,0.4,1], 'Should rejection of detected artifacts be applied before power estimation?\n');
    x = input('Select [y/n]: ','s');
    if strcmp('y', x)
      choise = true;
      artifactRejection = true;
    elseif strcmp('n', x)
      choise = true;
      artifactRejection = false;
    else
      choise = false;
    end
  end
  fprintf('\n');

  selection = false;
  while selection == false
    cprintf([1,0.4,1], 'Please select segmentation size for pwelch estimation:\n');
    fprintf('[1] - 1 sec \n');
    fprintf('[2] - 2 sec \n');
    y = input('Option: ');

    switch y
      case 1
        selection = true;
        seglength = 1;
      case 2
        selection = true;
        seglength = 2;
      otherwise
        cprintf([1,0.5,0], 'Wrong input!\n');
    end
  end
  fprintf('\n');

  selection = false;
  while selection == false
    cprintf([1,0.4,1], 'Please select segmentation overlap for pwelch estimation:\n');
    fprintf('[1] - 0.50 %%\n');
    fprintf('[2] - 0.75 %%\n');
    if( seglength == 2 )
      fprintf('[3] - 0.875 %%\n');
    end
    y = input('Option: ');

    if y == 1
      selection = true;
      overlap = 0.5;
    elseif y == 2
      selection = true;
      overlap = 0.75;
    elseif y == 3 && seglength == 2
      selection = true;
      overlap = 0.875;
    else
      cprintf([1,0.5,0], 'Wrong input!\n\n');
    end
  end
  fprintf('\n');
  
  % Write selected settings to settings file
  file_path = [desPath '00_settings/' sprintf('settings_%s', sessionStr) '.xls'];
  if ~(exist(file_path, 'file') == 2)                                       % check if settings file already exist
    cfg = [];
    cfg.desFolder   = [desPath '00_settings/'];
    cfg.type        = 'settings';
    cfg.sessionStr  = sessionStr;
  
    INFADI_createTbl(cfg);                                                  % create settings file
  end

  T = readtable(file_path);                                                 % update settings table
  warning off;
  T.artRejectPow(numOfPart) = { x };
  T.powSeglength(numOfPart) = seglength;
  T.powOverlap(numOfPart)   = overlap;
  warning on;
  delete(file_path);
  writetable(T, file_path);
  
  for i = numOfPart
    fprintf('<strong>Dyad %d</strong>\n', i);
    
    % Load preprocessed data
    cfg             = [];
    cfg.srcFolder   = strcat(desPath, '04c_preproc2/');
    cfg.filename    = sprintf('INFADI_d%02d_04c_preproc2', i);
    cfg.sessionStr  = sessionStr;

    fprintf('Load preprocessed data...\n\n');
    INFADI_loadData( cfg );
    
    % Segmentation of conditions in segments of x seconds with yy percent
    % overlapping
    cfg          = [];
    cfg.length   = seglength;                                               % window length
    cfg.overlap  = overlap;                                                 % overlap
    
    fprintf('<strong>Segmentation of preprocessed data.</strong>\n');
    data_preproc2 = INFADI_segmentation( cfg, data_preproc2 );

    numOfAllSeg = INFADI_numOfSeg( data_preproc2 );                         % estimate number of segments for each existing condition and participant

    fprintf('\n');
    
    % Load artifact definitions 
    if artifactRejection == true
      cfg             = [];
      cfg.srcFolder   = strcat(desPath, '05b_allart/');
      cfg.filename    = sprintf('INFADI_d%02d_05b_allart', i);
      cfg.sessionStr  = sessionStr;

      file_path = strcat(cfg.srcFolder, cfg.filename, '_', cfg.sessionStr, ...
                       '.mat');
      if ~isempty(dir(file_path))
        fprintf('Loading %s ...\n', file_path);
        INFADI_loadData( cfg );                                                  
        artifactAvailable = true;     
      else
        fprintf('File %s is not existent,\n', file_path);
        fprintf('Artifact rejection is not possible!\n');
        artifactAvailable = false;
      end
    fprintf('\n');  
    end
    
    % Artifact rejection
    if artifactRejection == true
      if artifactAvailable == true
        cfg           = [];
        cfg.artifact  = cfg_allart;
        cfg.reject    = 'complete';
        cfg.target    = 'single';

        fprintf('<strong>Artifact Rejection with preprocessed data.</strong>\n');
        data_preproc2 = INFADI_rejectArtifacts(cfg, data_preproc2);
        fprintf('\n');
      end
      
      clear cfg_allart
    end
    
    numOfGoodSeg = INFADI_numOfSeg( data_preproc2);                         % estimate number of remaining segments (after artifact rejection) for each existing condition and participant

    % Estimation of power spectrum
    cfg         = [];
    cfg.foi     = 1/seglength:1/seglength:50;                               % frequency of interest
      
    data_preproc2 = INFADI_pWelch( cfg, data_preproc2 );                    % calculate power activity using Welch's method
    data_pwelch = data_preproc2;                                            % to save need of RAM
    data_pwelch.experimenter.numOfAllSeg  = numOfAllSeg.experimenter;       % add number of segments of each existing condition
    data_pwelch.child.numOfAllSeg         = numOfAllSeg.child;
    data_pwelch.experimenter.numOfGoodSeg = numOfGoodSeg.experimenter;      % add number of clean segments of each existing condition
    data_pwelch.child.numOfGoodSeg        = numOfGoodSeg.child;
    clear data_preproc2
    
    % export number of good trials into a spreadsheet
    cfg           = [];
    cfg.desFolder = [desPath '00_settings/'];
    cfg.dyad = i;
    cfg.type = 'pwelch';
    cfg.sessionStr = sessionStr;
    INFADI_writeTbl(cfg, data_pwelch);

    % export power spectrum into a *.mat file
    cfg             = [];
    cfg.desFolder   = strcat(desPath, '08b_pwelch/');
    cfg.filename    = sprintf('INFADI_d%02d_08b_pwelch', i);
    cfg.sessionStr  = sessionStr;

    file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                       '.mat');

    fprintf('The Power spectrum of dyad %d will be saved in:\n', i);
    fprintf('%s ...\n', file_path);
    INFADI_saveData(cfg, 'data_pwelch', data_pwelch);
    fprintf('Data stored!\n\n');
    clear data_pwelch
  end
end

%% clear workspace
clear file_path cfg sourceList numOfSources i choise tfr pwelch T ...
      artifactRejection artifactAvailable numOfAllSeg numOfGoodSeg ...
      seglength overlap x y
