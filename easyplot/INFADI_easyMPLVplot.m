function INFADI_easyMPLVplot( cfg, data )
% INFADI_EASYMPLVPLOT is a function, which makes it easier to plot the mean 
% PLV values from all electrodes of a specific condition from the 
% INFADI_DATASTRUCTURE.
%
% Use as
%   INFADI_easyPLVplot( cfg, data )
%
% where the input data has to be the result either of INFADI_CALCMEANPLV or
% INFADI_MPLVOVERDYADS
%
% The configuration options are
%   cfg.condition = condition (default: 4 or 'Baseline', see INFADI_DATASTRUCTURE)
%   cfg.elecorder = describes the order of electrodes (use 'default' or specific order i.e.: 'infadi_01')
%                   default value: 'default'
%
% This function requires the fieldtrip toolbox.
%
% See also INFADI_DATASTRUCTURE, PLOT, INFADI_CALCMEANPLV, INFADI_MPLVOVERDYADS

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
cond      = ft_getopt(cfg, 'condition', 4);
elecorder = ft_getopt(cfg, 'elecorder', 'default');

if isfield(data, 'dyad')
  data = data.dyad;
elseif isfield(data, 'avgData')
  data = data.avgData;
else
  error(['The data structure has either a ''dyad'' nor a ''avgData'' field.' ... 
         'You''ve probably loaded the wrong data']);
end

trialinfo = data.trialinfo;                                                 % get trialinfo

filepath = fileparts(mfilename('fullpath'));
addpath(sprintf('%s/../utilities', filepath));

cond = INFADI_checkCondition( cond );                                       % check cfg.condition definition and translate it into trl number    
trl  = find(trialinfo == cond);
if isempty(trl)
  error('The selected dataset contains no condition %d.', cond);
end

% -------------------------------------------------------------------------
% Load electrode order describition, if necessary
% -------------------------------------------------------------------------
if ~strcmp(elecorder, 'default')
  filepath = fileparts(mfilename('fullpath'));
  load(sprintf('%s/../elecorder/%s.mat', filepath, elecorder), ...
     'labelAlt');
end

% -------------------------------------------------------------------------
% Prepare data
% ------------------------------------------------------------------------- 
label = data.label;
components = 1:1:length(label);

if strcmp(elecorder, 'default')
  mPLV = data.mPLV{trl};
else
  [tf, loc]                = ismember(labelAlt, label);                      % bring data into a correct order
  idx                     = 1:length(labelAlt);
  idx                     = idx(tf);
  label                   = labelAlt(idx);
  
  mPLV = data.mPLV{trl};
  loc(loc==0) = [];
  mPLV = mPLV(loc, loc);
end
  
% -------------------------------------------------------------------------
% Plot mPLV representation
% -------------------------------------------------------------------------
colormap jet;
imagesc(components, components, mPLV);
set(gca, 'XTick', components,'XTickLabel', label);                          % use labels instead of numbers for the axis description
set(gca, 'YTick', components,'YTickLabel', label);
set(gca,'xaxisLocation','top');                                             % move xlabel to the top
title(sprintf(' mean Phase Locking Values in Condition: %d', cond));   
colorbar;

end
