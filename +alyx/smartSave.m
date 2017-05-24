function smartSave(dataRepository, localFilePath, FileTag, sessionUUID, alyxInstance)

%Create alyx login instance if not already supplied
if isempty(alyxInstance)
    alyxInstance = alyx.loginWindow();
    if isempty(alyxInstance) % login failed or cancelled
        error('login failed');
    end
end

%Submit the dataRepository name (e.g. 'zserver') and FileTag (e.g. 'Block') to Alyx. 
%Receive the appropriate remote storage location for the local file.
warning('TODO');

%Copy localFile to the remotePath
try
    save(remoteFilePath, localFilePath);
catch
    error('Failed to save file to remote location');
end



%Now register the file to Alyx as a FileRecord
alyx.registerFile(sessionUUID,FileTag,remoteFilePath,alyxInstance)

end