function [dataset, filerecord] = registerFile2(filePath, dataFormatName, sessionURL, datasetTypeName, parentDatasetURL, alyxInstance)
%[dataset,filerecord] = registerPath(path, dataFormatName, sessionURL, datasetTypeName, parentDatasetURL, alyxInstance)
% Registers a ZSERVER path to Alyx. This works first by creating a dataset (a record of the dataset type, creation date, md5 hash), and
% then a filerecord (a record of the relative path within the repository). The dataset is associated with a session, which
% must be provided. Also must provide a datasetType. Can optionally provide
% a parentDataSet URL and alyxInstance
% Inputs:
% -path: full path of the file/directory being registered
% -dataFormatName: data format, e.g. 'npy', 'mj2', or 'directory'
% -sessionURL: Alyx URL for the session.
% -datasetTypeName: Block, Timeline, Parameters, etc
% -parentDatasetURL: optional URL for a parent dataset
% -AlyxInstance: Optional alyx instance object, created from alyx.loginWindow().

%%INPUT VALIDATION
%Validate input path
assert( ~contains(filePath,'/'), 'Do not use forward slashes in the path');
assert( exist(filePath,'file') == 2 , 'Path %s does not exist', filePath);
assert( ~isdir(filePath), 'filePath supplied must not be a folder');

%Validate alyxInstance, creating one if not supplied
if isempty(alyxInstance); alyxInstance = alyx.loginWindow(); end
assert(isfield(alyxInstance,'token'), 'Supplied alyxInstance is improper');

%Validate dataFormat supplied
dataFormats = alyx.getData(alyxInstance,['data-formats']);
dataFormats = [dataFormats{:}];
datasetTypeIdx = find( contains({dataFormats.name}, dataFormatName) );
assert( numel(datasetTypeIdx)==1, 'dataFormats error: no matching for %s', dataFormatName);

%Validate sessionURL supplied
[status,body] = http.jsonGet(sessionURL, 'Authorization', ['Token ' alyxInstance.token]);
assert(status==200,'SessionURL Invalid');

%Validate optional parentDatasetURL
if ~isempty(parentDatasetURL)
    [status,body] = http.jsonGet(parentDatasetURL, 'Authorization', ['Token ' alyxInstance.token]);
    assert(status==200,'parentDatasetURL Invalid');
end

%Validate datasetType supplied
datasetTypes = alyx.getData(alyxInstance,'dataset-types'); 
datasetTypes = [datasetTypes{:}];
datasetTypeIdx = find( strcmp({datasetTypes.name},datasetTypeName) );
assert( numel(datasetTypeIdx)>=1, 'DatasetType %s not found', datasetTypeName);
assert( numel(datasetTypeIdx)==1, 'DatasetType error: too many matches for that type');

%% Now some preparations
%Get datarepository ZSERVER
repository = alyx.getData(alyxInstance, ['data-repository?name=zserver']);
assert(~isempty(repository),'ZServer repository object not found');

%Check that input path is within the repository's path
if startsWith(filePath,repository{1}.path)
    relativePath = strrep(filePath,repository{1}.path,'');
else
    error('Input filePath\n%s\ndoes not contain the repository path\n%s',filePath,repository{1}.path);
end

%% Now submit Dataset and Filerecord to Alyx
pathInfo = dir(filePath); %Get path creation date/etc
d = struct('created_by',alyxInstance.username,...
    'dataset_type',datasetTypeName,...
    'data_format',dataFormatName,...
    'parent_dataset',parentDatasetURL,...
    'session',sessionURL,...
    'created_date',alyx.datestr(pathInfo.datenum));
try
    d.md5 = mMD5(filePath);
catch
    warning('Failed to compute MD5, using NULL');
end

[datasetReturnData, statusCode] = alyx.postData(alyxInstance, 'datasets', d);
assert(statusCode==201, 'Failed to submit dataset to Alyx');

d = struct('dataset', datasetReturnData.url,...
    'data_repository', 'zserver',...
    'relative_path', relativePath);

[fileRecordReturnData, statusCode] = alyx.postData(alyxInstance, 'files', d);
assert(statusCode==201, 'Failed to submit filerecord to Alyx');

dataset = datasetReturnData;
filerecord = fileRecordReturnData;
end