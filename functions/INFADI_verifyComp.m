function [ data_eogcomp ] = INFADI_verifyComp( cfg, data_eogcomp, data_icacomp )
% INFADI_VERIFYCOMP is a function to verify visually the ICA components
% having a high correlation with one of the measured EOG signals.
%
% Use as
%   [ data_eogcomp ] = INFADI_verifyComp( data_eogcomp, data_icacomp )
%
% where the input data_eogcomp has to be the result of INFADI_CORRCOMP ans 
% data_icacomp the result of INFADI_ICA
%
% The configuration options are
%   cfg.part        = participants which shall be processed: experimenter, child or both (default: both)
%
% This function requires the fieldtrip toolbox
%
% See also INFADI_CORRCOMP, INFADI_ICA and FT_DATABROWSER

% Copyright (C) 2018, Daniel Matthes, MPI CBS

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
  fprintf('<strong>Verify EOG-correlating components at experinmenter...</strong>\n');
  data_eogcomp.experimenter = corrComp(data_eogcomp.experimenter, data_icacomp.experimenter);
end

fprintf('\n');

if ismember(part, {'child', 'both'})
  fprintf('<strong>Verify EOG-correlating components at child...</strong>\n');
  data_eogcomp.child = corrComp(data_eogcomp.child, data_icacomp.child);
end

end

%--------------------------------------------------------------------------
% SUBFUNCTION which does the verification of the EOG-correlating components
%--------------------------------------------------------------------------
function [ dataEOGComp ] = corrComp( dataEOGComp, dataICAcomp )

numOfElements = 1:length(dataEOGComp.elements);

cfg               = [];
cfg.layout        = 'mpi_customized_acticap32.mat';
cfg.viewmode      = 'component';
cfg.zlim          = 'maxabs';
cfg.channel       = find(ismember(dataICAcomp.label, dataEOGComp.elements))';
cfg.blocksize     = 30;
cfg.showcallinfo  = 'no';

ft_info off;
ft_databrowser(cfg, dataICAcomp);
set(gcf, 'Position', [0, 0, 1000, 500]);
movegui(gcf, 'center');
colormap jet;
ft_info on;

commandwindow;
selection = false;
    
while selection == false
  fprintf('Do you want to deselect some of theses components?\n')
  for i = numOfElements
    fprintf('[%d] - %s\n', i, dataEOGComp.elements{i});
  end
  fprintf('Comma-seperate your selection and put it in squared brackets!\n');
  fprintf('Press simply enter if you do not want to deselect any component!\n');
  x = input('\nPlease make your choice! (i.e. [1,2,3]): ');

  if ~isempty(x)
    if ~all(ismember(x, numOfElements))
      selection = false;
      fprintf('At least one of the selected components does not exist.\n');
    else
      selection = true;
      fprintf('Component(s) %d will not used for eye artifact correction\n', x);
      
      dataEOGComp.elements = dataEOGComp.elements(~ismember(numOfElements,x));
    end
  else
    selection = true;
    fprintf('No Component will be rejected.\n');
  end
end

close(gcf);

end
