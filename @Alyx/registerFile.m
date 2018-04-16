function [datasets, filerecord] = registerFile(obj, filePath)
%REGISTERFILE Registers filepath(s) to Alyx. The file being registered should already be on the target server.
%   The repository being registered to will be automatically determined
%   from the filePath. Registration work first by creating a dataset (a
%   record of the dataset type, creation date), and then a filerecord (a
%   record of the relative path within the repository). The dataset is
%   associated with a session and a subject, which is inferred from the
%   path provided. 
%
%   The input filePath must be a full path to a directory or file, or a
%   cell array thereof.  For any directory paths provided, registerFile
%   attempts to register all files contained.  All file paths must include
%   an extension (if exists).  In order to be registered all files must
%   have an associated dataset type on Alyx.
%
%   All paths must conform to the following structure:
%   <dns>\<subject>\<yyyy-mm-dd>\<seq>\ where <dns> matches a valid data
%   repository domain name server entry on Alyx.
%
%   Examples:
%     datasets = obj.registerFile({...
%       '\\zubjects.cortexlab.net\Subjects\ALK055\2017-07-17\1\2017-07-17_1_ALK055_Block.mat',...
%       '\\zubjects.cortexlab.net\Subjects\ALK055\2017-07-17\2'});
%
%   NB: The returned datasets may not be in the same order as the filePaths
%   list provided.
%
%   TODO: Perhaps we should be able to register non-existent files?  I.e.
%   those that are not yet on the target server.
%   TODO: Validation based on regexp of dat.paths?
%
% See also ALYX, GETDATA, POSTDATA, HTTP.JSONGET
%
% Part of Alyx

% 2017 PZH created
% 2018 MW updated

%%INPUT VALIDATION
filePath = ensureCell(filePath);

% Validate files/directories exist
exists = cellfun(@(p) exist(p,'file') || exist(p,'dir'), filePath);
if any(~exists)
  warning('Alyx:registerFile:InvalidPath',...
    'One or more files/directories not found')
  filePath = filePath(exists);
end

% Validate file types FIXME: Use filename_pattern field instead of name
[~, ~, ext] = cellfun(@fileparts, filePath, 'uni', 0);
dataFormats = arrayfun(@(f)['.' f.name], obj.getData('data-formats'), 'uni', 0);
valid = cellfun(@(e)any(strcmp(dataFormats,e))||isempty(e), ext);
if any(~valid)
  warning('Alyx:registerFile:InvalidFileType',...
    'File extention(s) ''%s'' not found on Alyx', strjoin(unique(ext(~valid)),''', '''))
  filePath = filePath(valid);
end

% TODO: Should non-existant files be registered?
% assert( exist(filePaths,'file') || exist(filePaths,'dir'), 'Path %s does not exist', filePaths);
% assert( ~isdir(filePaths), 'filePath supplied must not be a folder');

% Log in, if required
if obj.IsLoggedIn == false; obj = obj.login; end

% Validate dataFormat supplied
% Remove leading slashes and replace back-slashes with forward ones
% filePaths = cellfun(@(s)strip(s,'\'), filePaths, 'uni', 0);
% filePaths = cellfun(@(s)strrep(s,'\','/'), filePaths, 'uni', 0);

%%Now some preparations
%Get datarepositories and their base paths
repositories = obj.getData('data-repository');
repo_paths = {repositories.dns};
assert(~all(cellfun('isempty',repo_paths)),...
  'Alyx:registerFile:EmptyDNSField',...
  'No valid DNS returned by database.')

%Identify which repository the filePath is in
which_repo = cellfun( @(rp) startsWith(filePath, ['\\' rp]), repo_paths, 'uni', 0);
which_repo = cell2mat(which_repo');
assert(all(sum(which_repo) > 0), 'Alyx:registerFile:InvalidRepoPath',...
  'Input filePath\n%s\ndoes not contain the repository path(s)\n',...
  strjoin(filePath(sum(which_repo) == 0), '\n'))

%Define the relative path of the file within the repo
% dnsId = regexp(filePath, ['(?<=' repo_paths{which_repo} '.*)\\?'], 'once')+1;
% relativePath = filePaths(dnsId:end);

% Remove redundant paths, i.e. those that point to specific files if a path
% to the same directory was also provided
filePath = unique(filePath);
dirs = cellfun(@isfolder, filePath);
dirPaths = filePath(dirs);
dirPaths(~endsWith(dirPaths, '\')) = strcat(dirPaths(~endsWith(dirPaths, '\')), '\');
filePath = filePath(~dirs);
filePath = filePath(~startsWith(filePath, dirPaths));

% Split filepaths into path and filenames
[filePath, filenames, ext] = cellfun(@fileparts, filePath, 'uni', 0);
filenames = strcat(filenames, ext);
[filePath,~,ic] = unique(filePath);
% Initialize datasets array
datasets = cell(1, sum([numel(dirPaths) numel(filePath)]));

% obj.BaseURL = 'https://alyx-dev.cortexlab.net';
% Register directories
D = struct('created_by', obj.User);
for i = 1:length(dirPaths)
  idx = which_repo(:,dirs);
  D.dns = repo_paths{idx(:,i)};
  D.path = strrep(dirPaths{i}, ['\\' D.dns '\Subjects\'], '');
  [record, statusCode] = obj.postData('register-file', D);
  assert(statusCode(end)==201, 'Failed to submit filerecord to Alyx');
  datasets{i} = record(end);
end

% Register files
for j = 1:length(filePath)
%   [relativePath, filename, ext] = fileparts(relativePath);
  idx = which_repo(:,~dirs);
  D.dns = repo_paths{idx(:,j)};
  D.path = [strrep(filePath{j}, ['\\' D.dns '\Subjects\'], '') '\'];
  D.filenames = filenames(ic==j);
  [record, statusCode] = obj.postData('register-file', D);
  assert(statusCode(end)==201, 'Failed to submit filerecord to Alyx');
  datasets{j+i} = record(end);
end

datasets = catStructs(datasets);
% try
%   d.md5 = mMD5(filePaths);
% catch
%   warning('Failed to compute MD5, using NULL');
% end
% 
% if ~isempty(parentDatasetURL)
%   d.parent_dataset = parentDatasetURL;
% end
% 
% [datasetReturnData, statusCode] = obj.postData('datasets', d);
% assert(statusCode(end)==201, 'Failed to submit dataset to Alyx')
%   
% d = struct('dataset', datasetReturnData(end).url,...
%   'data_repository', repositories{which_repo}.name,...
%   'relative_path', relativePath);

% [fileRecordReturnData, statusCode] = obj.postData('files', d);
% assert(statusCode(end)==201, 'Failed to submit filerecord to Alyx')
% 
% dataset = datasetReturnData(end);
% filerecord = fileRecordReturnData(end);

%% Alyx-dev test
% return
% try %#ok<UNRCH>
%   if ~contains(dataFormatName, '.npy')
%     obj.BaseURL = 'https://alyx-dev.cortexlab.net';
%     [relativePath, filename, ext] = fileparts(relativePath);
%     subject = regexpi(relativePath, '(?<=Subjects\\)[A-Z_0-9]+', 'match');
%     D.subject = subject{1};
%     D.dirname = relativePath;
%     D.filenames = {[filename, ext]};
%     D.exists_in = repositories{which_repo}.name;
%     [record, sc] = obj.postData('register-file', D);
%   end
% catch ex
%   warning(ex.identifier, '%s', ex.message)
% end
% obj.BaseURL = 'https://alyx.cortexlab.net';
end