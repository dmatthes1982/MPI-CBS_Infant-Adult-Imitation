function [ data ] = INFADI_removeEOGArt( data_eogcomp, data )
% INFADI_REMOVEEOGART is a function which removes eye artifacts from data
% using in advance estimated ica components
%
% Use as
%   [ data ] = INFADI_removeEOGArt( data_eogcomp, data )
%
% where data_eogcomp has to be the result of INFADI_VERIFYCOMP or 
% INFADI_CORRCOMP and data has to be the result of INFADI_PREPROCESSING
%
% This function requires the fieldtrip toolbox
%
% See also INFADI_VERIFYCOMP, INFADI_CORRCOMP, INFADI_PREPROCESSING,
% FT_COMPONENTANALYSIS and FT_REJECTCOMPONENT

% Copyright (C) 2018, Daniel Matthes, MPI CBS

fprintf('<strong>Cleanig data of participant 1 from eye-artifacts...</strong>\n');
data.experimenter = removeArtifacts(data_eogcomp.experimenter, data.experimenter);
fprintf('<strong>Cleanig data of participant 2 from eye-artifacts...</strong>\n');
data.child = removeArtifacts(data_eogcomp.child, data.child);

end

% -------------------------------------------------------------------------
% SUBFUNCTION which does the removal of artifacts
% -------------------------------------------------------------------------
function [ dataOfPart ] = removeArtifacts(  dataEOG, dataOfPart )

cfg               = [];
cfg.unmixing      = dataEOG.unmixing;
cfg.topolabel     = dataEOG.topolabel;
cfg.demean        = 'no';
cfg.showcallinfo  = 'no';

ft_info off;
dataComp = ft_componentanalysis(cfg, dataOfPart);                           % estimate components with the in previous part 3 calculated unmixing matrix
ft_info on;

for i=1:length(dataEOG.elements)
  dataEOG.elements(i) = strrep(dataEOG.elements(i), 'runica', 'component'); % change names of eog-like components from runicaXXX to componentXXX
end

cfg               = [];
cfg.component     = find(ismember(dataComp.label, dataEOG.elements))';      % to be removed component(s)
cfg.demean        = 'no';
cfg.showcallinfo  = 'no';
cfg.feedback      = 'no';

ft_info off;
ft_warning off;
dataOfPart = ft_rejectcomponent(cfg, dataComp, dataOfPart);                 % revise data
ft_warning on;
ft_info on;

end
