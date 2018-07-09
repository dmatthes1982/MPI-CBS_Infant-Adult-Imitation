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
%   cfg.artifact  = output of INFADI_autoArtifact (see file INFADI_dxx_05a_autoart_yyy.mat)
%   cfg.dyad      = number of dyad (only necessary for adding markers to databrowser view) (default: []) 
%
% This function requires the fieldtrip toolbox.
%
% See also INFADI_SEGMENTATION, INFADI_DATABROWSER

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
artifact  = ft_getopt(cfg, 'artifact', []);
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
cfg.part = 1;
cfg.artifact = artifact.experimenter.artfctdef.threshold.artifact;
ft_warning off;
INFADI_easyArtfctmapPlot(cfg, artifact);                                    % plot artifact map
fig = gcf;                                                                  % default position is [560 528 560 420]
fig.Position = [0 528 560 420];                                             % --> first figure will be placed on the left side of figure 2
cfgAllArt.experimenter = INFADI_databrowser(cfg, data);                     % show databrowser view in figure 2
close all;                                                                  % figure 1 will be closed with figure 2
cfgAllArt.experimenter = keepfields(cfgAllArt.experimenter, {'artfctdef', 'showcallinfo'});
  
fprintf('\n<strong>Search for artifacts with child...</strong>\n');
cfg.part = 2;
cfg.artifact = artifact.child.artfctdef.threshold.artifact;
ft_warning off;
INFADI_easyArtfctmapPlot(cfg, artifact);                                    % plot artifact map
fig = gcf;                                                                  % default position is [560 528 560 420]
fig.Position = [0 528 560 420];                                             % --> first figure will be placed on the left side of figure 2
cfgAllArt.child = INFADI_databrowser(cfg, data);                            % show databrowser view in figure 2
close all;                                                                  % figure 1 will be closed with figure 2
cfgAllArt.child = keepfields(cfgAllArt.child, {'artfctdef', 'showcallinfo'});
  
ft_warning on;

end