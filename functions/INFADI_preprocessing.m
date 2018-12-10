function [ data ] = INFADI_preprocessing( cfg, data )
% INFADI_PREPROCESSING does the basic bandpass filtering of the raw data
% and is calculating the EOG signals.
%
% Use as
%   [ data ] = INFADI_preprocessing(cfg, data)
%
% where the input data has to be the result of INFADI_IMPORTATASET
%
% The configuration options are
%   cfg.bpfreq            = passband range [begin end] (default: [0.1 48])
%   cfg.bpfilttype        = bandpass filter type, 'but' or 'fir' (default: fir')
%   cfg.bpinstabilityfix  = deal with filter instability, 'no' or 'split' (default: 'no')
%   cgf.expBadChan        = bad channels of experimimenter which should be excluded (default: [])
%   cgf.childBadChan      = bad channels of child which should be excluded (default: [])
%
% This function requires the fieldtrip toolbox.
%
% See also INFADI_IMPORTDATASET, INFADI_SELECTBADCHAN, FT_PREPROCESSING,
% INFADI_DATASTRUCTURE

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
bpfreq            = ft_getopt(cfg, 'bpfreq', [0.1 48]);
bpfilttype        = ft_getopt(cfg, 'bpfilttype', 'fir');
bpinstabilityfix  = ft_getopt(cfg, 'bpinstabilityfix', 'no');
expBadChan        = ft_getopt(cfg, 'expBadChan', []);
childBadChan      = ft_getopt(cfg, 'childBadChan', []);

% -------------------------------------------------------------------------
% Channel configuration
% -------------------------------------------------------------------------
if ~isempty(expBadChan)
  expBadChan = cellfun(@(x) sprintf('-%s', x), expBadChan, ...
                      'UniformOutput', false);
end
if ~isempty(childBadChan)
childBadChan = cellfun(@(x) sprintf('-%s', x), childBadChan, ...
                      'UniformOutput', false);
end

expChan = [{'all'} expBadChan];                                             % do bandpassfiltering only with good channels and remove the bad once
childChan = [{'all'} childBadChan];

% -------------------------------------------------------------------------
% Basic bandpass filtering
% -------------------------------------------------------------------------
cfg                   = [];
cfg.bpfilter          = 'yes';                                              % use bandpass filter
cfg.bpfreq            = bpfreq;                                             % bandpass range  
cfg.bpfilttype        = bpfilttype;                                         % bandpass filter type
cfg.bpinstabilityfix  = bpinstabilityfix;                                   % deal with filter instability
cfg.trials            = 'all';                                              % use all trials
cfg.feedback          = 'no';                                               % feedback should not be presented
cfg.showcallinfo      = 'no';                                               % prevent printing the time and memory after each function call

fprintf('Filter experimenter data (basic bandpass)...\n');
cfg.channel       = expChan;
data.experimenter = ft_preprocessing(cfg, data.experimenter);
  
fprintf('Filter child data (basic bandpass)...\n');
cfg.channel       = childChan;
data.child        = ft_preprocessing(cfg, data.child);

fprintf('Estimate EOG signals for experimenter...\n');
data.experimenter = estimEOG(data.experimenter);

end

% -------------------------------------------------------------------------
% Local functions
% -------------------------------------------------------------------------
function [ data_out ] = estimEOG( data_in )

cfg               = [];
cfg.channel       = {'F9', 'F10'};
cfg.reref         = 'yes';
cfg.refchannel    = 'F10';
cfg.showcallinfo  = 'no';
cfg.feedback      = 'no';

eogh              = ft_preprocessing(cfg, data_in);
eogh.label{1}     = 'EOGH';

cfg               = [];
cfg.channel       = 'EOGH';
cfg.showcallinfo  = 'no';

eogh              = ft_selectdata(cfg, eogh);

cfg               = [];
cfg.channel       = {'V1', 'V2'};
cfg.reref         = 'yes';
cfg.refchannel    = 'V2';
cfg.showcallinfo  = 'no';
cfg.feedback      = 'no';

eogv              = ft_preprocessing(cfg, data_in);
eogv.label{1}     = 'EOGV';

cfg               = [];
cfg.channel       = 'EOGV';
cfg.showcallinfo  = 'no';

eogv              = ft_selectdata(cfg, eogv);

cfg               = [];
cfg.showcallinfo  = 'no';
ft_info off;
data_out          = ft_appenddata(cfg, data_in, eogv, eogh);
data_out.fsample  = data_in.fsample;
ft_info on;



end
