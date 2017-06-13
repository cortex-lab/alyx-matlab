function registerFile(sessionUUID,DatasetType,fullPath,repository,alyxInstance)
%{
    Registers data files/folders (associated with a session) on Alyx
    Paths must use backslashes
%}

if contains(fullPath,'/')
    error('Use backslashes in path');
end

%Create alyx login instance if not already supplied
if isempty(alyxInstance)
    alyxInstance = alyx.loginWindow();
    if isempty(alyxInstance) % login failed or cancelled
        error('login failed');
    end
end

%Get root directory mask of the repository
ss = alyx.getData(alyxInstance, ['data-repository?name=' repository]);
if startsWith(fullPath,ss{1}.path)
    relPath = strrep(fullPath,ss{1}.path,'');
else
    error('Unclear which paths to use, please check');
end

%Check if session exists
if ~contains(sessionUUID,'NULL')
    warning('Session cannot be NULL, please specify');
    keyboard;
    ss = alyx.getData(alyxInstance, ['sessions?id=' sessionUUID]);
    if isempty(ss)
        error(['Session ' sessionUUID ' does not exist']);
    end
end

%Create dataset on Alyx, get the UUID for that dataset
d=struct;
d.created_by = alyxInstance.username;
d.dataset_type = DatasetType;
d.session = ss{1}.url;

info = dir(fullPath);
d.created_date = datestr(datenum(info.date),31);

d.md5 = [];
try
    if ~isdir(fullPath)
        d.md5 = mMD5(fullPath);
    end
catch
    warning('Failed to compute file md5, please download mMD5.c and compile');
end

try
    wa = alyx.postData(alyxInstance, 'datasets', d);
catch
    error('posting dataset failed');
end


%Create filerecord, using the dataset just created
d = struct;
d.dataset = wa.url;
d.data_repository = repository;
d.relative_path = relPath;

try
    wa = alyx.postData(alyxInstance, 'files', d);
catch
    error('posting filerecord failed');
end

end