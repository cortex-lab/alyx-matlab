function [dataset, filerecord] = registerFileNew(obj, filePaths)
%REGISTERFILE Registers a filepath to Alyx. The file being registered should already be on the target server.
%   The repository being registered to will be automatically determined
%   from the filePath. Registration work first by creating a dataset (a
%   record of the dataset type, creation date, md5 hash), and then a
%   filerecord (a record of the relative path within the repository). The
%   dataset is associated with a session, which must be provided. Also must
%   provide a datasetType. Can optionally provide a parentDataSet URL.
%
%   Inputs: 
%     -filePath: full path of the file being registered, including file
%     name and extension
%     -dataFormatName: data format, e.g. 'npy', 'mj2', or 'notData'
%     -session: Either Alyx URL for the session, an expRef, or cell {subject, date, number}.
%     -datasetTypeName: Block, Timeline, Parameters, eye.movie, etc.
%     -parentDatasetURL: optional URL for a parent dataset
%
% See also ALYX, GETDATA, POSTDATA, HTTP.JSONGET
%
% Part of Alyx

% 2017 PZH created

%%INPUT VALIDATION
filePaths = ensureCell(filePaths);
[relativePath, filename, ext] = cellfun(@fileparts, filePaths, 'uni', 0);
% Validate input paths
dataFormats = cellfun(@(f)['.' f.name], obj.getData('data-formats'), 'uni', 0);
valid = cellfun(@(e)any(strcmp(dataFormats,e))||isempty(e), ext);

assert( exist(filePaths,'file') || exist(filePaths,'dir'), 'Path %s does not exist', filePaths);
% assert( ~isdir(filePaths), 'filePath supplied must not be a folder');

% Log in, if required
if obj.IsLoggedIn == false; obj = obj.login; end

% Validate dataFormat supplied
dataFormats = obj.getData('data-formats');
dataFormats = [dataFormats{:}];
dataFormatIdx = strcmp({dataFormats.name}, datasetTypeName);
assert(~any(dataFormatIdx), 'dataFormat %s not found', dataFormatName);

if ischar(session)
  parsed = cellflat(regexp(session, dat.expRefRegExp, 'tokens'));
  if ~isempty(parsed) % Is an expRef
    subject = parsed{3};
    expDate = parsed{1};
    seq = parsed{2};
  else % Assumed session URL
    %Validate sessionURL supplied
    status = http.jsonGet(session, 'Authorization', ['Token ' obj.Token]);
    assert(status==200,'SessionURL Invalid');
  end
else
  subject = session{1};
  expDate = session{2};
  seq = session{3};
end

%Validate optional parentDatasetURL
if ~isempty(parentDatasetURL)
  [status,~] = http.jsonGet(parentDatasetURL, 'Authorization', ['Token ' obj.Token]);
  assert(status==200,'parentDatasetURL Invalid');
end

%Validate datasetType supplied
datasetTypes = obj.getData('dataset-types');
datasetTypes = [datasetTypes{:}];
datasetTypeIdx = strcmp({datasetTypes.name}, datasetTypeName);
assert(any(datasetTypeIdx), 'DatasetType %s not found', datasetTypeName);

%%Now some preparations
%Get datarepositories and their base paths
repositories = obj.getData('data-repository');
repo_paths = cellfun(@(r) r.name, repositories, 'uni', 0);

%Identify which repository the filePath is in
which_repo = cellfun( @(rp) contains(filePaths, rp), repo_paths);
assert(sum(which_repo) == 1, 'Input filePath\n%s\ndoes not contain the a repository path\n', filePaths);

%Define the relative path of the file within the repo
dnsId = regexp(filePaths, ['(?<=' repo_paths{which_repo} '.*)\\?'], 'once')+1;
relativePath = filePaths(dnsId:end);

%%Now submit Dataset and Filerecord to Alyx
pathInfo = dir(filePaths); %Get path creation date/etc
d = struct('created_by', obj.User,...
    'dataset_type', datasetTypeName,...
    'data_format', dataFormatName,...
    'created_date', Alyx.datestr(pathInfo.datenum));
if ischar(session)
    d.session = session;
elseif iscell(session)
    d.subject = subject;
    d.date = expDate;
    d.number = seq;
end

try
  d.md5 = mMD5(filePaths);
catch
  warning('Failed to compute MD5, using NULL');
end

if ~isempty(parentDatasetURL)
  d.parent_dataset = parentDatasetURL;
end

[datasetReturnData, statusCode] = obj.postData('datasets', d);
assert(statusCode(end)==201, 'Failed to submit dataset to Alyx');
  
d = struct('dataset', datasetReturnData(end).url,...
  'data_repository', repositories{which_repo}.name,...
  'relative_path', relativePath);

[fileRecordReturnData, statusCode] = obj.postData('files', d);
assert(statusCode(end)==201, 'Failed to submit filerecord to Alyx');

dataset = datasetReturnData(end);
filerecord = fileRecordReturnData(end);

%% Alyx-dev test
return
try %#ok<UNRCH>
  if ~contains(dataFormatName, '.npy')
    obj.BaseURL = 'https://alyx-dev.cortexlab.net';
    [relativePath, filename, ext] = fileparts(relativePath);
    subject = regexpi(relativePath, '(?<=Subjects\\)[A-Z_0-9]+', 'match');
    D.subject = subject{1};
    D.dirname = relativePath;
    D.filenames = {[filename, ext]};
    D.exists_in = repositories{which_repo}.name;
    [record, sc] = obj.postData('register-file', D);
  end
catch ex
  warning(ex.identifier, '%s', ex.message)
end
obj.BaseURL = 'https://alyx.cortexlab.net';
end