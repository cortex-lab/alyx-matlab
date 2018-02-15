function [fullpath, filename, fileID, records] = expFilePath(obj, varargin)
%EXPFILEPATH Full path for file pertaining to designated experiment
%   Returns the path(s) that a particular type of experiment file should be
%   located at for a specific experiment. NB: Unlike dat.expFilePath, this
%   CAN NOT be used to determine where a file should be saved to.  This
%   function only returns existing file records from Alyx.  There may be
%   files that exist but aren't on Alyx and likewise, may not exist but are
%   still on Alyx.
%
%   e.g. to get the paths for an experiments 2 photon TIFF movie:
%   ALYX.EXPFILEPATH('mouse1', datenum(2013, 01, 01), 1, 'block');
%
%   [full, filename] = expFilePath(ref, type[, user, reposlocation])
%   [full, filename] = expFilePath(subject, date, seq, type[, user, reposlocation])
%
%   
%   You specify:
%     - subject/ref: a string with the subject name or an experiment
%       reference
%     - date: a string in 'yyyy-mm-dd', 'yyyymmdd' or  'yyyy-mm-ddTHH:MM:SS'
%       format, or a datenum 
%     - seq: an integer number of the experiment you want
%     - type: a case-insensitive string specifying which file you want, e.g. 'Block'.  Must
%       be a valid dataset type on Alyx (see /dataset-types)
%     - user: optional string argument specifying the user who created the files 
%     - reposlocation: optional case-insensitive string argument specifying
%       the location of the files e.g. 'zubjects'.  Must be a valid data 
%       repository on Alyx (see /data-repository)
%
%   Outputs:
%     - fullpath: the full file paths of the files
%     - filename: the names of the files
%     - uuid: the Alyx ids of the files
%     - records: the complete records returned by Alyx
%
%   If more than one matching paths are found, output argument filePath
%   will be a cell array of strings, otherwise just a string.
%
%   TODO:
%     - Exists flag
%     - Replace functionality of dar.expFilePath?
%
% Part of Alyx

% 2018-02 MW created

% Validate input
assert(nargin > 2, 'Error: Not enough arguments supplied.')

parsed = regexp(varargin{1}, dat.expRefRegExp, 'tokens');
if isempty(parsed) % Subject, not ref
  subject = varargin{1};
  expDate = varargin{2};
  seq = varargin{3};
  type = varargin{4};
  varargin(1:4) = [];
else % Ref, not subject
  subject = parsed{1}{3};
  expDate = parsed{1}{1};
  seq = parsed{1}{2};
  type = varargin{2};
  varargin(1:2) = [];
end

% Check date
if ~ischar(expDate)||(ischar(expDate)&&length(expDate)==8)
  expDate = datestr(expDate, 'yyyy-mm-dd');
elseif ischar(expDate)&&length(expDate)==19
  expDate = datestr(expDate, 'yyyy-mm-ddTHH:MM:SS');
end

if length(varargin) > 1 % Repository location defined
 location = varargin{2};
 % Validate repository
 repos = catStructs(obj.getData('data-repository'));
 idx = strcmpi(location, {repos.name});
 assert(any(idx), 'Error: ''%s'' is an invalid data set type', location)
 location = repos(idx).name; % Ensures correct case
elseif ~isempty(varargin)
  user = varargin{1};
else
  location = [];
  user = '';
end

% Validate type
dataSets = catStructs(obj.getData('dataset-types'));
idx = strcmpi(type, {dataSets.name});
assert(any(idx), 'Error: ''%s'' is an invalid data set type', type)
type = dataSets(idx).name; % Ensures correct case

% Construct the endpoint
endpoint = sprintf('/datasets?subject=%s&date=%s&experiment_number=%s&dataset_type=%s&created_by=%s',...
  subject, expDate, num2str(seq), type, user);

% Get data
records = obj.getData(endpoint);
if ~isempty(records)
  data = catStructs(records);
  fileRecords = catStructs([data(:).file_records]);
end

if ~isempty(location)
  % Remove records in unwanted repo locations
  idx = contains({fileRecords.data_repository_path}, location);
  data = data(idx);
  fileRecords = fileRecords(idx);
end

fullpath = strcat({fileRecords.data_repository_path}, {fileRecords.relative_path});
filename = {data.name};
fileID = {fileRecords.id};

% If only one record was returned, don't return a cell array
if numel(fullpath)==1
  fullpath = fullpath{1};
  filename = filename{1};
  fileID = fileID{1};
end