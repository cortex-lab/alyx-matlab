function fullPath = getFile(obj, datasetURL)
%GETFILE Recovers the full filepath of a file on the repository, given the datasetURL
%	This function is SUPER inefficient because it has to load all
%	filerecords from the database, and then search for the specific
%	filerecord whose parent dataset matches the one supplied as input.
%
%   datasetURL: URL of a dataset on Alyx
%
% See also ALYX, GETDATA
%
% Part of Alyx
% TODO: Create endpoint so this function is no longer inefficient?
% 2017 PZH created


% Get all file records
filerecords = obj.getData('files');

% Extract the datasets which are parent to the filerecords
datasets = cellfun(@(fr) fr.dataset, filerecords, 'uni', 0);

% Find whichever filerecord has input datasetURL as its parent
idx = contains(datasets, datasetURL);

if any(idx)
  fr = filerecords{idx};
  relPath = fr.relative_path; % Get relative path of file
  
  repo = obj.getData('data-repository'); % Get absolute path of repository
  fullPath = [repo{1}.path relPath]; % Recover the full path of the file on the repository
else
  error('No filerecords with inputted datasetURL as its parent');
end

end

