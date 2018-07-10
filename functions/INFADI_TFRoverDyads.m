function  [ data_tfrod ] = INFADI_TFRoverDyads( cfg )
% INFADI_TFROVERDYADS estimates the mean of the time frequency responses
% over dyads for all conditions seperately for experimenters and children.
%
% Use as
%   [ data_tfrod ] = INFADI_TFRoverDyads( cfg )
%
% The configuration options are
%   cfg.path      = source path' (i.e. '/data/pt_01905/eegData/DualEEG_INFADI_processedData/08a_tfr/')
%   cfg.session   = session number (default: 1)
%
% This function requires the fieldtrip toolbox
% 
% See also INFADI_TIMEFREQANALYSIS

% Copyright (C) 2018, Daniel Matthes, MPI CBS 

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
path      = ft_getopt(cfg, 'path', ...
              '/data/pt_01905/eegData/DualEEG_INFADI_processedData/08a_tfr/');
session   = ft_getopt(cfg, 'session', 1);

% -------------------------------------------------------------------------
% Load general definitions
% -------------------------------------------------------------------------
filepath = fileparts(mfilename('fullpath'));
load(sprintf('%s/../general/INFADI_generalDefinitions.mat', filepath), ...
     'generalDefinitions');   

% -------------------------------------------------------------------------
% Select dyads
% -------------------------------------------------------------------------    
fprintf('<strong>Averaging TFR values over dyads...</strong>\n');

dyadsList   = dir([path, sprintf('INFADI_d*_08a_tfr_%03d.mat', session)]);
dyadsList   = struct2cell(dyadsList);
dyadsList   = dyadsList(1,:);
numOfDyads  = length(dyadsList);

for i=1:1:numOfDyads
  listOfDyads(i) = sscanf(dyadsList{i}, ['INFADI_d%d_08a'...
                                   sprintf('%03d.mat', session)]);          %#ok<AGROW>
end

y = sprintf('%d ', listOfDyads);
selection = false;

while selection == false
  fprintf('The following dyads are available: %s\n', y);
  x = input('Which dyads should be included into the averaging? (i.e. [1,2,3]):\n');
  if ~all(ismember(x, listOfDyads))
    cprintf([1,0.5,0], 'Wrong input!\n');
  else
    selection = true;
    listOfDyads = x;
  end
end
fprintf('\n');

% -------------------------------------------------------------------------
% Load, organize and summarize data
% -------------------------------------------------------------------------
data_out.experimenter.trialinfo = generalDefinitions.condNum';
data_out.child.trialinfo        = generalDefinitions.condNum';

numOfTrialsExp    = zeros(1, length(data_out.experimenter.trialinfo));
numOfTrialsChild  = zeros(1, length(data_out.child.trialinfo));
tfrExp{length(data_out.experimenter.trialinfo)} = [];
tfrChild{length(data_out.child.trialinfo)}      = [];

for i=1:1:numOfDyads
  filename = sprintf('INFADI_d%02d_08a_tfr_%03d.mat', listOfDyads(i), ...
                     session);
  file = strcat(path, filename);
  fprintf('Load %s ...\n', filename);
  load(file, 'data_tfr');
  tfr1   = data_tfr.experimenter.powspctrm;
  tfr2   = data_tfr.child.powspctrm;
  trialinfo_tmp = data_tfr.experimenter.trialinfo;
  if i == 1
    data_out.experimenter.label   = data_tfr.experimenter.label;
    data_out.child.label          = data_tfr.child.label;
    data_out.experimenter.dimord  = data_tfr.experimenter.dimord;
    data_out.child.dimord         = data_tfr.child.dimord;
    data_out.experimenter.freq    = data_tfr.experimenter.freq;
    data_out.child.freq           = data_tfr.child.freq;
    data_out.experimenter.time    = data_tfr.experimenter.time;
    data_out.child.time           = data_tfr.child.time;
    tfrExp(:)   = {zeros(length(data_out.experimenter.label), ...
                    length(data_out.experimenter.freq), ...
                    length(data_out.experimenter.time))};
    tfrChild(:) = {zeros(length(data_out.child.label), ...
                    length(data_out.child.freq), ...
                    length(data_out.child.time))};
  end
  clear data_tfr
  
  tfr1 = num2cell(tfr1, [2,3,4])';
  tfr1 = cellfun(@(x) squeeze(x), tfr1, 'UniformOutput', false);
  [tfr1,trialSpec1] = fixTrialOrder( tfr1, trialinfo_tmp, ...
                                      generalDefinitions.condNum, i, 1);
  
  tfr2 = num2cell(tfr2, [2,3,4])';
  tfr2 = cellfun(@(x) squeeze(x), tfr2, 'UniformOutput', false);
  [tfr2, trialSpec2] = fixTrialOrder( tfr2, trialinfo_tmp, ...
                                      generalDefinitions.condNum, i, 2);
  
  tfrExp    = cellfun(@(x,y) x+y, tfrExp, tfr1, 'UniformOutput', false);
  numOfTrialsExp    = numOfTrialsExp + trialSpec1;

  tfrChild  = cellfun(@(x,y) x+y, tfrChild, tfr2, 'UniformOutput', false);
  numOfTrialsChild  = numOfTrialsChild + trialSpec2;
end

numOfTrialsExp    = num2cell(numOfTrialsExp);
numOfTrialsChild  = num2cell(numOfTrialsChild);

tfrExp = cellfun(@(x,y) x/y, tfrExp, numOfTrialsExp, 'UniformOutput', false);
tfrExp = cat(4, tfrExp{:});
tfrExp = shiftdim(tfrExp, 3);

tfrChild = cellfun(@(x,y) x/y, tfrChild, numOfTrialsChild, 'UniformOutput', false);
tfrChild = cat(4, tfrChild{:});
tfrChild = shiftdim(tfrChild, 3);

data_out.experimenter.powspctrm   = tfrExp;
data_out.child.powspctrm          = tfrChild;
data_out.dyads                    = listOfDyads;

data_tfrod = data_out;

end

%--------------------------------------------------------------------------
% SUBFUNCTION which fixes trial order and creates empty matrices for 
% missing phases.
%--------------------------------------------------------------------------
function [dataTmp, NoT] = fixTrialOrder( dataTmp, trInf, trInfOrg, ...
                                        dyadNum, part )

emptyMatrix = zeros(35, 49, 345);                                           % empty matrix
fixed = false;
NoT = ones(1, length(trInfOrg));

if ~isequal(trInf, trInfOrg')
  missingPhases = ~ismember(trInfOrg, trInf);
  missingPhases = trInfOrg(missingPhases);
  if ~isempty(missingPhases)
    missingPhases = vec2str(missingPhases, [], [], 0);
    cprintf([1,0.4,1], ...
          sprintf('Dyad %d/%d: Phase(s) %s missing. Empty matrix(matrices) with zeros created.\n', ...
          dyadNum, part, missingPhases));
    fixed = true;
  end
  [~, loc] = ismember(trInfOrg, trInf);
  tmpBuffer = [];
  tmpBuffer{length(trInfOrg)} = [];
  for j = 1:1:length(trInfOrg)
    if loc(j) == 0
      NoT(j) = 0;
      tmpBuffer{j} = emptyMatrix;
    else
      tmpBuffer(j) = dataTmp(loc(j));
    end
  end
  dataTmp = tmpBuffer;
end

if fixed == true
  fprintf('\n');
end

end
