function [ data_repaired ] = INFADI_repairBadChan( data_badchan, data_raw )
% INFADI_REPAIRBADCHAN can be used for repairing previously selected bad
% channels. For repairing this function uses the weighted neighbour
% approach. After the repairing operation, the result will be displayed in
% the fieldtrip databrowser for verification purpose.
%
% Use as
%   [ data_repaired ] = INFADI_repairBadChan( data_badchan, data_raw )
%
% where data_raw has to be raw data and data_badchan the result of
% INFADI_SELECTBADCHAN.
%
% Used layout and neighbour definitions:
%   mpi_customized_acticap32.mat
%   mpi_customized_acticap32_neighb.mat
%
% The function requires the fieldtrip toolbox
%
% SEE also INFADI_DATABROWSER and FT_CHANNELREPAIR

% Copyright (C) 2018, Daniel Matthes, MPI CBS

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
cfg.badchannel    = data_badchan.experimenter.badChan;

fprintf('<strong>Repairing bad channels of experimenter...</strong>\n');
if isempty(cfg.badchannel)
  fprintf('All channels are good, no repairing operation required!\n');
  data_repaired.experimenter = data_raw.experimenter;
else
  data_repaired.experimenter = ft_channelrepair(cfg, data_raw.experimenter);
  data_repaired.experimenter = removefields(data_repaired.experimenter, {'elec'});
end

cfgView           = [];
cfgView.ylim      = [-200 200];
cfgView.blocksize = 120;
cfgView.part      = 1;
  
fprintf('\n<strong>Verification view for experimenter...</strong>\n');
INFADI_databrowser( cfgView, data_repaired );
commandwindow;                                                            % set focus to commandwindow
input('Press enter to continue!:');
close(gcf);

fprintf('\n');

cfg.badchannel    = data_badchan.child.badChan;

fprintf('<strong>Repairing bad channels of child...</strong>\n');
if isempty(cfg.badchannel)
  fprintf('All channels are good, no repairing operation required!\n');
  data_repaired.child = data_raw.child;
else
  data_repaired.child = ft_channelrepair(cfg, data_raw.child);
  data_repaired.child = removefields(data_repaired.child, {'elec'});
end

% -------------------------------------------------------------------------
% Visual verification
% -------------------------------------------------------------------------
cfgView           = [];
cfgView.ylim      = [-200 200];
cfgView.blocksize = 120;
cfgView.part      = 2;
  
fprintf('\n<strong>Verification view for child...</strong>\n');
INFADI_databrowser( cfgView, data_repaired );
commandwindow;                                                              % set focus to commandwindow
input('Press enter to continue!:');
close(gcf);

fprintf('\n');

end
