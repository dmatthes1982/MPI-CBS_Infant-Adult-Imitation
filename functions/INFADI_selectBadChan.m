function [ data_badchan ] = INFADI_selectBadChan( data_raw )
% INFADI_SELECTBADCHAN can be used for selecting bad channels visually. The
% data will be presented in the fieldtrip databrowser view and the bad
% channels will be marked in the INFADI_CHANNELCHECKBOX gui. The function
% returns a fieldtrip-like datastructure which includes only a cell array 
% for each participant with the selected bad channels.
%
% Use as
%   [ data_badchan ] = INFADI_selectBadChan( data_raw )
%
% where the input has to be raw data
%
% The function requires the fieldtrip toolbox
%
% SEE also INFADI_DATABROWSER and INFADI_CHANNELCHECKBOX

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Databrowser settings
% -------------------------------------------------------------------------
cfg             = [];
cfg.ylim        = [-200 200];
cfg.blocksize   = 120;
cfg.part        = 1;
cfg.plotevents  = 'no';

% -------------------------------------------------------------------------
% Selection of bad channels
% -------------------------------------------------------------------------
fprintf('<strong>Select bad channels of experimenter...</strong>\n');
INFADI_databrowser( cfg, data_raw );
badLabel = INFADI_channelCheckbox();
close(gcf);                                                                 % close also databrowser view when the channelCheckbox will be closed
if any(strcmp(badLabel, 'TP10'))
  warning backtrace off;
  warning(['You have repaired ''TP10'', accordingly selecting linked ' ...
           'mastoid as reference in step [2] - preprocessing is not '...
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
  
if ~isempty(badLabel)
  data_badchan.experimenter.badChan = data_raw.experimenter.label(...
                          ismember(data_raw.experimenter.label, badLabel));
else
  data_badchan.experimenter.badChan = [];
end

cfg.part      = 2;
  
fprintf('<strong>Select bad channels of child...</strong>\n');
INFADI_databrowser( cfg, data_raw );
badLabel = INFADI_channelCheckbox();
close(gcf);                                                                 % close also databrowser view when the channelCheckbox will be closed
if any(strcmp(badLabel, 'TP10'))
  warning backtrace off;
  warning(['You have repaired ''TP10'', accordingly selecting linked ' ...
           'mastoid as reference in step [2] - preprocessing is not '...
           'longer recommended']);
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
  
if ~isempty(badLabel)
  data_badchan.child.badChan = data_raw.child.label(ismember(...
                                          data_raw.child.label, badLabel));
else
  data_badchan.child.badChan = [];
end

end
