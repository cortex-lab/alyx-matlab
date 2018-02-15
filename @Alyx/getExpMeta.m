function expMetaData = getExpMeta(obj, sessionURL)
%GETEXPMETA Returns experiment meta-data, given a session URL 
%   TODO Document!
% See also ALYX, GETDATA
%
% Part of Alyx

% 2017 -- created

allMeta = obj.getData('exp-metadata');
isThisExp = cell2mat(cellfun(@(x)strcmp(x.experiment, sessionURL), allMeta, 'uni', false));

expMetaData = allMeta(isThisExp);