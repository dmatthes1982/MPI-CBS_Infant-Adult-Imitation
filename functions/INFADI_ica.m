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
channel         = ft_getopt(cfg, 'channel', {'all', '-EOGV', '-EOGH', '-REF'});
numOfComponent  = ft_getopt(cfg, 'numcomponent', 'all');

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

fprintf('\n<strong>ICA decomposition for participant 1...</strong>\n\n');
data.experimenter = ft_componentanalysis(cfg, data.experimenter);
fprintf('\n<strong>ICA decomposition for participant 2...</strong>\n\n');
data.child = ft_componentanalysis(cfg, data.child);

end
