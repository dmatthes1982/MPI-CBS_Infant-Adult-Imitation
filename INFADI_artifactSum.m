% -------------------------------------------------------------------------
% Add directory and subfolders to path, clear workspace, clear command
% windwow
% -------------------------------------------------------------------------
INFADI_init;

cprintf([1,0.4,1], '<strong>------------------------------------------------</strong>\n');
cprintf([1,0.4,1], '<strong>Infant adult imitation project</strong>\n');
cprintf([1,0.4,1], '<strong>Export number of segments with artifacts</strong>\n');
cprintf([1,0.4,1], 'Copyright (C) 2018-2019, Daniel Matthes, MPI CBS\n');
cprintf([1,0.4,1], '<strong>------------------------------------------------</strong>\n');

% -------------------------------------------------------------------------
% Path settings
% -------------------------------------------------------------------------
path = '/data/pt_01905/eegData/DualEEG_INFADI_processedData/';

fprintf('\nThe default path is: %s\n', path);

selection = false;
while selection == false
  fprintf('\nDo you want to use the default path?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    selection = true;
    newPaths = false;
  elseif strcmp('n', x)
    selection = true;
    newPaths = true;
  else
    selection = false;
  end
end

if newPaths == true
  path = uigetdir(pwd, 'Select folder...');
  path = strcat(path, '/');
end

% -------------------------------------------------------------------------
% Session selection
% -------------------------------------------------------------------------
tmpPath = strcat(path, '05a_autoart/');

fileList     = dir([tmpPath, 'INFADI_d*_05a_autoart_*.mat']);
fileList     = struct2cell(fileList);
fileList     = fileList(1,:);
numOfFiles   = length(fileList);

sessionNum   = zeros(1, numOfFiles);
fileListCopy = fileList;

for i=1:1:numOfFiles
  fileListCopy{i} = strsplit(fileList{i}, '05a_autoart_');
  fileListCopy{i} = fileListCopy{i}{end};
  sessionNum(i) = sscanf(fileListCopy{i}, '%d.mat');
end

sessionNum = unique(sessionNum);
y = sprintf('%d ', sessionNum);

userList = cell(1, length(sessionNum));

for i = sessionNum
  match = find(strcmp(fileListCopy, sprintf('%03d.mat', i)), 1, 'first');
  filePath = [tmpPath, fileList{match}];
  [~, cmdout] = system(['ls -l ' filePath '']);
  attrib = strsplit(cmdout);
  userList{i} = attrib{3};
end

selection = false;
while selection == false
  fprintf('\nThe following sessions are available: %s\n', y);
  fprintf('The session owners are:\n');
  for i=1:1:length(userList)
    fprintf('%d - %s\n', i, userList{i});
  end
  fprintf('\n');
  fprintf('Please select one session:\n');
  fprintf('[num] - Select session\n\n');
  x = input('Session: ');

  if length(x) > 1
    cprintf([1,0.5,0], 'Wrong input, select only one session!\n');
  else
    if ismember(x, sessionNum)
      selection = true;
      sessionStr = sprintf('%03d', x);
    else
      cprintf([1,0.5,0], 'Wrong input, session does not exist!\n');
    end
  end
end

fprintf('\n');

clear sessionNum fileListCopy y userList match filePath cmdout attrib

% -------------------------------------------------------------------------
% Extract and export number of artifacts
% -------------------------------------------------------------------------
tmpPath = strcat(path, '05a_autoart/');

fileList     = dir([tmpPath, ['INFADI_d*_05a_autoart_' sessionStr '.mat']]);
fileList     = struct2cell(fileList);
fileList     = fileList(1,:);
numOfFiles  = length(fileList);
numOfPart   = zeros(1, numOfFiles);
for i = 1:1:numOfFiles
  numOfPart(i) = sscanf(fileList{i}, strcat('INFADI_d%d*', sessionStr, '.mat'));
end

file_path = strcat(tmpPath, fileList{1});
load(file_path, 'cfg_autoart');

labelExp    = cfg_autoart.labelExp;
labelChild  = cfg_autoart.labelChild;
label_1 = cellfun(@(x) strcat(x, '_1'), labelExp,   'UniformOutput', false)';
label_2 = cellfun(@(x) strcat(x, '_2'), labelChild, 'UniformOutput', false)';

T = cell2table(num2cell(zeros(1, length(label_1) + length(label_2) + 3 )));
T.Properties.VariableNames = [{'dyad', 'ArtifactsPart1', ...
                                'ArtifactsPart2'} label_1 label_2];         % create empty table with variable names

for i = 1:1:length(fileList)
  file_path = strcat(tmpPath, fileList{i});
  load(file_path, 'cfg_autoart');

  chan = ismember(labelExp, cfg_autoart.labelExp);                          % determine all channels which were used for artifact detection
  pos = ismember(cfg_autoart.labelExp, labelExp);                           % determine the order of the channels

  tmpArt1 = zeros(1,length(labelExp));
  tmpArt1(chan) = cfg_autoart.bad1NumChan(pos);                             % extract number of artifacts per channel for participant 1
  tmpArt1 = num2cell(tmpArt1);

  chan = ismember(labelChild, cfg_autoart.labelChild);                      % determine all channels which were used for artifact detection
  pos = ismember(cfg_autoart.labelChild, labelChild);                       % determine the order of the channels

  tmpArt2 = zeros(1,length(labelChild));
  tmpArt2(chan) = cfg_autoart.bad2NumChan(pos);                             % extract number of artifacts per channel for participant 2
  tmpArt2 = num2cell(tmpArt2);

  warning off;
  T.dyad(i) = numOfPart(i);
  T.ArtifactsPart1(i) = cfg_autoart.bad1Num;
  T.ArtifactsPart2(i) = cfg_autoart.bad2Num;
  T(i,4:length(label_1) + 3)  = tmpArt1;
  T(i, (length(label_1) + 4):(length(label_1) + length(label_2) + 3)) = ...
                                tmpArt2;
  warning on;
end

file_path = strcat(path, '00_settings/', 'numOfArtifacts_', sessionStr, '.xls');
fprintf('The default file path is: %s\n', file_path);

selection = false;
while selection == false
  fprintf('\nDo you want to use the default file path and possibly overwrite an existing file?\n');
  x = input('Select [y/n]: ','s');
  if strcmp('y', x)
    selection = true;
    newPaths = false;
  elseif strcmp('n', x)
    selection = true;
    newPaths = true;
  else
    selection = false;
  end
end

if newPaths == true
  [filename, file_path] = uiputfile(file_path, 'Specify a destination file...');
  file_path = [file_path, filename];
end

if exist(file_path, 'file')
  delete(file_path);
end
writetable(T, file_path);

fprintf('\nNumber of segments with artifacts per dyad exported to:\n');
fprintf('%s\n', file_path);

%% clear workspace
clear tmpPath path sessionStr fileList numOfFiles numOfPart i ...
      file_path cfg_autoart T newPaths filename selection x chan ...
      labelChild labelExp label_1 label_2 pos tmpArt1 tmpArt2
