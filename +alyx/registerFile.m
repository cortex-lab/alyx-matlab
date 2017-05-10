function registerFile(sessionUUID,tag,filepath,alyxInstance)
%{
    Registers data files/folders (associated with a session) on Alyx
    Paths must use backslashes
%}

if contains(filepath,'/')
    error('Use backslashes in path');
end

%Create alyx login instance if not already supplied
if isempty(alyxInstance)
    alyxInstance = alyx.loginWindow();
    if isempty(alyxInstance) % login failed or cancelled
        error('login failed');
    end
end

%Check if session exists
ss = alyx.getData(alyxInstance, ['sessions?id=' sessionUUID]);  
if isempty(ss)
    error(['Session ' sessionUUID ' does not exist']);
end

%Submit file record to Alyx, getting confirmation of submission
d = struct;
d.sessionUUID = uuid;
d.tag = tag;
d.filepath = filepath;

try
    wa = alyx.postData(alyxInstance, 'files-url', d);
catch
    fprintf(1, 'posting failed\n');
end

end