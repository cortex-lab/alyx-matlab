function [fullPath, exists] = getFile(obj, eid, type)
%GETFILE Returns the full filepath for a given eid.
%	Returns the full path of associated data files given a dataset or file
%	record URL or eid (experiment ID). Also returns a logical array 
% indicating whether files exist for each element in the `eid` array.
%
% Inputs:
%   `eid`: a string or char array containing the full URL(s) or eid(s) of 
%   dataset(s) / file record(s) on Alyx.
%   `type`: a string indicating type of eid(s) ('dataset' (default) or 
%   'file')
%
% Outputs:
%   `fullPath`: a cellstring containing the full data file path(s) for
%   each element in the `eid` array
%   `exists`: a logical array indicating whether files exist for each eid
%   in the `eid` array
%
% See also ALYX, GETDATA, GETSESSIONS
%
% Part of Alyx
% 2017 PZH created
% 2019 MW Rewrote

if nargin < 3; type = 'dataset'; end

% Convert array of strings to cell string
if isstring(eid) && ~isscalar(eid)
  eid = cellstr(eid);
else
  eid = ensureCell(eid);
end

% Validate URL (UUIDs have 36 characters)
assert(all(cellfun(@(str)ischar(str) && length(str) >= 36, eid)), 'Invalid eid')
eid = mapToCell(@(str)str(end-35:end), eid);

% Get all file records
switch lower(type)
  case 'file'
    filerecords = mapToCell(@(url)obj.getData(['files/', url]), eid);
    repos = obj.getData('data-repository');
    repos = containers.Map({repos.name}, {repos.data_url});
    fullPath = mapToCell(@(s)[repos(s.data_repository) s.relative_path], filerecords);
    exists = cellfun(@(s)s.exists, filerecords);
    % Return as char if user expects one output
    if numel(eid) == 1; fullPath = fullPath{1}; end
  case 'dataset'
    filerecords = catStructs(mapToCell(@(url)getOr(obj.getData(['datasets/', url]), 'file_records'), eid));
    exists = [filerecords.exists];
    fullPath = {filerecords.data_url};
    % Remove records with empty url field
    exists = exists(emptyElems(fullPath));
    fullPath = rmEmpty(fullPath);
  otherwise
    error('Alyx:GetFile:InvalidType', 'Invalid eid type: must be ''dataset'' or ''file''')
end

