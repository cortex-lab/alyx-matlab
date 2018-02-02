function expMetaData = getExpMeta(obj, expUrl)
%GETEXPMETA Returns experiment meta-data, given an experiment URL 
%   TODO Document!
% See also ALYX, GETDATA
%
% Part of Alyx

% 2017 -- created

allMeta = obj.getData('exp-metadata');
isThisExp = cell2mat(cellfun(@(x)strcmp(x.experiment, expUrl), allMeta, 'uni', false));

expMetaData = allMeta(isThisExp);