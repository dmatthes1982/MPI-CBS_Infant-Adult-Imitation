function [ data_eogcomp ] = INFADI_selectBadComp( cfg, data_eogcomp, data_icacomp )
% INFADI_SELECTBADCOMP is a function for exploring previously estimated ICA
% components visually. Within the GUI, each component can be set to either
% keep or reject for a later artifact correction operation. The result of
% JAI_DETEOGCOMP are preselected, but it should be visually explored too.
%
% Use as
%   [ data_eogcomp ] = INFADI_selectBadComp( data_eogcomp, data_icacomp )
%
% where the input data_eogcomp has to be the result of INFADI_DETEOGCOMP
% and data_icacomp the result of INFADI_ICA
%
% The configuration options are
%   cfg.part        = participants which shall be processed: experimenter, child or both (default: both)
%
% This function requires the fieldtrip toolbox
%
% See also INFADI_DETEOGCOMP, INFADI_ICA and FT_DATABROWSER

% Copyright (C) 2018-2019, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
part        = ft_getopt(cfg, 'part', 'both');

if ~ismember(part, {'experimenter', 'child', 'both'})                       % check cfg.part definition
  error('cfg.part has to either ''experimenter'', ''child'' or ''both''.');
end

% -------------------------------------------------------------------------
% Verify correlating components
% -------------------------------------------------------------------------
if ismember(part, {'experimenter', 'both'})
  fprintf('<strong>Select ICA components which shall be subtracted from participants 1 data...</strong>\n');
  data_eogcomp.experimenter = selectComp(data_eogcomp.experimenter, data_icacomp.experimenter);
end

fprintf('\n');

if ismember(part, {'child', 'both'})
  fprintf('<strong>Select ICA components which shall be subtracted from participants 2 data...</strong>\n');
  data_eogcomp.child = selectComp(data_eogcomp.child, data_icacomp.child);
end

end

%--------------------------------------------------------------------------
% SUBFUNCTION which does the verification of the EOG-correlating components
%--------------------------------------------------------------------------
function [ dataEOGComp ] = selectComp( dataEOGComp, dataICAcomp )

numOfElements = 1:length(dataEOGComp.elements);
idx = find(ismember(dataICAcomp.label, dataEOGComp.elements))';

fprintf(['Select components to reject!\n'...
         'Components which exceeded the selected EOG correlation '...'
         'threshold are already marked as bad.\n'...
         'These are:\n']);

for i = numOfElements
  [~, pos] = max(abs([dataEOGComp.eoghCorr(idx(i)) ...
                  dataEOGComp.eogvCorr(idx(i))]));
  if pos == 1
    corrVal = dataEOGComp.eoghCorr(idx(i)) * 100;
  else
    corrVal = dataEOGComp.eogvCorr(idx(i)) * 100;
  end
  fprintf('[%d] - component %d - %2.1f %% correlation\n', i, idx(i), corrVal);
end

filepath = fileparts(mfilename('fullpath'));                                % load cap layout
load(sprintf('%s/../layouts/mpi_customized_acticap32.mat', filepath), ...
     'lay');

cfg               = [];
cfg.rejcomp       = idx;
cfg.blocksize     = 30;
cfg.layout        = lay;
cfg.colormap      = 'jet';
cfg.showcallinfo  = 'no';

ft_warning off;
badComp = ft_icabrowser(cfg, dataICAcomp);
ft_warning on;

if sum(badComp) == 0
  cprintf([1,0.5,0],'No component is selected!\n');
  cprintf([1,0.5,0],'NOTE: The following cleaning operation will keep the data unchanged!\n');
end

dataEOGComp.elements = dataICAcomp.label(badComp);

end
