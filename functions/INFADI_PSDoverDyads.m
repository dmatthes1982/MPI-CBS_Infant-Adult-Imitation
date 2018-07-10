function  [ data_pwelchod ] = INFADI_PSDoverDyads( cfg )
% INFADI_PSDOVERDYADS estimates the mean of the power spectral density
% values over dyads for all conditions separately for experimenters and
% children.
%
% Use as
%   [ data_pwelchod ] = INFADI_PSDoverDyads( cfg )
%
% The configuration options are
%   cfg.path      = source path' (i.e. '/data/pt_01905/eegData/DualEEG_INFADI_processedData/08b_pwelch/')
%   cfg.session   = session number (default: 1)
%
% This function requires the fieldtrip toolbox
% 
% See also INFADI_PWELCH

% Copyright (C) 2018, Daniel Matthes, MPI CBS 

% -------------------------------------------------------------------------
% Get and check config options
% -------------------------------------------------------------------------
path      = ft_getopt(cfg, 'path', ...
              '/data/pt_01905/eegData/DualEEG_INFADI_processedData/08b_pwelch/');
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
fprintf('<strong>Averaging PSD values over dyads...</strong>\n');

dyadsList   = dir([path, sprintf('INFADI_d*_08b_pwelch_%03d.mat', session)]);
dyadsList   = struct2cell(dyadsList);
dyadsList   = dyadsList(1,:);
numOfDyads  = length(dyadsList);

for i=1:1:numOfDyads
  listOfDyads(i) = sscanf(dyadsList{i}, ['INFADI_d%d_08b'...
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
% Load and organize data
% -------------------------------------------------------------------------
data_out.experimenter.trialinfo = generalDefinitions.condNum';
data_out.child.trialinfo        = generalDefinitions.condNum';

dataExp{1, numOfDyads}        = [];
dataChild{1, numOfDyads}      = [];
trialinfoExp{1, numOfDyads}   = [];
trialinfoChild{1, numOfDyads} = [];

for i=1:1:numOfDyads
  filename = sprintf('INFADI_d%02d_08b_pwelch_%03d.mat', listOfDyads(i), ...
                     session);
  file = strcat(path, filename);
  fprintf('Load %s ...\n', filename);
  load(file, 'data_pwelch');
  dataExp{i}        = data_pwelch.experimenter.powspctrm;
  dataChild{i}      = data_pwelch.child.powspctrm;
  trialinfoExp{i}   = data_pwelch.experimenter.trialinfo;
  trialinfoChild{i} = data_pwelch.child.trialinfo;
  if i == 1
    data_out.experimenter.label   = data_pwelch.experimenter.label;
    data_out.child.label          = data_pwelch.child.label;
    data_out.experimenter.dimord  = data_pwelch.experimenter.dimord;
    data_out.child.dimord         = data_pwelch.child.dimord;
    data_out.experimenter.freq    = data_pwelch.experimenter.freq;
    data_out.child.freq           = data_pwelch.child.freq;
  end
  clear data_pwelch
end
fprintf('\n');

dataExp   = cellfun(@(x) num2cell(x, [2,3])', dataExp, 'UniformOutput', false);
dataChild = cellfun(@(x) num2cell(x, [2,3])', dataChild, 'UniformOutput', false);

for i=1:1:numOfDyads
  dataExp{i}    = cellfun(@(x) squeeze(x), dataExp{i}, 'UniformOutput', false);
  dataChild{i}  = cellfun(@(x) squeeze(x), dataChild{i}, 'UniformOutput', false);
end

dataExp   = fixTrialOrder( dataExp, trialinfoExp, generalDefinitions.condNum, ...
                      listOfDyads, 'Experimenter' );
dataChild = fixTrialOrder( dataChild, trialinfoChild, generalDefinitions.condNum, ...
                      listOfDyads, 'Child' );

dataExp = cellfun(@(x) cat(3, x{:}), dataExp, 'UniformOutput', false);
dataExp = cellfun(@(x) shiftdim(x, 2), dataExp, 'UniformOutput', false);
dataExp = cat(4, dataExp{:});

dataChild = cellfun(@(x) cat(3, x{:}), dataChild, 'UniformOutput', false);
dataChild = cellfun(@(x) shiftdim(x, 2), dataChild, 'UniformOutput', false);
dataChild = cat(4, dataChild{:});

% -------------------------------------------------------------------------
% Estimate averaged power spectral density (over dyads)
% -------------------------------------------------------------------------
dataExp   = nanmean(dataExp, 4);
dataChild = nanmean(dataChild, 4);

data_out.experimenter.powspctrm = dataExp;
data_out.child.powspctrm        = dataChild;
data_out.dyads                  = listOfDyads;

data_pwelchod = data_out;

end

%--------------------------------------------------------------------------
% SUBFUNCTION which fixes trial order and creates empty matrices for 
% missing phases.
%--------------------------------------------------------------------------
function dataTmp = fixTrialOrder( dataTmp, trInf, trInfOrg, dyadNum, part )

if strcmp(part, 'Experimenter')
  emptyMatrix = NaN * ones(35,50);                                          % empty matrix with NaNs
elseif strcmp(part, 'Child')
  emptyMatrix = NaN * ones(31,50);                                          % empty matrix with NaNs
end
fixed = false;

for k = 1:1:size(dataTmp, 2)
  if ~isequal(trInf{k}, trInfOrg')
    missingPhases = ~ismember(trInfOrg, trInf{k});
    missingPhases = trInfOrg(missingPhases);
    missingPhases = vec2str(missingPhases, [], [], 0);
    cprintf([1,0.4,1], ...
            sprintf('Dyad %d - %s: Phase(s) %s missing. Empty matrix(matrices) with NaNs created.\n', ...
            dyadNum(k), part, missingPhases));
    [~, loc] = ismember(trInfOrg, trInf{k});
    tmpBuffer = [];
    tmpBuffer{length(trInfOrg)} = [];                                       %#ok<AGROW>
    for l = 1:1:length(trInfOrg)
      if loc(l) == 0
        tmpBuffer{l} = emptyMatrix;
      else
        tmpBuffer(l) = dataTmp{k}(loc(l));
      end
    end
    dataTmp{k} = tmpBuffer;
    fixed = true;
  end
end

if fixed == true
  fprintf('\n');
end

end
