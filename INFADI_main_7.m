%% check if basic variables are defined
if ~exist('sessionStr', 'var')
  cfg           = [];
  cfg.subFolder = '06b_hilbert/';
  cfg.filename  = 'INFADI_d01_06b_hilbertGamma';
  sessionStr    = sprintf('%03d', INFADI_getSessionNum( cfg ));             % estimate current session number
end

if ~exist('desPath', 'var')
  desPath = '/data/pt_01905/eegData/DualEEG_INFADI_processedData/';         % destination path for processed data  
end

if ~exist('numOfPart', 'var')                                               % estimate number of participants in segmented data folder
  sourceList    = dir([strcat(desPath, '06b_hilbert/'), ...
                       strcat('*Gamma_', sessionStr, '.mat')]);
  sourceList    = struct2cell(sourceList);
  sourceList    = sourceList(1,:);
  numOfSources  = length(sourceList);
  numOfPart     = zeros(1, numOfSources);

  for i=1:1:numOfSources
    numOfPart(i)  = sscanf(sourceList{i}, ...
                    strcat('INFADI_d%d_06b_hilbertGamma_', sessionStr, '.mat'));
  end
end

%% part 7
% 1. Segmentation of the hilbert phase data trials for PLV estimation.
%    Split the data of every condition into subtrials with a length of 5 
%    or 1 seconds
% 2. Artifact rejection
% 3. PLV estimation
% 4. mPLV estimation

cprintf([1,0.4,1], '<strong>[7] - Estimation of Phase Locking Values (PLV)</strong>\n');
fprintf('\n');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% general adjustment
choise = false;
while choise == false
  cprintf([1,0.4,1], 'Should rejection of detected artifacts be applied before PLV estimation?\n');
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

% Write selected settings to settings file
file_path = [desPath '00_settings/' sprintf('settings_%s', sessionStr) '.xls'];
if ~(exist(file_path, 'file') == 2)                                         % check if settings file already exist
  cfg = [];
  cfg.desFolder   = [desPath '00_settings/'];
  cfg.type        = 'settings';
  cfg.sessionStr  = sessionStr;
  
  INFADI_createTbl(cfg);                                                    % create settings file
end

T = readtable(file_path);                                                   % update settings table
warning off;
T.artRejectPLV(numOfPart) = { x };
warning on;
delete(file_path);
writetable(T, file_path);

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%% Segmentation, artifact rejection, PLV and mPLV estimation
for i = numOfPart
  fprintf('<strong>Dyad %d</strong>\n\n', i);
  
  %% Load Artifact definitions %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
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
  
  %% theta branch %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % load hilbert phase data at theta %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '06b_hilbert/');
  cfg.sessionStr  = sessionStr;
  cfg.filename    = sprintf('INFADI_d%02d_06b_hilbertTheta', i);
  fprintf('Load hilbert phase data at theta (4-7Hz)...\n');
  INFADI_loadData( cfg );
  
  % segmentation at theta %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg           = [];
  cfg.length    = 5;
  cfg.overlap   = 0;
  
  fprintf('<strong>Segmentation of Hilbert phase data at theta (4-7Hz).</strong>\n');
  data_hilbert_theta  = INFADI_segmentation( cfg, data_hilbert_theta );
  
  % artifact rejection at theta %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if artifactRejection == true
    if artifactAvailable == true
      cfg           = [];
      cfg.artifact  = cfg_allart;
      cfg.reject    = 'complete';
      cfg.target    = 'dual';
  
      fprintf('<strong>Artifact Rejection of Hilbert phase data at theta (4-7Hz).</strong>\n');
      data_hilbert_theta = INFADI_rejectArtifacts(cfg, data_hilbert_theta);
      fprintf('\n');
    end
  end
  
  % calculate PLV and meanPLV at theta %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg           = [];
  cfg.winlen    = 5;                                                        % window length for one PLV value in seconds
  
  data_plv_theta  = INFADI_phaseLockVal(cfg, data_hilbert_theta);
  data_mplv_theta = INFADI_calcMeanPLV(data_plv_theta);
  clear data_hilbert_theta
  
  % export number of good trials into a spreadsheet
  cfg           = [];
  cfg.desFolder = [desPath '00_settings/'];
  cfg.dyad = i;
  cfg.type = 'plv';
  cfg.param = 'theta';
  cfg.sessionStr = sessionStr;
  INFADI_writeTbl(cfg, data_plv_theta);
  
  % export the PLVs into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '07a_plv/');
  cfg.filename    = sprintf('INFADI_d%02d_07a_plvTheta', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving PLVs (theta: 4-7Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_plv_theta', data_plv_theta);
  fprintf('Data stored!\n');
  clear data_plv_theta
  
  % export the mean PLVs into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '07b_mplv/');
  cfg.filename    = sprintf('INFADI_d%02d_07b_mplvTheta', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving mean PLVs (theta: 4-7Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_mplv_theta', data_mplv_theta);
  fprintf('Data stored!\n\n');
  clear data_mplv_theta
  
  %% alpha branch %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % load hilbert phase data at alpha %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '06b_hilbert/');
  cfg.sessionStr  = sessionStr;
  cfg.filename    = sprintf('INFADI_d%02d_06b_hilbertAlpha', i);
  fprintf('Load hilbert phase data at alpha (8-12Hz)...\n');
  INFADI_loadData( cfg );

  % segmentation at alpha %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg           = [];
  cfg.length    = 1;
  cfg.overlap   = 0;
  
  fprintf('<strong>Segmentation of Hilbert phase data at alpha (8-12Hz).</strong>\n');
  data_hilbert_alpha  = INFADI_segmentation( cfg, data_hilbert_alpha );
  
  % artifact rejection at alpha %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if artifactRejection == true
    if artifactAvailable == true
      cfg           = [];
      cfg.artifact  = cfg_allart;
      cfg.reject    = 'complete';
      cfg.target    = 'dual';
  
      fprintf('<strong>Artifact Rejection of Hilbert phase data at alpha (8-12Hz).</strong>\n');
      data_hilbert_alpha = INFADI_rejectArtifacts(cfg, data_hilbert_alpha);
      fprintf('\n');
    end
  end
  
  % calculate PLV and meanPLV at alpha %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg           = [];
  cfg.winlen    = 1;                                                        % window length for one PLV value in seconds
  
  data_plv_alpha  = INFADI_phaseLockVal(cfg, data_hilbert_alpha);
  data_mplv_alpha = INFADI_calcMeanPLV(data_plv_alpha);
  clear data_hilbert_alpha
  
  % export number of good trials into a spreadsheet
  cfg           = [];
  cfg.desFolder = [desPath '00_settings/'];
  cfg.dyad = i;
  cfg.type = 'plv';
  cfg.param = 'alpha';
  cfg.sessionStr = sessionStr;
  INFADI_writeTbl(cfg, data_plv_alpha);
  
  % export the PLVs into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '07a_plv/');
  cfg.filename    = sprintf('INFADI_d%02d_07a_plvAlpha', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving PLVs (alpha: 8-12Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_plv_alpha', data_plv_alpha);
  fprintf('Data stored!\n');
  clear data_plv_alpha
  
  % export the mean PLVs into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '07b_mplv/');
  cfg.filename    = sprintf('INFADI_d%02d_07b_mplvAlpha', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving mean PLVs (alpha: 8-12Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_mplv_alpha', data_mplv_alpha);
  fprintf('Data stored!\n\n');
  clear data_mplv_alpha
  
  %% beta branch %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % load hilbert phase data at beta %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '06b_hilbert/');
  cfg.sessionStr  = sessionStr;
  cfg.filename    = sprintf('INFADI_d%02d_06b_hilbertBeta', i);
  fprintf('Load hilbert phase data at beta (13-30Hz)...\n');
  INFADI_loadData( cfg );
   
  % segmentation at beta %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg           = [];
  cfg.length    = 1;
  cfg.overlap   = 0;
    
  fprintf('<strong>Segmentation of Hilbert phase data at beta (13-30Hz).</strong>\n');
  data_hilbert_beta  = INFADI_segmentation( cfg, data_hilbert_beta );
  
  % artifact rejection at beta %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if artifactRejection == true
    if artifactAvailable == true
      cfg           = [];
      cfg.artifact  = cfg_allart;
      cfg.reject    = 'complete';
      cfg.target    = 'dual';
  
      fprintf('<strong>Artifact Rejection of Hilbert phase data at beta (13-30Hz).</strong>\n');
      data_hilbert_beta = INFADI_rejectArtifacts(cfg, data_hilbert_beta);
      fprintf('\n');
    end
  end
  
  % calculate PLV and meanPLV at beta %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg           = [];
  cfg.winlen    = 1;                                                        % window length for one PLV value in seconds
  
  data_plv_beta  = INFADI_phaseLockVal(cfg, data_hilbert_beta);
  data_mplv_beta = INFADI_calcMeanPLV(data_plv_beta);
  clear data_hilbert_beta
  
  % export number of good trials into a spreadsheet
  cfg           = [];
  cfg.desFolder = [desPath '00_settings/'];
  cfg.dyad = i;
  cfg.type = 'plv';
  cfg.param = 'beta';
  cfg.sessionStr = sessionStr;
  INFADI_writeTbl(cfg, data_plv_beta);
  
  % export the PLVs into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '07a_plv/');
  cfg.filename    = sprintf('INFADI_d%02d_07a_plvBeta', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving PLVs (beta: 13-30Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_plv_beta', data_plv_beta);
  fprintf('Data stored!\n');
  clear data_plv_beta
  
  % export the mean PLVs into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '07b_mplv/');
  cfg.filename    = sprintf('INFADI_d%02d_07b_mplvBeta', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving mean PLVs (beta: 13-30Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_mplv_beta', data_mplv_beta);
  fprintf('Data stored!\n\n');
  clear data_mplv_beta
  
  %% gamma branch %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  % load hilbert phase data at gamma %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '06b_hilbert/');
  cfg.sessionStr  = sessionStr;
  cfg.filename    = sprintf('INFADI_d%02d_06b_hilbertGamma', i);
  fprintf('Load hilbert phase data at gamma (31-48Hz)...\n');
  INFADI_loadData( cfg );
    
  % segmentation at gamma %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg           = [];
  cfg.length    = 1;
  cfg.overlap   = 0;
    
  fprintf('<strong>Segmentation of Hilbert phase data at gamma (31-48Hz).</strong>\n');
  data_hilbert_gamma  = INFADI_segmentation( cfg, data_hilbert_gamma );
  
  % artifact rejection at gamma %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  if artifactRejection == true
    if artifactAvailable == true
      cfg           = [];
      cfg.artifact  = cfg_allart;
      cfg.reject    = 'complete';
      cfg.target    = 'dual';
  
      fprintf('<strong>Artifact Rejection of Hilbert phase data at gamma (31-48Hz).</strong>\n');
      data_hilbert_gamma = INFADI_rejectArtifacts(cfg, data_hilbert_gamma);
      fprintf('\n');
      
      clear cfg_allart
    end
  end
  
  % calculate PLV and meanPLV at gamma %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
  cfg           = [];
  cfg.winlen    = 1;                                                        % window length for one PLV value in seconds
  
  data_plv_gamma  = INFADI_phaseLockVal(cfg, data_hilbert_gamma);
  data_mplv_gamma = INFADI_calcMeanPLV(data_plv_gamma);
  clear data_hilbert_gamma
  
  % export number of good trials into a spreadsheet
  cfg           = [];
  cfg.desFolder = [desPath '00_settings/'];
  cfg.dyad = i;
  cfg.type = 'plv';
  cfg.param = 'gamma';
  cfg.sessionStr = sessionStr;
  INFADI_writeTbl(cfg, data_plv_gamma);
  
  % export the PLVs into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '07a_plv/');
  cfg.filename    = sprintf('INFADI_d%02d_07a_plvGamma', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving PLVs (gamma: 31-48Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_plv_gamma', data_plv_gamma);
  fprintf('Data stored!\n');
  clear data_plv_gamma
  
  % export the mean PLVs into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '07b_mplv/');
  cfg.filename    = sprintf('INFADI_d%02d_07b_mplvGamma', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('Saving mean PLVs (gamma: 31-48Hz) of dyad %d in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'data_mplv_gamma', data_mplv_gamma);
  fprintf('Data stored!\n\n');
  clear data_mplv_gamma
end

%% clear workspace
clear cfg file_path sourceList numOfSources i artifactRejection ...
      artifactAvailable x choise T
