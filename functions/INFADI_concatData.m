function [ data ] = INFADI_concatData( data )
% INFADI_CONCATDATA concatenate all trials of a dataset to a continuous
% data stream.
%
% Use as
%   [ data ] = INFADI_concatData( data )
%
% where the input can be i.e. the result from INFADI_IMPORTDATASET or 
% INFADI_PREPROCESSING
%
% This function requires the fieldtrip toolbox.
%
% See also INFADI_IMPORTDATASET, INFADI_PREPROCESSING

% Copyright (C) 2018, Daniel Matthes, MPI CBS

% -------------------------------------------------------------------------
% Concatenate the data
% -------------------------------------------------------------------------
fprintf('Concatenate trials of participant 1...\n');
data.experimenter = concatenate(data.experimenter);

fprintf('Concatenate trials of participant 2...\n');
data.child = concatenate(data.child);

end

% -------------------------------------------------------------------------
% SUBFUNCTION for concatenation
% -------------------------------------------------------------------------
function [ dataset ] = concatenate( dataset )

numOfTrials = length(dataset.trial);                                        % estimate number of trials
trialLength = zeros(numOfTrials, 1);                                        
numOfChan   = size(dataset.trial{1}, 1);                                    % estimate number of channels

for i = 1:numOfTrials
  trialLength(i) = size(dataset.trial{i}, 2);                               % estimate length of single trials
end

dataLength  = sum( trialLength );                                           % estimate number of all samples in the dataset
data_concat = zeros(numOfChan, dataLength);
time_concat = zeros(1, dataLength);
endsample   = 0;

for i = 1:numOfTrials
  begsample = endsample + 1;
  endsample = endsample + trialLength(i);
  data_concat(:, begsample:endsample) = dataset.trial{i}(:,:);              % concatenate data trials
  if begsample == 1
    time_concat(1, begsample:endsample) = dataset.time{i}(:);               % concatenate time vectors
  else
    if (dataset.time{i}(1) == 0 )
      time_concat(1, begsample:endsample) = dataset.time{i}(:) + ...
                                time_concat(1, begsample - 1) + ...         % create continuous time scale
                                1/dataset.fsample;
    elseif(dataset.time{i}(1) > time_concat(1, begsample - 1))
      time_concat(1, begsample:endsample) = dataset.time{i}(:);             % keep existing time scale
    else
      time_concat(1, begsample:endsample) = dataset.time{i}(:) + ...
                                time_concat(1, begsample - 1) + ...         % create continuous time scale
                                1/dataset.fsample - ...
                                dataset.time{i}(1);
    end
  end
end

dataset.trial       = [];
dataset.time        = [];
dataset.trial{1}    = data_concat;                                          % add concatenated data to the data struct
dataset.time{1}     = time_concat;                                          % add concatenated time vector to the data struct
dataset.trialinfo   = 0;                                                    % add a fake event number to the trialinfo for subsequend artifact rejection
dataset.sampleinfo  = [1 dataLength];                                       % add also a fake sampleinfo for subsequend artifact rejection

end
