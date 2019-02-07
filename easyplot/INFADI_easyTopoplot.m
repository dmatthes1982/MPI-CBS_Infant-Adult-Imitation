function INFADI_easyTopoplot(cfg , data)
% INFADI_EASYTOPOPLOT is a function, which makes it easier to plot the
% topographic distribution of the power over the head.
%
% Use as
%   INFADI_easyTopoplot(cfg, data)
%
%  where the input data have to be a result from INFADI_PWELCH.
%
% The configuration options are 
%   cfg.part        = participant identifier, options: 'experimenter' or 'child' (default: 'experimenter')   
%   cfg.condition   = condition (default: 4 or 'Baseline', see INFADI_DATASTRUCTURE)
%   cfg.baseline    = baseline condition (default: [], can by any valid condition)
%                     the values of the baseline condition will be subtracted
%                     from the values of the selected condition (cfg.condition)
%   cfg.freqlim     = limits for frequency in Hz (e.g. [6 9] or 10) (default: 10)
%
% This function requires the fieldtrip toolbox
%
% See also INFADI_PWELCH, INFADI_DATASTRUCTURE

% Copyright (C) 2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
part      = ft_getopt(cfg, 'part', 'experimenter');
condition = ft_getopt(cfg, 'condition', 4);
baseline  = ft_getopt(cfg, 'baseline', []);
freqlim   = ft_getopt(cfg, 'freqlim', 10);

filepath = fileparts(mfilename('fullpath'));                                % add utilities folder to path
addpath(sprintf('%s/../utilities', filepath));

if ~ismember(part, {'experimenter', 'child'})                               % check cfg.part definition
  error('cfg.part has to be either ''experimenter'' or ''child''.');
end

switch part                                                                 % extract selected participant
  case 'experimenter'
    data = data.experimenter;
  case 'child'
    data = data.child;
end

trialinfo = data.trialinfo;                                                 % get trialinfo

condition = INFADI_checkCondition( condition );                             % check cfg.condition definition    
if isempty(find(trialinfo == condition, 1))
  error('The selected dataset contains no condition %d.', condition);
else
  trialNum = ismember(trialinfo, condition);
end

if ~isempty(baseline)
  baseline    = JAI_checkCondition( baseline );                             % check cfg.baseline definition
  if isempty(find(trialinfo == baseline, 1))
    error('The selected dataset contains no condition %d.', baseline);
  else
    baseNum = ismember(trialinfo, baseline);
  end
end

if numel(freqlim) == 1
  freqlim = [freqlim freqlim];
end

% -------------------------------------------------------------------------
% Generate topoplot
% -------------------------------------------------------------------------
load(sprintf('%s/../layouts/mpi_customized_acticap32.mat', filepath), 'lay');

cfg               = [];
cfg.parameter     = 'powspctrm';
cfg.xlim          = freqlim;
cfg.zlim          = 'maxmin';
cfg.trials        = trialNum;
cfg.colormap      = 'jet';
cfg.marker        = 'on';
cfg.colorbar      = 'yes';
cfg.style         = 'both';
cfg.gridscale     = 200;                                                    % gridscale at map, the higher the better
cfg.layout        = lay;
cfg.showcallinfo  = 'no';

if ~isempty(baseline)                                                       % subtract baseline condition
  data.powspctrm(trialNum,:,:) = data.powspctrm(trialNum,:,:) - ...
                                  data.powspctrm(baseNum,:,:);
end

ft_topoplotER(cfg, data);

if isempty(baseline)
  title(sprintf(['Power - %s - Condition %d - Freqrange '...
            '[%d %d]'], part, condition, freqlim));
else
  title(sprintf(['Power - %s - Condition %d-%d - '...
            'Freqrange [%d %d]'], part, condition, baseline, freqlim));
end

set(gcf, 'Position', [0, 0, 750, 550]);
movegui(gcf, 'center');
              
end
