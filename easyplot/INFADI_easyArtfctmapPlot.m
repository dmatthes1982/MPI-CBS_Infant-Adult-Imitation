function INFADI_easyArtfctmapPlot(cfg, cfg_autoart)
% INFADI_EASYARTFCTMAPPLOT generates a multiplot of artifact maps for all 
% existing trials. A single map contains a artifact map for a specific 
% condition from which one could determine which electrode exceeds the 
% artifact detection threshold in which time segment. Artifact free 
% segments are filled with green and the segments which violates the 
% threshold are colored in red.
%
% Use as
%   INFADI_easyArtfctmapPlot(cfg, cfg_autoart)
%
% where cfg_autoart has to be a result from INFADI_AUTOARTIFACT.
%
% The configuration options are 
%   cfg.part      = participant identifier, options: 'experimenter' or 'child' (default: 'experimenter')
%   cfg.trialinfo = trialinfo of dataset (optional)
%                   if trialinfo is specified, this function will plot a combined map for trials of the same condition
%
% This function requires the fieldtrip toolbox
%
% See also INFADI_AUTOARTIFACT

% Copyright (C) 2018, Daniel Matthes, MPI CBS


% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
part      = ft_getopt(cfg, 'part', 'experimenter');                         % get participant identifier
trialinfo = ft_getopt(cfg, 'trialinfo', []);                                % get trialinfo of dataset

label = cfg_autoart.label;                                                  % get labels which were used for artifact detection

if strcmp(part, 'experimenter')
  badNumChan  = cfg_autoart.bad1NumChan;
  cfg_autoart = cfg_autoart.experimenter;
elseif strcmp(part, 'child')
  badNumChan  = cfg_autoart.bad2NumChan;
  cfg_autoart = cfg_autoart.child;
else                                                                        % check validity of cfg.part
  error('Input structure seems to be no cfg_autoart element including participants fields');
end

artfctmap = cfg_autoart.artfctdef.threshold.artfctmap;                      % extract artifact maps from cfg_autoart structure

if ~isempty(trialinfo)
  if length(trialinfo) ~= length(artfctmap)
    error('Wrong selection! Length of cfg.trialinfo and artfctmap doesn''t match.\n');
  end
end

% -------------------------------------------------------------------------
% Define colormap
% -------------------------------------------------------------------------
cmap = [1 0.71 0.8; 0.55 0.23 0.38];                                        % colormap with two colors, light pink tone for good segments, hot pink tone for bad once

% -------------------------------------------------------------------------
% Concatenation of maps from same conditions
% -------------------------------------------------------------------------
if ~isempty(trialinfo)
  trl = unique(trialinfo, 'stable');                                        % estimate unique conditions
  numOfUniqueTrials = length(trl);
  map = cell(1, numOfUniqueTrials);
  for i = 1:1:numOfUniqueTrials
    sel = ismember(trialinfo, trl(i));
    map{i} = cat(2, artfctmap{sel});                                        % concatenate maps
  end
  artfctmap = map;
end

% -------------------------------------------------------------------------
% Plot artifact map
% -------------------------------------------------------------------------
conditions = size(artfctmap, 2);                                            % estimate number of conditions
elements = sqrt(conditions);                                                % estimate structure of multiplot
rows = fix(elements);                                                       % try to create a nearly square design
rest = mod(elements, rows);

if rest > 0
  if rest > 0.5
    rows    = ceil(elements);
    columns = ceil(elements);
  else
    columns = ceil(elements);
  end
else
  columns = rows;
end

data(:,1) = label;
data(:,2) = num2cell(badNumChan);

f = figure;
pt = uipanel('Parent', f, 'Title', 'Electrodes', 'Fontsize', 12, 'Position', [0.02,0.02,0.09,0.96]);
if isempty(trialinfo)
  identifier = 'Artifact maps';
else
  identifier = sprintf('Artifact maps for all conditions - Part: %s', part);
end
pg = uipanel('Parent', f, 'Title', identifier, 'Fontsize', 12, 'Position', [0.12,0.02,0.86,0.96]);
uitable(pt, 'Data', data, 'ColumnWidth', {50 50}, 'ColumnName', {'Chans', 'Artfcts'}, 'Units', 'normalized', 'Position', [0.01, 0.01, 0.98, 0.98]);

colormap(f, cmap);                                                          % change colormap for this new figure

for i=1:1:conditions
  subplot(rows,columns,i,'parent', pg);
  h = imagesc(artfctmap{i},[0 1]);                                          % plot subelements
  set(h,'alphadata',~isnan(artfctmap{i}));                                  % set nan values to transparent
  set(gca,'color','white');                                                 % make the background white
  if ~isempty(trialinfo)
    title(sprintf('Condition S%3d', trl(i)));
  end
  xlabel('time in sec');
  ylabel('channels');
end

if isempty(trialinfo)
  axes(pg, 'Units','Normal');                                               % set main title for the whole figure only if no trialinfo was specified
  h = title(sprintf('Artifact maps for all existing trials - Part: %s', part));
  set(gca,'visible','off')
  set(h,'visible','on')
end

end
