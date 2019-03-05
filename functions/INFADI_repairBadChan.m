function [ data ] = INFADI_repairBadChan( data_badchan, data )
% INFADI_REPAIRBADCHAN can be used for repairing previously selected bad
% channels. For repairing this function uses the weighted neighbour
% approach.
%
% Use as
%   [ data ] = INFADI_repairBadChan( data_badchan, data )
%
% where data_badchan has to be the result of INFADI_SELECTBADCHAN.
%
% Used layout and neighbour definitions:
%   mpi_customized_acticap32.mat
%   mpi_customized_acticap32_neighb.mat
%
% The function requires the fieldtrip toolbox
%
% SEE also FT_CHANNELREPAIR

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Load layout and neighbour definitions
% -------------------------------------------------------------------------
load('mpi_customized_acticap32_neighb.mat', 'neighbours');
load('mpi_customized_acticap32.mat', 'lay');

% -------------------------------------------------------------------------
% Configure Repairing
% -------------------------------------------------------------------------
cfg               = [];
cfg.method        = 'weighted';
cfg.neighbours    = neighbours;
cfg.layout        = lay;
cfg.trials        = 'all';
cfg.showcallinfo  = 'no';

% -------------------------------------------------------------------------
% Repairing bad channels
% -------------------------------------------------------------------------
cfg.missingchannel = data_badchan.experimenter.badChan;

fprintf('<strong>Repairing bad channels of experimenter...</strong>\n');
if isempty(cfg.missingchannel)
  fprintf('All channels are good, no repairing operation required!\n');
else
  ft_warning off;
  data.experimenter = ft_channelrepair(cfg, data.experimenter);
  ft_warning on;
  data.experimenter = removefields(data.experimenter, {'elec'});
  fprintf('\n');
end
label = [lay.label; {'EOGV'; 'EOGH'}];
data.experimenter = correctChanOrder( data.experimenter, label);

cfg.missingchannel = data_badchan.child.badChan;

fprintf('<strong>Repairing bad channels of child...</strong>\n');
if isempty(cfg.missingchannel)
  fprintf('All channels are good, no repairing operation required!\n');
else
  ft_warning off;
  data.child = ft_channelrepair(cfg, data.child);
  ft_warning on;
  data.child = removefields(data.child, {'elec'});
  fprintf('\n');
end
data.child = correctChanOrder( data.child, label);

end

% -------------------------------------------------------------------------
% Local function - move corrected channel to original position
% -------------------------------------------------------------------------
function [ dataTmp ] = correctChanOrder( dataTmp, label )

[~, pos]  = ismember(label, dataTmp.label);
pos       = pos(~ismember(pos, 0));

dataTmp.label = dataTmp.label(pos);
dataTmp.trial = cellfun(@(x) x(pos, :), dataTmp.trial, 'UniformOutput', false);

end
