function [ cfgAllArt ] = INFADI_manArtifact( cfg, data )
% INFADI_MANARTIFACT - this function could be use to is verify the
% automatic detected artifacts remove some of them or add additional ones
% if required.
%
% Use as
%   [ cfgAllArt ] = INFADI_manArtifact(cfg, data)
%
% where data has to be a result of INFADI_SEGMENTATION
%
% The configuration options are
%   cfg.threshArt = output of INFADI_AUTOARTIFACT (see file INFADI_dxx_05a_autoart_yyy.mat)
%   cfg.manArt    = output of INFADI_IMPORTDATASET (see file INFADI_dxx_01b_manart_yyy.mat)
%   cfg.dyad      = number of dyad (only necessary for adding markers to databrowser view) (default: []) 
%
% This function requires the fieldtrip toolbox.
%
% See also INFADI_SEGMENTATION, INFADI_DATABROWSER, INFADI_AUTOARTIFACT, 
% INFADI_IMPORTDATASET

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
threshArt = ft_getopt(cfg, 'threshArt', []);
manArt    = ft_getopt(cfg, 'manArt', []);
dyad      = ft_getopt(cfg, 'dyad', []);

% -------------------------------------------------------------------------
% Initialize settings, build output structure
% -------------------------------------------------------------------------
cfg             = [];
cfg.dyad        = dyad;
cfg.channel     = {'all', '-V1', '-V2'};
cfg.ylim        = [-100 100];
cfgAllArt.experimenter = [];                                       
cfgAllArt.child = [];

% -------------------------------------------------------------------------
% Check Data
% -------------------------------------------------------------------------

fprintf('\n<strong>Search for artifacts with experimenter...</strong>\n');
cfg.part = 'experimenter';
cfg.threshArt = threshArt.experimenter.artfctdef.threshold.artifact;
cfg.manArt    = manArt.experimenter.artfctdef.xxx.artifact;
ft_warning off;
INFADI_easyArtfctmapPlot(cfg, threshArt);                                   % plot artifact map
fig = gcf;                                                                  % default position is [560 528 560 420]
fig.Position = [0 528 560 420];                                             % --> first figure will be placed on the left side of figure 2
cfgAllArt.experimenter = INFADI_databrowser(cfg, data);                     % show databrowser view in figure 2
close all;                                                                  % figure 1 will be closed with figure 2
cfgAllArt.experimenter = keepfields(cfgAllArt.experimenter, {'artfctdef', 'showcallinfo'});
  
fprintf('\n<strong>Search for artifacts with child...</strong>\n');
cfg.part = 'child';
cfg.threshArt = threshArt.child.artfctdef.threshold.artifact;
cfg.manArt    = manArt.child.artfctdef.xxx.artifact;
ft_warning off;
INFADI_easyArtfctmapPlot(cfg, threshArt);                                   % plot artifact map
fig = gcf;                                                                  % default position is [560 528 560 420]
fig.Position = [0 528 560 420];                                             % --> first figure will be placed on the left side of figure 2
cfgAllArt.child = INFADI_databrowser(cfg, data);                            % show databrowser view in figure 2
close all;                                                                  % figure 1 will be closed with figure 2
cfgAllArt.child = keepfields(cfgAllArt.child, {'artfctdef', 'showcallinfo'});
  
ft_warning on;

end
