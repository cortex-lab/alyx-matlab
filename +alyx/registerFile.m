function [dataset,filerecord] = registerFile(subject,sessionURL,datasetType,fullPath,repository,alyxInstance)
%[dataset,filerecord] = registerFile(subject,sessionURL,datasetType,fullPath,repository,alyxInstance)
% Registers a file to Alyx. This works first by creating a dataset (a record of the dataset type, creation date, md5 hash), and
% then a filerecord (a record of the relative path of one instance of the
% file in the repository). The dataset is associated with a session, which
% can be provided or inferred from the creation date.
% Inputs:
% -subject: 'Nyx', 'PC001', etc
% -sessionURL: Alyx URL for the session. If empty then we search for one
%   corresponding to the creation date of the supplied file. If that doesn't
%   exist, then one is created
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

if isempty(sessionURL)
    %Find session for that subject & date
    sessions = alyx.getData(alyxInstance, ['sessions?subject=' subject]);
    if isempty(sessions) || ~strcmp(created_time(1:10) , sessions{end}.start_time(1:10))
        warning(['Session not found for ' subject ' on ' created_time(1:10) '. Creating one now...']);
        
        d = struct;
        d.subject = subject;
        d.procedures = {'Behavior training/tasks'};
        d.narrative = 'auto-generated session';
        d.start_time = created_time;
        session = alyx.postData(alyxInstance, 'sessions', d);
        
        %     error('Session not found');
    else
        session = sessions{end};
        disp(['Session automatically found for ' subject ' on ' session.start_time(1:10) '.']);
    end
    sessionURL = session.url;
end

%Get root directory mask of the repository
datarepository = alyx.getData(alyxInstance, ['data-repository?name=' repository]);
if startsWith(fullPath,datarepository{1}.path)
    relPath = strrep(fullPath,datarepository{1}.path,'');
else
    error('Filepath does not contain the repository parent folder');
end



%Create dataset on Alyx, get the UUID for that dataset
d=struct;
d.created_by = alyxInstance.username;
d.dataset_type = datasetType;
d.session = sessionURL;
d.created_date = created_time;

try
    if ~isdir(fullPath)
        d.md5 = mMD5(fullPath);
    end
catch
    warning('Failed to compute file md5, please download mMD5.c and compile');
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