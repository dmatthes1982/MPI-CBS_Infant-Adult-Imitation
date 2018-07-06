function INFADI_writeTbl( cfg, data )
% INFADI_WRITETBL writes the numbers of good trials for each condition of a 
% specific dyad in plv or itpc estimations to the associated files.
%
% Use as
%   INFADI_writeTbl( cfg, data )
%
% The input data hast to be from INFADI_PHASELOCKVAL
%
% The configuration options are
%   cfg.desFolder   = destination folder (default: '/data/pt_01905/eegData/DualEEG_INFADI_processedData/00_settings/')
%   cfg.dyad        = number of dyad
%   cfg.type        = type of documentation file (options: plv)
%   cfg.param       = additional params for type 'plv' (options: 'theta', 'alpha', 'beta', 'gamma');
%   cfg.sessionStr  = number of session, format: %03d, i.e.: '003' (default: '001')
%
% This function requires the fieldtrip toolbox.
%
% SEE also INFADI_INTERTRIALPHASECOH, INFADI_PHASELOCKVAL

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get config options
% -------------------------------------------------------------------------
desFolder   = ft_getopt(cfg, 'desFolder', ...
          '/data/pt_01905/eegData/DualEEG_INFADI_processedData/00_settings/');
dyad        = ft_getopt(cfg, 'dyad', []);
type        = ft_getopt(cfg, 'type', []);
param       = ft_getopt(cfg, 'param', []);
sessionStr  = ft_getopt(cfg, 'sessionStr', []);

if isempty(dyad)
  error('cfg.dyad has to be specified');
end

if isempty(type)
  error('cfg.type has to be specified. It has to be ''plv''.');
end

if strcmp(type, 'plv')
  if isempty(param)
    error([ 'cfg.param has to be specified. Selectable options: '...
            '''theta'', ''alpha'', ''beta'', ''gamma''']);
  end
end

if isempty(sessionStr)
  error('cfg.sessionNum has to be specified');
end

% -------------------------------------------------------------------------
% Load general definitions
% -------------------------------------------------------------------------
filepath = fileparts(mfilename('fullpath'));
load(sprintf('%s/../general/INFADI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');

% -------------------------------------------------------------------------
% Extract trialinfo and number of good trials from data
% -------------------------------------------------------------------------
if strcmp(type, 'plv')
  trialinfo = data.dyad.trialinfo';
  [~, loc] = ismember(generalDefinitions.condNum, trialinfo);
  if any(loc == 0)
    emptyCond = (loc == 0);
    emptyCond = generalDefinitions.condNum(emptyCond);
    str = vec2str(emptyCond, [], [], 0);
    warning backtrace off;
    warning(['The following trials are completely rejected: ' str]);
    warning backtrace on;
  end
  goodtrials = zeros(1, length(generalDefinitions.condNum));
  for i = 1:1:length(generalDefinitions.condNum)
    if loc(i) ~= 0
      goodtrials(i) = data.dyad.goodtrials(loc(i));
    end
  end
  goodtrials = num2cell(goodtrials);
end

% -------------------------------------------------------------------------
% Generate output file, if necessary
% -------------------------------------------------------------------------
if strcmp(type, 'plv')
  file_path = [desFolder sprintf('%s_%s_%s', type, param, sessionStr) '.xls'];
end

if ~(exist(file_path, 'file') == 2)                                         % check if file already exist
  cfg = [];
  cfg.desFolder   = desFolder;
  cfg.type        = type;
  cfg.param       = param;
  cfg.sessionStr  = sessionStr;
  
  INFADI_createTbl(cfg);                                                    % create file
end

% -------------------------------------------------------------------------
% Update table
% -------------------------------------------------------------------------
T = readtable(file_path);
delete(file_path);
warning off;
T.dyad(dyad) = dyad;
if strcmp(type, 'plv')
  T(dyad, 2:end) = goodtrials;
warning on;
writetable(T, file_path);

end
