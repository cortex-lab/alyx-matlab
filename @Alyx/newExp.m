function [expRef, expSeq, url] = newExp(obj, subject, expDate, expParams)
%NEWEXP Create a new unique experiment in the database
%   [ref, seq] = NEWEXP(subject, expDate, expParams)
%   Create a new experiment by creating the relevant folder tree in the
%   local and main data repositories in the following format:
%
%   subject/
%          |_ YYYY-MM-DD/
%                       |_ expSeq/
%
%   If experiment parameters are passed into the function, they are saved
%   here, as a mat and in JSON (if possible).  If a base session for the
%   experiment date is not found, one is created in the Alyx database. A
%   corresponding subsession is also created and the parameters file is
%   registered with the sub-session.
%
%   See also ALYX, DAT.PATHS
%
% Part of Alyx

% 2013-03 CB created
% 2018-02 MW added to Alyx

%%% Validate the input, create the new expRef and create any nessessary
%%% experiment folders on the respository locations
if nargin < 3
  % use today by default
  expDate = now;
end

if nargin < 4
  % default parameters is empty variable
  expParams = [];
end

if ischar(expDate)
  % if the passed expDate is a string, parse it into a datenum
  expDate = datenum(expDate, 'yyyy-mm-dd');
end

% check the subject exists in the database
exists = any(strcmp(dat.listSubjects, subject));
assert(exists, sprintf('"%" does not exist', subject));

% retrieve list of experiments for subject
[~, dateList, seqList] = dat.listExps(subject);

% filter the list by expdate
filterIdx = dateList == floor(expDate);

% find the next sequence number
expSeq = max(seqList(filterIdx)) + 1;
if isempty(expSeq)
  % if none today, max will have returned [], so override this to 1
  expSeq = 1;
end

% Main repository is the reference location for which experiments exist
[expPath, expRef] = dat.expPath(subject, floor(expDate), expSeq, 'main');
% ensure nothing went wrong in making a "unique" ref and path to hold
assert(~any(file.exists(expPath)), ...
  sprintf('Something went wrong as experiment folders already exist for "%s".', expRef));

% now make the folder(s) to hold the new experiment
assert(all(cellfun(@(p) mkdir(p), expPath)), 'Creating experiment directories failed');

%%% If the parameters had an experiment definition function, save a copy in
%%% the experiment's folder and register the file to Alyx
expVersion = [];
if isfield(expParams, 'defFunction')
  assert(file.exists(expParams.defFunction),...
    'Experiment definition function does not exist: %s', expParams.defFunction);
  assert(all(cellfun(@(p)copyfile(expParams.defFunction, p),...
    dat.expFilePath(expRef, 'expDefFun'))),...
    'Copying definition function to experiment folders failed');
  % Register the experiment definition file
  if ~strcmp(subject,'default') && ~(obj.Headless && ~obj.IsLoggedIn)
    try
      obj.registerFile(dat.expFilePath(expRef, 'expDefFun', 'master'));
    catch ex
      warning(ex.identifier, 'Registration of experiment definition failed: %s', ex.message)
    end
  end
  % Generate a version tag for the defFunction
  [~, expDef] = fileparts(expParams.defFunction);
  modDate = datetime(getOr(dir(expParams.defFunction), 'date'));
  ver = datestr(dateshift(modDate, 'start', 'minute', 'nearest'), 'yy.mm.dd.HH:MM');
  expVersion = [expDef '_' ver];
elseif isfield(expParams, 'type')
  % Generate version tag for old experiment types
  if strcmp(type, 'ChoiceWorld')
    modDate = datetime(getOr(dir(which('exp.ChoiceWorld')), 'date'));
    ver = datestr(dateshift(modDate, 'start', 'minute', 'nearest'), 'yy.mm.dd.HH:MM');
    expVersion = ['ChoiceWorld_' ver];
  end
end

%%% Here we create a new base session on Alyx if it doesn't already exist
%%% for this subject today.  Then we create a new subsession and save the
%%% URL in the Alyx object
url = []; % Clear any previous subsession URL
if ~strcmp(subject, 'default') && ~(obj.Headless && ~obj.IsLoggedIn) % Ignore fake subject
  % logged in, find or create BASE session
  expDate = obj.datestr(expDate); % date in Alyx format
  % Ensure user is logged in
  if ~obj.IsLoggedIn; obj = obj.login; end
    % Get list of base sessions
    [sessions, statusCode] = obj.getData(['sessions?type=Base&subject=' subject]);
    
    %If the date of this latest base session is not the same date as
    %today, then create a new base session for today
    if statusCode ~= 000 && (isempty(sessions) || ~strcmp(sessions(end).start_time(1:10), expDate(1:10)))
      d = struct;
      d.subject = subject;
      d.procedures = {'Behavior training/tasks'};
      d.narrative = 'auto-generated session';
      d.start_time = expDate;
      d.type = 'Base';
      d.users = {obj.User};
      
      base_submit = obj.postData('sessions', d);
      assert(isfield(base_submit,'subject'),...
        'Submitted base session did not return appropriate values');
      
      %Now retrieve the sessions again
      sessions = obj.getData(['sessions?type=Base&subject=' subject]);
    elseif statusCode == 000
      % Failed to reach Alyx; making headless.  NB: Headless only within
      % scope of this method
      obj.Headless = true;
      sessions = struct('url', []); % FIXME: Post may fail
    end
    latest_base = sessions(end);
    
    %Now create a new SUBSESSION, using the same experiment number
    d = struct;
    d.subject = subject;
    d.procedures = {'Behavior training/tasks'};
    d.narrative = 'auto-generated session';
    d.start_time = expDate;
    if ~isempty(expVersion); d.taskProtocol = expVersion; end
    d.type = 'Experiment';
    d.parent_session = latest_base.url;
    d.number = expSeq;
    d.users = {obj.User};
    
    try
      [subsession, statusCode] = obj.postData('sessions', d);
      url = subsession.url;
    catch ex
      if (isinteger(statusCode) && statusCode == 503) || obj.Headless % Unable to connect, or user is supressing errors
        warning(ex.identifier, 'Failed to create subsession file: %s.', ex.message)
      else % Probably fatal user error
        rethrow(ex)
      end
    end
end

%%% Now save the experiment parameters variable both locally and in the
%%% 'master' location
%%%TODO Make expFilePath an Alyx query?
superSave(dat.expFilePath(expRef, 'parameters'), struct('parameters', expParams));

%%% Try to save a copy of the expParams as a JSON file, unpon failing that,
%%% save as a mat file instead.  Register the parameters to Alyx
try 
  % Generate JSON path and save
  jsonPath = fullfile(fileparts(dat.expFilePath(expRef, 'parameters', 'master')),...
      [expRef, '_parameters.json']);
  fid = fopen(jsonPath, 'w'); fprintf(fid, '%s', obj2json(expParams)); fclose(fid);
  % Register our JSON parameter set to Alyx
  if ~strcmp(subject,'default') && ~(obj.Headless && ~obj.IsLoggedIn)
    obj.registerFile(jsonPath);
  end
catch ex
  warning(ex.identifier, 'Failed to save paramters as JSON: %s', ex.message)
end

% If user not logged in and has suppressed prompts, print warning
if ~strcmp(subject,'default') && (obj.Headless && ~obj.IsLoggedIn)
  warning('Alyx:HeadlessLoginFail', 'Failed to register files; must be logged in');
end
end