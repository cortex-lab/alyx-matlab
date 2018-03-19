function registerALF(obj, alfDir, sessionURL)
%REGISTERALFTOALYX Register files contained within alfDir to Alyx
%   This function registers files contained within the alfDir to Alyx.
%   Files are only registered if their filenames match a datasetType's
%   alf_filename field. Must also provide an alyx session URL. Optionally
%   can provide alyxInstance as well.
%
%   INPUTS:
%     -alfDir: Directory containing ALF files, this will be searched
%     recursively for all ALF files which match a datasetType
%     -endpoint (optional): Alyx URL of the session to register this data
%     to. If none supplied, will use SessionURL in obj.  If this is unset,
%     an error is thrown.
%
% See also ALYX, REGISTERFILES, POSTDATA, HTTP.JSONGET
% TODO: Fix up; Put in +alf??
% TODO: Validate data repository
% Part of Alyx

% 2017 NS created

if nargin < 3
  if isempty(obj.SessionURL)
    error('No session URL set')
  else
    sessionURL = obj.SessionURL;
  end
end

assert(~isempty(which('dirPlus')),...
  'Function ''dirPlus'' not found, make sure alyx helpers folder is added to path')

%%INPUT VALIDATION
% Validate alfDir path
assert(~contains(alfDir,'/'), 'Do not use forward slashes in the path');
assert(exist(alfDir,'dir') == 7 , 'alfDir %s does not exist', alfDir);

% Validate alyxInstance, creating one if not supplied
if ~obj.IsLoggedIn; obj = obj.login; end

%%Validate that the files within alfDir match a datasetType.
%1) Get all datasetTypes from the database, and list the alf_filenames
datasetTypes = obj.getData('dataset-types');
datasetTypes = [datasetTypes{:}];
datasetTypes_filemasks = {datasetTypes.alf_filename};
datasetTypes_filemasks(cellfun(@isempty,datasetTypes_filemasks)) = {''}; %Ensures all entries are character arrays

%2) Get all the files contained within the alfDir, which match a
%datasetType in the Alyx database
function v = validateFcn(fileObj)
    match = regexp(fileObj.name, regexptranslate('wildcard',datasetTypes_filemasks));
    v = ~isempty([match{:}]);
end
alfFiles = dirPlus(alfDir, 'ValidateFileFcn', @validateFcn, 'Struct', true);
assert(~isempty(alfFiles), 'No files within %s matched a datasetType', alfDir);

%% Define a hierarchy of alfFiles based on the ALF naming scheme: parent.child.*
alfFileParts = cellfun(@(name) strsplit(name,'.'), {alfFiles.name}, 'uni', 0);
alfFileParts = cat(1, alfFileParts{:});

%Create parent datasets, which contain no filerecords themselves
[parentTypes, ~, parentID] = unique(alfFileParts(:,1));
parentURLs = cell(size(parentTypes));
fprintf('Creating parent datasets... ');
for parent = 1:length(parentTypes)
    d = struct('created_by', obj.User,...
               'dataset_type', parentTypes{parent},...
               'session', sessionURL,...
               'data_format', 'notData');
    w = obj.postData('datasets',d);
    parentURLs{parent} = w.url;
end

%Now go through each file, creating a dataset and filerecord for that file
for file = 1:length(alfFiles)
    fullPath = fullfile(alfFiles(file).folder, alfFiles(file).name);
    fileFormat = alfFileParts{file,3};
    parentDataset = parentURLs{parentID(file)};

    datasetTypes_filemasks(contains(datasetTypes_filemasks,'*.*')) = []; % Remove parant datasets from search
    matchIdx = regexp(alfFiles(file).name, regexptranslate('wildcard', datasetTypes_filemasks));
    matchIdx = find(~cellfun(@isempty, matchIdx));
    assert(numel(matchIdx)==1, 'Insufficient/Too many matches of datasetType for file %s', alfFiles(file).name);
    datasetType = datasetTypes(matchIdx).name;
    
    obj.registerFile(fullPath, fileFormat, sessionURL, datasetType, parentDataset);
    
    fprintf('Registered file %s as datasetType %s\n', alfFiles(file).name, datasetType);
end

%% Alyx-dev
return
try %#ok<UNRCH>
  %Get datarepositories and their base paths
  repositories = obj.getData('data-repository');
  repo_paths = cellfun(@(r) r.path, repositories, 'uni', 0);
  
  %Identify which repository the filePath is in
  which_repo = cellfun( @(rp) startsWith(alfDir, rp), repo_paths);
  assert(sum(which_repo) == 1, 'Input filePath\n%s\ndoes not contain the a repository path\n', alfDir);
  relativePath = strrep(alfDir, repo_paths{which_repo}, '');
  if relativePath(1)=='\'; relativePath = relativePath(2:end); end
  obj.BaseURL = 'https://alyx-dev.cortexlab.net';
  subject = regexpi(relativePath, '(?<=Subjects\\)[A-Z_0-9]+', 'match');
  
  D.subject = subject{1};
  D.filenames = {alfFiles.name};
  D.dirname = relativePath;
  D.exists_in = repositories{which_repo}.name;
  
  [record, sc] = obj.postData('register-file', D);
catch ex
  warning(ex.identifier, '%s', ex.message)
end
obj.BaseURL = 'https://alyx-dev.cortexlab.net';
end