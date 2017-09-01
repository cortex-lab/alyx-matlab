function [dataset,filerecord] = registerFile(subject,subsessionURL,datasetType,fullPath,repository,alyxInstance)
%[dataset,filerecord] = registerFile(subject,subsessionURL,datasetType,fullPath,repository,alyxInstance)
% Registers a file to Alyx. This works first by creating a dataset (a record of the dataset type, creation date, md5 hash), and
% then a filerecord (a record of the relative path of one instance of the
% file in the repository). The dataset is associated with a subsession, which
% can be provided or inferred from the creation date. If the subsession URL
% is not provided, the code searches for sessions which have the TYPE field
% as 'Experiment', therefore if you don't provide a URL, your subsessions must include this TYPE field entry. 
% Inputs:
% -subject: 'Nyx', 'PC001', etc
% -subsessionURL: Alyx URL for the subsession. If empty then we search the
% latest one for the current date, errors if not found.
% -datasetType: Block, Timeline, Parameters
% -fullPath: the full path of the file on the server
%   (e.g. '\\zserver.cortexlab.net\Data\...\blabla_Timeline.mat')
% -repository: name of the remote repository the data is stored on (e.g.
%   'zserver');
% -AlyxInstance: An alyx instance object, created from alyx.loginWindow().
%   If empty, then creates one.

   

if contains(fullPath,'/')
    error('Use backslashes in path');
end

info = dir(fullPath);
created_time = datestr(info.datenum,31);

%Create alyx login instance if not already supplied
if isempty(alyxInstance)
    alyxInstance = alyx.loginWindow();
    if isempty(alyxInstance) % login failed or cancelled
        error('login failed');
    end
end

if isempty(subsessionURL)
    %If no subsession provided, then search for the latest one for the same
    %file creation date 
    subsessions = alyx.getData(alyxInstance, ['sessions?type=Experiment&subject=' subject]);
    if isempty(subsessions)
        error(['No subsessions found for subject' subject]);
    end
    
    latest_subsession = subsessions{end};
    if ~strcmp(latest_subsession.start_time(1:10), created_time(1:10))
        error('Latest subsession found in Alyx has a different creation date to the file being registered');
    end
    
    subsessionURL = latest_subsession.url;
end

%Get root directory mask of the repository
datarepository = alyx.getData(alyxInstance, ['data-repository?name=' repository]);
if isempty(datarepository)
    error(['Data repository ' repository ' not found']);
end

if startsWith(fullPath,datarepository{1}.path)
    relPath = strrep(fullPath,datarepository{1}.path,'');
else
    error(['File path does not contain the repository path signature: ' datarepository{1}.path]);
end

%Create dataset on Alyx, get the UUID for that dataset
d=struct;
d.created_by = alyxInstance.username;
d.dataset_type = datasetType;
d.session = subsessionURL;
d.created_date = created_time;

try
    if ~isdir(fullPath)
        d.md5 = mMD5(fullPath);
        
        [~,name,extension] = fileparts(fullPath);
        d.name = [name extension];
    else
        d.name = 'DIR';
    end
catch
    warning('Failed to compute file md5, please download mMD5.c and compile -> <a href="http://uk.mathworks.com/matlabcentral/fileexchange/7919-md5-in-matlab">http://uk.mathworks.com/matlabcentral/fileexchange/7919-md5-in-matlab</a>' );
end

try
    dataset = alyx.postData(alyxInstance, 'datasets', d);
catch
    error('Posting dataset failed');
end


%Create filerecord, using the dataset just created
d = struct;
d.dataset = dataset.url;
d.data_repository = repository;
d.relative_path = relPath;

try
    filerecord = alyx.postData(alyxInstance, 'files', d);
catch
    error('posting filerecord failed');
end

end