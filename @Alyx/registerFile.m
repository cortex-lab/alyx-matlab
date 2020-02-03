function [datasets, filerecords] = registerFile(obj, filePath, varargin)
%REGISTERFILE Registers filepath(s) to Alyx
%   [DATASETS, FILERECORDS] = REGISTERFILE(OBJ, FILEPATH, VERSION, HASH)
%   The repository being registered to will be automatically determined
%   from the filePath. Registration work first by creating a dataset (a
%   record of the dataset type, creation date), and then a filerecord (a
%   record of the relative path within the repository). The dataset is
%   associated with a session and a subject, which is inferred from the
%   path provided.  The file being registered should already be on the
%   target server.
%
%   All paths must conform to the following structure:
%   <dns>\<subject>\<yyyy-mm-dd>\<seq>\ where <dns> matches a valid data
%   repository domain name server entry on Alyx.
%
%   Inputs:
%     filePath (char|cellstr): A full path to a directory or file, or a
%       cell array thereof.  For any directory paths provided, registerFile
%       attempts to register all files contained.  All file paths must
%       include an extension (if exists).  In order to be registered all
%       files must have an associated dataset type on Alyx.
%     version (char|cellstr): The version of the algorithm used to
%       generate the files being registered.  If more than one provided,
%       must be the same number of elements as filePath.  Optional.
%     hash (char|cellstr): A hash checksum of the files being registered.  
%       If provided, the filePath(s) cannot be a dir and must be the same
%       number of elements as filePath.
%
%   Examples:
%     datasets = obj.registerFile({...
%       '\\znas.cortexlab.net\Subjects\ALK055\2017-07-17\1\2017-07-17_1_ALK055_Block.mat',...
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
p = inputParser;
validator = @(x) ischar(x) || iscellstr(x); %#ok<ISCLSTR>
p.addRequired('filePath', validator)
p.addOptional('version', '', validator) 
p.addOptional('hash', '', validator)
p.parse(filePath, varargin{:});

filePath = ensureCell(filePath);
if size(filePath,1) < size(filePath,2)
  filePath = filePath';
end

% Validate parameter input sizes
[filePath, version, hash, singleArg] = ...
  tabulateArgs(filePath, p.Results.version, p.Results.hash);

% Validate files/directories exist
exists = cellfun(@(p) exist(p,'file') || exist(p,'dir'), filePath);
if any(~exists)
  warning('Alyx:registerFile:InvalidPath',...
    'One or more files/directories not found')
  filePath = filePath(exists);
end

% Remove redundant paths, i.e. those that point to specific files if a path
% to the same directory was also provided
dirs = cellfun(@(p)exist(p,'dir')~=0, filePath); % For 2017b and later, we can use @isfolder
filePath = [filePath(~dirs); cellflat(cellfun(@dirPlus, filePath(dirs), 'uni', 0))];
filePath = unique(filePath);
if any(dirs)
  assert(isempty(hash), 'Alyx:registerFile:HashForDirGiven', ...
    'Cannot register hash for a directory, please provide full paths to files instead')
end

% Get the DNS part of the file paths  FIXME: Generalize expression
hostname = cellflat(regexp(filePath,'.*(?:\\{2}|\/)(.[^\\|\/]*)', 'tokens'));

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
  repo_dns = rmEmpty({repositories.hostname});
  if isempty(repo_dns)
    warning('Alyx:registerFile:EmptyDNSField',...
    'No valid DNS returned by database data repositories.')
    return
  end
  
  % Identify which repository the filePath is in
  valid = cellfun(@(p)~isempty(p)&&any(strcmp(p,repo_dns)), hostname);
  if ~all(valid)
    warning('Alyx:registerFile:InvalidRepoPath',...
      ['The following file path(s) not valid repository path(s):\n%s\n',...
      'Check dns field of data repositories on Alyx'], strjoin(filePath(~valid), '\n'))
    filePath = filePath(valid);
    hostname = hostname(valid);
  end
  
  % Validate dataset format
  dataFormats(strcmp({dataFormats.name}, 'unknown')) = [];
  isValidFormat = @(p)any(cell2mat(regexp(p,...
    regexptranslate('wildcard', rmEmpty({dataFormats.file_extension})))));
  valid = cellfun(isValidFormat, filePath);
  if ~all(valid)
    [~,~,ext] = cellfun(@fileparts, filePath, 'uni', 0);
    warning('Alyx:registerFile:InvalidFileType',...
      'File extention(s) ''%s'' not found on Alyx', strjoin(unique(ext(~valid)),''', '''))
    filePath = filePath(valid);
    hostname = hostname(valid);
  end
  
  % Validate file name matching a dataset type
  datasetTypes(strcmp({datasetTypes.name}, 'unknown')) = [];
  isValidFileName = @(p)any(cell2mat(regexp(p,...
    regexptranslate('wildcard', rmEmpty({datasetTypes.filename_pattern})))));
  valid = cellfun(isValidFileName, filePath);
  if ~all(valid)
    warning('Alyx:registerFile:InvalidFileName',...
      'The following input file path(s) have invalid file name pattern(s):\n%s ',...
      strjoin(filePath(~valid), '\n'))
    filePath = filePath(valid);
    hostname = hostname(valid);
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
datasets = cell(1, numel(filePath));
filerecords = []; % Initialize in case unable to access server

if isempty(filePath)
  warning('Alyx:registerFile:NoValidPaths', 'No file paths were registered')
  return
end

% Regex pattern for the relative path
expr = ['\w+(\\|\/)\d{4}\-\d{2}\-\d{2}((?:(\\|\/))\d+)+(?=(\\|\/)\w+\.\w+)|',...
  '\w+(\\|\/)\d{4}\-\d{2}\-\d{2}((\\|\/)\w+)+'];
realtivePath = cellflat(regexp(filePath, expr, 'match'));

% Register files
D = struct('created_by', obj.User);
for i = 1:length(filePath)
  D.hostname = hostname{i};
  D.version = iff(singleArg, version, version{i});
  D.hash = iff(singleArg, hash, hash{i});
  D.path = realtivePath{i};
  D.filenames = filenames(ic==i);
  [record, statusCode] = obj.postData('register-file', D);
  if statusCode==000; continue; end % Cannot reach server
  assert(statusCode(end)==201, 'Failed to submit filerecord to Alyx');
  datasets{i} = record(end);
end

if statusCode~=000 % Cannot reach server
datasets = catStructs(datasets);
filerecords = [datasets(:).file_records];
end