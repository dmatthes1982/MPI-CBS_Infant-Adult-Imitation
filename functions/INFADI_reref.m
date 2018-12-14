function [ data ] = INFADI_reref( cfg, data )
% INFADI_REREF does the re-referencing of eeg data, 
%
% Use as
%   [ data ] = INFADI_reref(cfg, data)
%
% The configuration option is
%   cfg.refchannel        = re-reference channel (default: 'TP10')
%
% This function requires the fieldtrip toolbox.
%
% See also FT_PREPROCESSING, INFADI_DATASTRUCTURE

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check the config option
% -------------------------------------------------------------------------
refchannel        = ft_getopt(cfg, 'refchannel', 'TP10');

% -------------------------------------------------------------------------
% Re-Referencing
% -------------------------------------------------------------------------
cfg               = [];
cfg.reref         = 'yes';                                                  % enable re-referencing
if ~iscell(refchannel)
  cfg.refchannel    = {refchannel, 'REF'};                                  % specify new reference
else
  cfg.refchannel    = [refchannel, {'REF'}];
end
cfg.implicitref   = 'REF';                                                  % add implicit channel 'REF' to the channels
cfg.refmethod     = 'avg';                                                  % average over selected electrodes
cfg.channel       = 'all';                                                  % use all channels
cfg.trials        = 'all';                                                  % use all trials
cfg.feedback      = 'no';                                                   % feedback should not be presented
cfg.showcallinfo  = 'no';                                                   % prevent printing the time and memory after each function call

fprintf('Re-reference experimenter data...\n');
data.experimenter = ft_preprocessing(cfg, data.experimenter);
data.experimenter.label  = data.experimenter.label';
  
fprintf('Re-reference child data...\n');
data.child        = ft_preprocessing(cfg, data.child);
data.child.label  = data.child.label';

end
