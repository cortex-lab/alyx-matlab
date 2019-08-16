function [fullPath, exists] = getFile(obj, eid, type, remoteOnly)
%GETFILE Returns the full filepath for a given eid.
%	Returns the full path of associated data files given a dataset or file
%	record URL or eid (experiment ID). Also returns a logical array 
% indicating whether files exist for each element in the `eid` array.
%
% Inputs:
%   `eid`: a string or char array containing the full URL(s) or eid(s) of 
%       dataset(s) / file record(s) on Alyx.
%   `type`: a string indicating type of eid(s) ('dataset' (default) or 
%       'file').
%   `remoteOnly`: a logical indicating whether to only return paths
%       associated with a valid data_url field.  Default false.
%
% Outputs:
%   `fullPath`: a cellstring containing the full data file path(s) for
%   each element in the `eid` array
%   `exists`: a logical array indicating whether files exist for each eid
%   in the `eid` array
%
% FIXME with > 1 datasets output not the same size as input array 
% @body Should package into cell array the size of eid array.  The user the
% option to cellflat the output if the want
%
% See also ALYX, GETDATA, GETSESSIONS
%
% Part of Alyx
% 2017 PZH created
% 2019 MW Rewrote

if nargin < 3; type = 'dataset'; end
if nargin < 4; remoteOnly = false; end

% Convert array of strings to cell string
if isstring(eid) && ~isscalar(eid)
  eid = cellstr(eid);
else
  eid = ensureCell(eid);
end

% Validate URL (UUIDs have 36 characters)
assert(all(cellfun(@(str)ischar(str) && length(str) >= 36, eid)), 'Invalid eid')
eid = mapToCell(@(str)str(end-35:end), eid);

% Create map for base path using url or hostname fields.  If data_rul
% field is empty, assume an SMB protocol
repos = obj.getData('data-repository');
base = @(x) iff(isempty(x.data_url), ['\\' x.hostname], x.data_url);
repos = containers.Map({repos.name}, arrayfun(base, repos, 'uni', 0));

% Get all file records
switch lower(type)
  case 'file'
    filerecords = mapToCell(@(url)obj.getData(['files/', url]), eid);
    fullPath = mapToCell(@(s)[repos(s.data_repository) s.relative_path], filerecords);
    exists = cellfun(@(s)s.exists, filerecords);
    % Return as char if user expects one output
    if numel(eid) == 1; fullPath = fullPath{1}; end
  case 'dataset'
    filerecords = catStructs(mapToCell(@(url)getOr(obj.getData(['datasets/', url]), 'file_records'), eid));
    exists = [filerecords.exists];
    % Generate full paths
    makePath = @(s) iff(isempty(s.data_url), ... % If the data url is empty...
      fullfile(repos(s.data_repository), s.relative_path), ... % SMB access
      s.data_url); % URL access (http(s)).  This is already a full path
    fullPath = mapToCell(makePath, filerecords);
    % Remove records with empty url field
    if remoteOnly % i.e. only those with data url
      discard = emptyElems({filerecords.data_url});
      exists(discard) = [];
      fullPath(discard) = [];
    end
  otherwise
    error('Alyx:GetFile:InvalidType', 'Invalid eid type: must be ''dataset'' or ''file''')
end

