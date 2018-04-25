function [datasets, filerecords] = registerFile(obj, filePath)
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
% See also ALYX, GETDATA, POSTDATA
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

% Remove redundant paths, i.e. those that point to specific files if a path
% to the same directory was also provided
filePath = unique(filePath);
dirs = cellfun(@(p)exist(p,'dir')~=0, filePath); % For 2017b and later, we can use @isfolder
dirPath = filePath(dirs);
dirPath(~endsWith(dirPath, '\')) = strcat(dirPath(~endsWith(dirPath, '\')), '\');
filePath = filePath(~dirs);
filePath = filePath(~startsWith(filePath, dirPath));

% Get the DNS part of the file paths
dns_dirs = cellflat(regexp(dirPath,'.*(?:\\{2}|\/)(.[^\\|\/]*)', 'tokens'));
dns_files = cellflat(regexp(filePath,'.*(?:\\{2}|\/)(.[^\\|\/]*)', 'tokens'));

% Retrieve information from Alyx for file validation
[dataFormats, statusCode(1)] = obj.getData('data-formats');
[datasetTypes, statusCode(2)] = obj.getData('dataset-types');
[repositories, statusCode(3)] = obj.getData('data-repository');

% When Alyx unreachable, i.e. server down or user is not
% logged in and object is headless, we can not validate posts
if any(statusCode==000)||(any(statusCode==403)&&obj.Headless)
  warning('Alyx:registerFile:UnableToValidate',...
    'Unable to validate paths, some posts may fail')
else %%% FURTHER VALIDATION %%%
  % Ensure there are DNS fields on the database
  repo_dns = rmEmpty({repositories.dns});
  if isempty(repo_dns)
    warning('Alyx:registerFile:EmptyDNSField',...
    'No valid DNS returned by database data repositories.')
    return
  end
  
  % Identify which repository the filePath is in
  valid_dirs = cellfun(@(p)any(strcmp(p,repo_dns)), dns_dirs);
  valid_files = cellfun(@(p)any(strcmp(p,repo_dns)), dns_files);
  if ~all(valid_dirs)||~all(valid_files)
    warning('Alyx:registerFile:InvalidRepoPath',...
      ['The following file path(s) not valid repository path(s):\n%s\n',...
      'Check dns field of data repositories on Alyx'],...
      strjoin([filePath(~valid_files), dirPath(~valid_dirs)], '\n'))
    filePath = filePath(valid_files);
    dns_files = dns_files(valid_files);
    dirPath = dirPath(valid_dirs);
    dns_dirs = dns_dirs(valid_dirs);
  end
  
  % Validate dataset format
  isValidFormat = @(p)any(cell2mat(regexp(p,...
    regexptranslate('wildcard', rmEmpty({dataFormats.filename_pattern})))));
  valid = cellfun(isValidFormat, filePath);
  if ~all(valid)
    [~,~,ext] = cellfun(@fileparts, filePath, 'uni', 0);
    warning('Alyx:registerFile:InvalidFileType',...
      'File extention(s) ''%s'' not found on Alyx', strjoin(unique(ext(~valid)),''', '''))
    filePath = filePath(valid);
    dns_files = dns_files(valid);
  end
  
  % Validate file name matching a dataset type
  isValidFileName = @(p)any(cell2mat(regexp(p,...
    regexptranslate('wildcard', rmEmpty({datasetTypes.filename_pattern})))));
  valid = cellfun(isValidFileName, filePath);
  if ~all(valid)
    warning('Alyx:registerFile:InvalidFileName',...
      'The following input file path(s) have invalid file name pattern(s):\n%s ',...
      strjoin(filePath(~valid), '\n'))
    filePath = filePath(valid);
    dns_files = dns_files(valid);
  end
end

% Validate dataFormat supplied
% Remove leading slashes and replace back-slashes with forward ones
% filePaths = cellfun(@(s)strip(s,'\'), filePaths, 'uni', 0);
% filePaths = cellfun(@(s)strrep(s,'\','/'), filePaths, 'uni', 0);

% Split filepaths into path and filenames
[filePath, filenames, ext] = cellfun(@fileparts, filePath, 'uni', 0);
filenames = strcat(filenames, ext);
[filePath,~,ic] = unique(filePath);
% Initialize datasets array
datasets = cell(1, sum([numel(dirPath) numel(filePath)]));
filerecords = []; % Initialize in case unable to access server

if isempty(filePath)&&isempty(dirPath)
  warning('Alyx:registerFile:NoValidPaths', 'No file paths were registered')
  return
end

% Regex pattern for the relative path
exp = ['\w+(\\|\/)\d{4}\-\d{2}\-\d{2}((?:(\\|\/))\d+)+(?=(\\|\/)\w+\.\w+)|',...
  '\w+(\\|\/)\d{4}\-\d{2}\-\d{2}((\\|\/)\w+)+'];
realtivePath = cellflat(regexp([dirPath; filePath], exp, 'match'));

% Register directories
D = struct('created_by', obj.User);
for i = 1:length(dirPath)
  D.dns = dns_dirs{i};
  D.path = realtivePath{i};
  [record, statusCode] = obj.postData('register-file', D);
  if statusCode==000; continue; end % Cannot reach server
  assert(statusCode(end)==201, 'Failed to submit filerecord to Alyx');
  datasets{i} = record(end);
end
if isempty(i); i = 0; end

% Register files
for j = 1:length(filePath)
  D.dns = dns_files{j};
  D.path = realtivePath{j+i};
  D.filenames = filenames(ic==j);
  [record, statusCode] = obj.postData('register-file', D);
  if statusCode==000; continue; end % Cannot reach server
  assert(statusCode(end)==201, 'Failed to submit filerecord to Alyx');
  datasets{j+i} = record(end);
end

datasets = catStructs(datasets);
if statusCode==000
% Cannot reach server
  return
end
filerecords = [datasets(:).file_records];
end