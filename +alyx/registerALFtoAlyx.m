function registerALFtoAlyx(alyxInstance)
%This function will parse through an ALF directory, and register the
%containing data hierarchy to alyx

alfDir = '\\zserver.cortexlab.net\Data\Subjects\Cori\2016-12-18\alf';
sessionURL = 'https://alyx-dev.cortexlab.net/sessions/5e15d67b-106e-4314-bd07-a7870a96cf0b';

warning('Only handles files which have been defined in the database');
warning('Dependency: dirPlus.m');

%% INPUT VALIDATION
%Validate alfDir path
assert( ~contains(alfDir,'/'), 'Do not use forward slashes in the path');
assert( exist(alfDir,'dir') == 7 , 'alfDir %s does not exist', alfDir);

%Validate alyxInstance, creating one if not supplied
if isempty(alyxInstance); alyxInstance = alyx.loginWindow(); end
assert(isfield(alyxInstance,'token'), 'Supplied alyxInstance is improper');

%Validate sessionURL supplied
[status,body] = http.jsonGet(sessionURL, 'Authorization', ['Token ' alyxInstance.token]);
assert(status==200,'SessionURL Invalid');

%% Validate that the files within alfDir match a datasetType.
%1) Get all datasetTypes from the database, and list the alf_filenames
datasetTypes = alyx.getData(alyxInstance,'dataset-types');
datasetTypes = [datasetTypes{:}];
datasetTypes_filemasks = {datasetTypes.alf_filename};
datasetTypes_filemasks(cellfun(@isempty,datasetTypes_filemasks)) = {''}; %Ensures all entries are character arrays

%2) Get all the files contained within the alfDir, which match a
%datasetType in the Alyx database
function v = validateFcn(fileObj)
    match = regexp(fileObj.name, regexptranslate('wildcard',datasetTypes_filemasks));
    v = ~isempty([match{:}]);
end
alfFiles = dirPlus(alfDir,'ValidateFileFcn',@validateFcn,'Struct',true);
assert( ~isempty(alfFiles), 'No files within %s matched a datasetType', alfDir);

%% Define a hierarchy of alfFiles based on the ALF naming scheme: parent.child.*
alfFileParts = cellfun(@(name) strsplit(name,'.'), {alfFiles.name}, 'uni', 0);
alfFileParts = cat(1,alfFileParts{:});

%Create parent datasets, which contain no filerecords themselves
[parentTypes, ~, parentID] = unique(alfFileParts(:,1));
parentURLs = cell(size(parentTypes));
fprintf('Creating parent datasets... ');
for parent = 1:length(parentTypes)
    d = struct('created_by',alyxInstance.username,...
               'dataset_type', parentTypes{parent},...
               'session',sessionURL,...
               'data_format','notData');
    w = alyx.postData(alyxInstance,'datasets',d);
    parentURLs{parent} = w.url;
end

%Now go through each file, creating a dataset and filerecord for that file
for file = 1:length(alfFiles)
    fullPath = fullfile(alfFiles(file).folder,alfFiles(file).name);
    fileFormat = alfFileParts{file,3};
    parentDataset = parentURLs{parentID(file)};

    matchIdx = regexp(alfFiles(file).name, regexptranslate('wildcard',datasetTypes_filemasks));
    matchIdx = find(~cellfun(@isempty, matchIdx));
    assert(numel(matchIdx)==1, 'Insufficient/Too many matches of datasetType for file %s', alfFiles(file).name);
    datasetType = datasetTypes(matchIdx).name;
    
    alyx.registerFile2(fullPath, fileFormat, sessionURL, datasetType, parentDataset, alyxInstance);
    
    fprintf('Registered file %s as datasetType %s\n',alfFiles(file).name, datasetType);
end


fprintf('All done!\n');
end