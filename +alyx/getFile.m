function fullPath = getFile(datasetURL, alyxInstance)
%fullPath = getFile(datasetURL, alyxInstance)
%This function recovers the full filepath of a file on the repository,
%given the datasetURL. This function is SUPER inefficient because it has to
%load all filerecords from the database, and then search for the specific
%filerecord whose parent dataset matches the one supplied as input. 
%-datasetURL: url of dataset on alyx
%-AlyxInstance: instance of the alyx object, obtained from alyx.loginWindow

%Get all file records
filerecords = alyx.getData(alyxInstance, 'files');

%Extract the datasets which are parent to the filerecords
datasets = cellfun(@(fr) fr.dataset, filerecords, 'uni', 0);

%Find whichever filerecord has input datasetURL as its parent
idx = contains(datasets, datasetURL);

if any(idx)
    fr = filerecords{idx};
    relPath = fr.relative_path; %Get relative path of file
    
    repo = alyx.getData(alyxInstance, 'data-repository'); %Get absolute path of repository
    fullPath = [repo{1}.path relPath]; %Recover the full path of the file on the repository
else
    error('No filerecords with inputted datasetURL as its parent');
end

end

