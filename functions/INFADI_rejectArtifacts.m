function [ data ] = INFADI_rejectArtifacts( cfg, data )
% INFADI_REJECTARTIFACTS is a function which removes trials containing 
% artifacts. It returns clean data.
%
% Use as
%   [ data ] = INFADI_rejectartifacts( cfg, data )
%
% where data can be a result of INFADI_SEGMENTATION, INFADI_BPFILTERING,
% INFADI_CONCATDATA or INFADI_HILBERTPHASE
%
% The configuration options are
%   cfg.part      = participants which shall be processed: experimenter, child or both (default: both)
%   cfg.artifact  = output of INFADI_manArtifact or INFADI_manArtifact 
%                   (see file INFADI_pxx_05_autoArt_yyy.mat, INFADI_pxx_06_allArt_yyy.mat)
%   cfg.reject    = 'none', 'partial','nan', or 'complete' (default = 'complete')
%   cfg.target    = type of rejection, options: 'single' or 'dual' (default: 'single');
%                   'single' = trials of a certain participant will be 
%                              rejected, if they are marked as bad 
%                              for that particpant (useable for ITPC calc)
%                   'dual' = trials of a certain participant will be
%                            rejected, if they are marked as bad for
%                            that particpant or for the other participant
%                            of the dyad (useable for PLV calculation)
%
% This function requires the fieldtrip toolbox.
%
% See also INFADI_SEGMENTATION, INFADI_BPFILTERING, INFADI_HILBERTPHASE, 
% INFADI_MANARTIFACT and INFADI_AUTOARTIFACT 

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get config options
% -------------------------------------------------------------------------
part      = ft_getopt(cfg, 'part', 'both');                                 % participant selection
artifact  = ft_getopt(cfg, 'artifact', []);
reject    = ft_getopt(cfg, 'reject', 'complete');
target    = ft_getopt(cfg, 'target', 'single');

if ~ismember(part, {'experimenter', 'child', 'both'})                       % check cfg.part definition
  error('cfg.part has to either ''experimenter'', ''child'' or ''both''.');
end

if isempty(artifact)
  error('cfg.artifact has to be defined');
end

if ~strcmp(target, 'single') && ~strcmp(target, 'dual')
  error('Selected type is unknown. Choose single or dual');
end

if ~strcmp(reject, 'complete')
  if ismember(part, {'experimenter', 'both'})
    artifact.experimenter.artfctdef.reject = reject;
    artifact.experimenter.artfctdef.minaccepttim = 0.2;
  end

  if ismember(part, {'child', 'both'})
    artifact.child.artfctdef.reject = reject;
    artifact.child.artfctdef.minaccepttim = 0.2;
  end
end


% -------------------------------------------------------------------------
% Clean Data
% -------------------------------------------------------------------------
if ismember(part, {'experimenter', 'both'})
  fprintf('\n<strong>Cleaning data of experimenter...</strong>\n');
  ft_warning off;
  dataTmp.experimenter = ft_rejectartifact(artifact.experimenter, data.experimenter);
  if strcmp(target, 'dual')
    ft_warning off;
    dataTmp.experimenter = ft_rejectartifact(artifact.child, data.experimenter);
  end
end

if ismember(part, {'child', 'both'})
  fprintf('\n<strong>Cleaning data of child...</strong>\n');
  ft_warning off;
  dataTmp.child = ft_rejectartifact(artifact.child, data.child);
  if strcmp(target, 'dual')
    ft_warning off;
    dataTmp.child = ft_rejectartifact(artifact.experimenter, data.child);
  end
end
  
ft_warning on;

data = dataTmp;

end
