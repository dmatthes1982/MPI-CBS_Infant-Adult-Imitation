function [ data_badchan ] = INFADI_selectBadChan( data_raw, data_noisy )
% INFADI_SELECTBADCHAN can be used for selecting bad channels visually. The
% data will be presented in two different ways. The first fieldtrip
% databrowser view shows the time course of each channel. The second view
% shows the total power of each channel and is highlighting outliers. The
% bad channels can be marked within the INFADI_CHANNELCHECKBOX gui.
%
% Use as
%   [ data_badchan ] = INFADI_selectBadChan( data_raw, data_noisy )
%
% where the first input has to be concatenated raw data and second one has
% to be the result of INFADI_ESTNOISYCHAN.
%
% The function requires the fieldtrip toolbox
%
% SEE also INFADI_DATABROWSER, INFADI_ESTNOISYCHAN and
% INFADI_CHANNELCHECKBOX

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Check data
% -------------------------------------------------------------------------
if numel(data_raw.experimenter.trialinfo) ~= 1 || numel(data_raw.child.trialinfo) ~= 1
  error('First dataset has more than one trial. Data has to be concatenated!');
end

if ~isfield(data_noisy.experimenter, 'totalpow')
  error('Second dataset has to be the result of INFADI_ESTNOISYCHAN!');
end

% -------------------------------------------------------------------------
% Databrowser settings
% -------------------------------------------------------------------------
cfg             = [];
cfg.ylim        = [-200 200];
cfg.blocksize   = 120;
cfg.part        = 'experimenter';
cfg.plotevents  = 'no';

% -------------------------------------------------------------------------
% Selection of bad channels
% -------------------------------------------------------------------------
fprintf('<strong>Select bad channels of experimenter...</strong>\n');
INFADI_easyTotalPowerBarPlot( cfg, data_noisy );
fig = gcf;                                                                  % default position is [560 528 560 420]
fig.Position = [0 528 560 420];                                             % --> first figure will be placed on the left side of figure 2
INFADI_databrowser( cfg, data_raw );
cfgCC.maxchan = fix(numel(data_raw.experimenter.label) * 0.1);              % estimate 10% of the total number of channels in the data
badLabel = JAI_channelCheckbox( cfgCC );
close(gcf);                                                                 % close also databrowser view when the channelCheckbox will be closed
close(gcf);                                                                 % close also total power diagram when the channelCheckbox will be closed
if any(strcmp(badLabel, 'TP10'))
  warning backtrace off;
  warning(['You have rejected ''TP10'', accordingly selecting linked ' ...
           'mastoid as reference in step [4] - Preproc II is not '...
           'longer recommended.']);
  warning backtrace on;
end
if length(badLabel) >= 2
  warning backtrace off;
  warning(['You have selected more than one channel. Please compare your ' ... 
           'selection with the neighbour definitions in 00_settings/general. ' ...
           'Bad channels will exluded from a repairing operation of a ' ...
           'likewise bad neighbour, but each channel should have at least '...
           'two good neighbours.']);
  warning backtrace on;
end
fprintf('\n');

data_badchan.experimenter = data_noisy.experimenter;

if ~isempty(badLabel)
  data_badchan.experimenter.badChan = data_raw.experimenter.label(...
                          ismember(data_raw.experimenter.label, badLabel));
else
  data_badchan.experimenter.badChan = [];
end

cfg.part      = 'child';
  
fprintf('<strong>Select bad channels of child...</strong>\n');
INFADI_easyTotalPowerBarPlot( cfg, data_noisy );
fig = gcf;                                                                  % default position is [560 528 560 420]
fig.Position = [0 528 560 420];                                             % --> first figure will be placed on the left side of figure 2
INFADI_databrowser( cfg, data_raw );
cfgCC.maxchan = fix(numel(data_raw.child.label) * 0.1);                     % estimate 10% of the total number of channels in the data
badLabel = JAI_channelCheckbox( cfgCC );
close(gcf);                                                                 % close also databrowser view when the channelCheckbox will be closed
close(gcf);                                                                 % close also total power diagram when the channelCheckbox will be closed
if any(strcmp(badLabel, 'TP10'))
  warning backtrace off;
  warning(['You have rejected ''TP10'', accordingly selecting linked ' ...
           'mastoid as reference in step [4] - Preproc II is not '...
           'longer recommended.']);
  warning backtrace on;
end
if length(badLabel) >= 2
  warning backtrace off;
  warning(['You marked more than one channel. Please compare your ' ... 
           'selection with the neighbour overview in 00_settings/general. ' ...
           'Bad channels will not used for repairing a likewise bad ' ...
           'neighbour, but each channel should have at least two good '...
           'neighbours.']);
  warning backtrace on;
end
fprintf('\n');

data_badchan.child = data_noisy.child;

if ~isempty(badLabel)
  data_badchan.child.badChan = data_raw.child.label(ismember(...
                                          data_raw.child.label, badLabel));
else
  data_badchan.child.badChan = [];
end

end
