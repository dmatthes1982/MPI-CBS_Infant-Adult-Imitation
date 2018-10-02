function INFADI_easyPSDplot(cfg, data)
% INFADI_EASYPSDPLOT is a function, which makes it easier to plot the power
% spectral density within a specific condition of the INFADI_DATASTRUCTURE
%
% Use as
%   INFADI_easyPSDplot(cfg, data)
%
% where the input data have to be a result from INFADI_PWELCH.
%
% The configuration options are 
%   cfg.part        = participant identifier, options: 'experimenter' or 'child' (default: 'experimenter')
%   cfg.condition   = condition (default: 4 or 'Baseline', see INFADI_DATASTRUCTURE)
%   cfg.electrode   = number of electrodes (default: {'Cz'} repsectively [8])
%                     examples: {'Cz'}, {'F3', 'Fz', 'F4'}, [8] or [2, 1, 28]
%   cfg.avgelec     = plot average over selected electrodes, options: 'yes' or 'no' (default: 'no')
%
% This function requires the fieldtrip toolbox
%
% See also INFADI_PWELCH, INFADI_DATASTRUCTURE

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
part    = ft_getopt(cfg, 'part', 'experimenter');
cond    = ft_getopt(cfg, 'condition', 4);
elec    = ft_getopt(cfg, 'electrode', {'Cz'});
avgelec = ft_getopt(cfg, 'avgelec', 'no');

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
label     = data.label;                                                     % get labels 

cond    = INFADI_checkCondition( cond );                                    % check cfg.condition definition    
if isempty(find(trialinfo == cond, 1))
  error('The selected dataset contains no condition %d.', cond);
else
  trialNum = ismember(trialinfo, cond);
end

if isnumeric(elec)                                                          % check cfg.electrode
  for i=1:length(elec)
    if elec(i) < 1 || elec(i) > 32
      error('cfg.elec has to be a numbers between 1 and 32 or a existing labels like {''Cz''}.');
    end
  end
else
  tmpElec = zeros(1, length(elec));
  for i=1:length(elec)
    tmpElec(i) = find(strcmp(label, elec{i}));
    if isempty(tmpElec(i))
      error('cfg.elec has to be a cell array of existing labels like ''Cz''or a vector of numbers between 1 and 32.');
    end
  end
  elec = tmpElec;
end

if ~ismember(avgelec, {'yes', 'no'})                                        % check cfg.avgelec definition
  error('cfg.avgelec has to be either ''yes'' or ''no''.');
end

% -------------------------------------------------------------------------
% Plot power spectral density (PSD)
% -------------------------------------------------------------------------
legend('-DynamicLegend');
hold on;

if strcmp(avgelec, 'no')
  for i = 1:1:length(elec)
    plot(data.freq, squeeze(data.powspctrm(trialNum, elec(i),:)), ...
        'DisplayName', data.label{elec(i)});
  end
else
  labelString = strjoin(data.label(elec), ',');
  plot(data.freq, mean(squeeze(data.powspctrm(trialNum, elec,:)), 1), ...
        'DisplayName', labelString);
end

title(sprintf('PSD - Part.: %s - Cond.: %d', part, cond));
xlabel('frequency in Hz');                                                  % set xlabel
ylabel('power in uV^2');                                                    % set ylabel

hold off;

end
