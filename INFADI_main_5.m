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

%% part 5
% 1. auto artifact detection (threshold and method is selectable - default: 'minmax', +-75 µV)
% 2. manual artifact detection (verification)

cprintf([1,0.4,1], '<strong>[5] - Automatic and manual artifact detection</strong>\n');
fprintf('\n');

default_threshold = [75, 75;  ...                                           % default for method 'minmax'
                     100, 100; ...                                          % default for method 'range'
                     50, 50;  ...                                           % default for method 'stddev'
                     7, 7];                                                 % default for method 'mad'
threshold_range   = [50, 200; ...                                           % range for method 'minmax'
                     50, 200; ...                                           % range for method 'range'
                     20, 80; ...                                            % range for method 'stddev'
                     3, 7];                                                 % range for method 'mad'

% method selectiom
selection = false;
while selection == false
  cprintf([1,0.4,1], 'Please select an artifact detection method:\n');
  fprintf('[1] - minmax threshold\n');
  fprintf('[2] - range threshold within 200ms, sliding window\n');
  fprintf('[3] - stddev threshold within 200ms, sliding window\n');
  fprintf('[4] - mutiple of median absolute deviation, sliding window\n');
  x = input('Option: ');

  switch x
    case 1
      selection = true;
      method = 'minmax';
      winsize = [];
      sliding = 'no';
    case 2
      selection = true;
      method = 'range';
      winsize = 200;
      sliding = 'yes';
    case 3
      selection = true;
      method = 'stddev';
      winsize = 200;
      sliding = 'yes';
    case 4
      selection = true;
      method = 'mad';
      winsize = 200;
      sliding = 'yes';
    otherwise
      cprintf([1,0.5,0], 'Wrong input!\n');
  end
end
fprintf('\n');

% use default settings
selection = false;
while selection == false
  if x ~= 4
    cprintf([1,0.4,1], ['Do you want to use the default thresholds ' ...
                        '(exp.: %d %sV - child: %d %sV)  for automatic ' ...
                        'artifact detection?\n'], ...
                        default_threshold(x,1), char(956), ...
                        default_threshold(x,2), char(956));
  else
    cprintf([1,0.4,1], ['Do you want to use the default thresholds ' ...
                         '(exp.: %d - child: %d times of mad) for ' ...
                         'automatic artifact detection?\n'], ...
                         default_threshold(x,:));
  end
  y = input('Select [y/n]: ','s');
  if strcmp('y', y)
    selection = true;
    threshold = default_threshold(x,:);
  elseif strcmp('n', y)
    selection = true;
    threshold = [];
  else
    selection = false;
  end
end
fprintf('\n');

% use alternative settings
if isempty(threshold)
  identifier = {'experimenters', 'children'};
  for i = 1:1:2                                                             % specify a independent threshold for experimenter and child 
    selection = false;
    while selection == false
      if x ~= 4
        cprintf([1,0.4,1], ['Define the threshold for %s (in %sV) with ' ...
                            'a value from the range between %d and ' ...
                            '%d!\n'], identifier{i}, char(956), ...
                            threshold_range(x,:));
        if x == 1
          cprintf([1,0.4,1], ['Note: i.e. value 100 means threshold '...
                              'limits are +-100' char(956) 'V\n']);
        end
      else
        cprintf([1,0.4,1], ['Define the threshold for %s (in mutiples ' ...
                            'of mad) for %s with a value from the ' ...
                            'range between %d and %d!\n'], ...
                            identifier{i}, threshold_range(x,:));
      end
      y = input('Value: ');
      if isnumeric(y)
        if (y < threshold_range(x,1) || y > threshold_range(x,2))
          cprintf([1,0.5,0], '\nWrong input!\n\n');
          selection = false;
        else
          threshold(1,i) = y;
          selection = true;
        end
      else
        cprintf([1,0.5,0], '\nWrong input!\n\n');
        selection = false;
      end
    end
    fprintf('\n');
  end
end

% channel selection (default settings)
selection = false;
while selection == false
  cprintf([1,0.4,1], 'Do you want to include all channels in artifact detection?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    selection = true;
    selChan = {'all', '-V1', '-V2', '-REF', '-EOGV', '-EOGH'};
    channels = {'all'};
  elseif strcmp('n', x)
    selection = true;
    selChan = [];
  else
    selection = false;
  end
end

% channel selection (user specification)
if isempty(selChan)
  cprintf([1,0.4,1], '\nAvailable channels will be determined. Please wait...\n');
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '04b_eyecor/');
  cfg.filename    = sprintf('INFADI_d%02d_04b_eyecor', numOfPart(1));
  cfg.sessionStr  = sessionStr;

  INFADI_loadData( cfg );

  label = data_eyecor.experimenter.label;
  label = label(~ismember(label, {'V1', 'V2', 'REF', 'EOGV', 'EOGH'}));   % remove 'V1', 'V2', 'REF', 'EOGV' and 'EOGH'
  clear data_eyecor

  sel = listdlg('PromptString', 'Select channels of interest...', ...     % open the dialog window --> the user can select the channels of interest
              'ListString', label, ...
              'ListSize', [220, 300] );

  selChan = label(sel);
  channels = {strjoin(selChan,',')};

  fprintf('You have selected the following channels:\n');
  fprintf('%s\n', channels{1});
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
T.artMethod(numOfPart) = {method};
T.artTholdExp(numOfPart) = threshold(1);
T.artTholdChild(numOfPart) = threshold(2);
T.artChan(numOfPart) = channels;
warning on;
delete(file_path);
writetable(T, file_path);

for i = numOfPart
  cfg             = [];
  cfg.srcFolder   = strcat(desPath, '04b_eyecor/');
  cfg.filename    = sprintf('INFADI_d%02d_04b_eyecor', i);
  cfg.sessionStr  = sessionStr;
  
  fprintf('<strong>Dyad %d</strong>\n', i);
  fprintf('Load eye-artifact corrected data...\n');
  INFADI_loadData( cfg );

 % automatic artifact detection
  cfg             = [];
  cfg.channel     = selChan;
  cfg.method      = method;                                                 % artifact detection method
  cfg.sliding     = sliding;                                                % use sliding window or not
  cfg.winsize     = winsize;                                                % size of sliding window
  cfg.continuous  = 'no';                                                   % data is trial-based
  cfg.trllength   = 1000;                                                   % minimal subtrial length: 1 sec
  cfg.overlap     = 0;                                                      % no overlap
  cfg.min         = -threshold;                                             % min: -threshold µV
  cfg.max         = threshold;                                              % max: threshold µV
  cfg.range       = threshold;                                              % range: threshold µV
  cfg.stddev      = threshold;                                              % stddev: threshold µV
  cfg.mad         = threshold;                                              % mad: multiples of median absolute deviation

  cfg_autoart     = INFADI_autoArtifact(cfg, data_eyecor);
  
  % verify automatic detected artifacts / manual artifact detection
  cfg           = [];
  cfg.artifact  = cfg_autoart;
  cfg.dyad      = i;
  
  cfg_allart    = INFADI_manArtifact(cfg, data_eyecor);                           
  
  % export the automatic selected artifacts into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '05a_autoart/');
  cfg.filename    = sprintf('INFADI_d%02d_05a_autoart', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('\nThe automatic selected artifacts of dyad %d will be saved in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'cfg_autoart', cfg_autoart);
  fprintf('Data stored!\n');
  clear cfg_autoart cfg_manart data_eyecor trl
  
  % export the verified and the additional artifacts into a *.mat file
  cfg             = [];
  cfg.desFolder   = strcat(desPath, '05b_allart/');
  cfg.filename    = sprintf('INFADI_d%02d_05b_allart', i);
  cfg.sessionStr  = sessionStr;

  file_path = strcat(cfg.desFolder, cfg.filename, '_', cfg.sessionStr, ...
                     '.mat');
                   
  fprintf('The visual verified artifacts of dyad %d will be saved in:\n', i); 
  fprintf('%s ...\n', file_path);
  INFADI_saveData(cfg, 'cfg_allart', cfg_allart);
  fprintf('Data stored!\n\n');
  clear cfg_allart
  
  if(i < max(numOfPart))
    selection = false;
    while selection == false
      fprintf('Proceed with the next dyad?\n');
      x = input('\nSelect [y/n]: ','s');
      if strcmp('y', x)
        selection = true;
      elseif strcmp('n', x)
        clear file_path numOfSources sourceList cfg i x selection
        return;
      else
        selection = false;
      end
    end
    fprintf('\n');
  end
end

%% clear workspace
clear file_path numOfSources sourceList cfg i x y selection T threshold ...
      method winsize sliding default_threshold threshold_range ...
      identifier selChan channels label sel
