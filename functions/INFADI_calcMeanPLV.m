function [ data ] = INFADI_calcMeanPLV( data )
% INFADI_CALCMEANPLV estimates the mean of the phase locking values within
% the different conditions for all dyads and connections.
%
% Use as
%   [ data ] = INFADI_calcMeanPLV( data )
%
%  where the input data have to be the result from INFADI_PHASELOCKVAL
%
% This function requires the fieldtrip toolbox
% 
% See also INFADI_DATASTRUCTURE, INFADI_PHASELOCKVAL

% Copyright (C) 2018, Daniel Matthes, MPI CBS 

% -------------------------------------------------------------------------
% Estimate mean Phase Locking Value (mPLV)
% -------------------------------------------------------------------------

fprintf('<strong>Calc mean PLVs with a center frequency of %g Hz...</strong>\n', ...           
          data.centerFreq);
numOfTrials = size(data.dyad.PLV, 2);
numOfElecA = size(data.dyad.PLV{1}, 1);
numOfElecB = size(data.dyad.PLV{1}, 2);

data.dyad.mPLV{1, numOfTrials} = [];
for i=1:1:numOfTrials
  data.dyad.mPLV{i} = zeros(numOfElecA, numOfElecB);
  for j=1:1:numOfElecA
    for k=1:1:numOfElecB
    data.dyad.mPLV{i}(j,k) = mean(cell2mat(data.dyad.PLV{i}(j,k)));
    end
  end
end
data.dyad = rmfield(data.dyad, {'time', 'PLV'});

end

