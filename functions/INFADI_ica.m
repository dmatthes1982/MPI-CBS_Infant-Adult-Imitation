function [ data ] = INFADI_ica( cfg, data )
% INFADI_ICA conducts an independent component analysis on both
% participants
%
% Use as
%   [ data ] = INFADI_ica( cfg, data )
%
% where the input data have to be the result from INFADI_CONCATDATA
%
% The configuration options are
%   cfg.part          = participants which shall be processed: experimenter, child or both (default: both)
%   cfg.channel       = cell-array with channel selection (default = {'all', '-EOGV', '-EOGH', '-REF'})
%   cfg.numcomponent  = 'all' or number (default = 'all')
%
% This function requires the fieldtrip toolbox.
%
% See also INFADI_CONCATDATA

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
part            = ft_getopt(cfg, 'part', 'both');                           % participant selection
channel         = ft_getopt(cfg, 'channel', {'all', '-EOGV', '-EOGH', '-REF'});
numOfComponent  = ft_getopt(cfg, 'numcomponent', 'all');

if ~ismember(part, {'experimenter', 'child', 'both'})                       % check cfg.part definition
  error('cfg.part has to either ''experimenter'', ''child'' or ''both''.');
end

% -------------------------------------------------------------------------
% ICA decomposition
% -------------------------------------------------------------------------
cfg               = [];
cfg.method        = 'runica';
cfg.channel       = channel;
cfg.trials        = 'all';
cfg.numcomponent  = numOfComponent;
cfg.demean        = 'no';
cfg.updatesens    = 'no';
cfg.showcallinfo  = 'no';

if ismember(part, {'experimenter', 'both'})
  fprintf('\n<strong>ICA decomposition for experimenter...</strong>\n\n');
  dataTmp.experimenter = ft_componentanalysis(cfg, data.experimenter);
end

if ismember(part, {'child', 'both'})
  fprintf('\n<strong>ICA decomposition for child...</strong>\n\n');
  dataTmp.child = ft_componentanalysis(cfg, data.child);
end

data = dataTmp;

end
