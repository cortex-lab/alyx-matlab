function [dataset, filerecord] = registerFile(obj, filePath, dataFormatName, sessionURL, datasetTypeName, parentDatasetURL)
%REGISTERFILE Registers a filepath to Alyx. The file being registered should already be on the target server.
%   The repository being registered to will be automatically determined
%   from the filePath. Registration work first by creating a dataset (a
%   record of the dataset type, creation date, md5 hash), and then a
%   filerecord (a record of the relative path within the repository). The
%   dataset is associated with a session, which must be provided. Also must
%   provide a datasetType. Can optionally provide a parentDataSet URL.
%   
%   Inputs: 
%     -filePath: full path of the file being registered
%     -dataFormatName: data format, e.g. 'npy', 'mj2', or 'notData'
%     -sessionURL: Alyx URL for the session
%     -datasetTypeName: Block, Timeline, Parameters, eye.movie, etc.
%     -parentDatasetURL: optional URL for a parent dataset
%
% See also ALYX, GETDATA, POSTDATA, HTTP.JSONGET
%
% Part of Alyx

% 2017 PZH created

%%INPUT VALIDATION
% Validate input path
assert( ~contains(filePath,'/'), 'Do not use forward slashes in the path');
assert( exist(filePath,'file') == 2 , 'Path %s does not exist', filePath);
assert( ~isdir(filePath), 'filePath supplied must not be a folder');

% Log in, if required
if obj.IsLoggedIn == false; obj.login; end

% Validate dataFormat supplied
dataFormats = obj.getData('data-formats');
dataFormats = [dataFormats{:}];
dataFormatIdx = strcmp({dataFormats.name}, datasetTypeName);
assert(~any(dataFormatIdx), 'dataFormat %s not found', dataFormatName);

%Validate sessionURL supplied
[status,~] = http.jsonGet(sessionURL, 'Authorization', ['Token ' alyxInstance.token]);
assert(status==200,'SessionURL Invalid');

%Validate optional parentDatasetURL
if ~isempty(parentDatasetURL)
  [status,~] = http.jsonGet(parentDatasetURL, 'Authorization', ['Token ' alyxInstance.token]);
  assert(status==200,'parentDatasetURL Invalid');
end

%Validate datasetType supplied
datasetTypes = obj.getData('dataset-types');
datasetTypes = [datasetTypes{:}];
datasetTypeIdx = strcmp({datasetTypes.name}, datasetTypeName);
assert(~any(datasetTypeIdx), 'DatasetType %s not found', datasetTypeName);

%%Now some preparations
%Get datarepositories and their base paths
repositories = obj.getData('data-repository');
repo_paths = cellfun(@(r) r.path, repositories, 'uni', 0);

%Identify which repository the filePath is in
which_repo = cellfun( @(rp) startsWith(filePath, rp), repo_paths);
assert(sum(which_repo) == 1, 'Input filePath\n%s\ndoes not contain the a repository path\n',filePath);

%Define the relative path of the file within the repo
relativePath = strrep(filePath, repo_paths{which_repo}, '');

%%Now submit Dataset and Filerecord to Alyx
pathInfo = dir(filePath); %Get path creation date/etc
d = struct('created_by', obj.User,...
  'dataset_type', datasetTypeName,...
  'data_format', dataFormatName,...
  'session', sessionURL,...
  'created_date', obj.datestr(pathInfo.datenum));
try
  d.md5 = mMD5(filePath);
catch
  warning('Failed to compute MD5, using NULL');
end

if ~isempty(parentDatasetURL)
  d.parent_dataset = parentDatasetURL;
end

[datasetReturnData, statusCode] = obj.postData('datasets', d);
assert(statusCode==201, 'Failed to submit dataset to Alyx');

d = struct('dataset', datasetReturnData.url,...
  'data_repository', repositories{which_repo}.name,...
  'relative_path', relativePath);

[fileRecordReturnData, statusCode] = obj.postData('files', d);
assert(statusCode==201, 'Failed to submit filerecord to Alyx');

dataset = datasetReturnData;
filerecord = fileRecordReturnData;
end