function updateSessions(varargin)
% ALYX.UPDATESESSIONS (Re-)Extract ALF Files for subject sessions
%   Extract any missing ALF files and register the files to Alyx.  If no
%   session exists for that day, a new sub-session is created.  If register
%   is true then the trial counts for that session are also posted to Alyx.
%
%   Inputs:
%     ai (optional): an Alyx object to use for registration.  If none is
%       provided and registration is true, a new instance is instantiated
%       and the user will be prompted to log in.
%     subject: a subject (char) are list of subjects (cell array) whose
%       data are to be extracted from block files into ALF files.
%     register: a logical indicating whether to register the newly
%       extracted files to Alyx.
%     
%   Examples:
%     Alyx.updateSessions('subject1', false) - extracts ALF files for
%     'subject1' without registering the files to Alyx
%     Alyx.updateSessions(ai, {'subject1', 'subject2'}) - extracts ALF
%     files for 'subject1' and 'subject2' and registers them to Alyx using
%     the 'ai' Alyx object
%     
%   TODO: Integrate old ChoiceWorld ALF extraction
%   TODO: Add exclude input to ignore particular experiments?

w = warning('off', 'MATLAB:toeplitz:DiagonalConflict');
if isa(varargin{1}, 'Alyx')
  ai = varargin{1};
  varargin(1) = [];
else
  ai = Alyx('','');
end

subjects = ensureCell(varargin{1});
if length(varargin) == 1
  register = true;
elseif isempty(varargin)
  error('UpdateSessions:InputArgs:NotEnoughArgs', ...
    'Subject or cell array of subjects required')
else
  register = varargin{2};
end

if register && ~ai.IsLoggedIn
  ai = ai.login;
end

% Check for wheel function
if isempty(which('myGaussWin')) || isempty(which('wheel.computeVelocity'))
  errordlg('Please ensure rigbox is fully updated and add wheelAnalysis folders to paths')
  return
end

if register
  notOnDB = ~ismember(subjects, ai.listSubjects(false, true, false));
  if any(notOnDB)
    h = warndlg(...
      sprintf(['The following mice were not found on the database: /n %s \n',...
      'These mice will not be processed'], strjoin(subjects(notOnDB), ', ')));
    uiwait(h)
    subjects = subjects(~notOnDB);
  end
end

for s = 1:length(subjects)
  subject = subjects{s};
  disp(['<strong>Processing ' subject '</strong>'])
  expRefs = dat.listExps(subject);
  expRefs = expRefs(cellfun(@(f)exist(f, 'file')~=0,...
    dat.expFilePath(expRefs, 'block', 'master')));
  if register
    sessions = ai.getData(['sessions?type=Experiment&subject=' subject]);
    if isempty(sessions)
      alyxExpRefs = [];
    else
      alyxExpRefs = cellfun(@(a,b,c)dat.constructExpRef(a,ai.datenum(b),c), ...
        {sessions.subject}, {sessions.start_time}, {sessions.number}, 'uni', 0);
      assert(length(unique(alyxExpRefs))==length(alyxExpRefs), ...
        'Alyx:UpdateSessions:MultipleSessions', 'Multiple identical sessions found');
    end
  end
  for b = 1:length(expRefs)
    disp(expRefs{b})
    block = dat.loadBlock(expRefs{b});
    try
      alf.block2ALF(block);
    catch ex
      warning(ex.identifier, '%s', ex.message)
    end
    if register
      try
        numCorrect = [];
        numTrials = [];
        if isfield(block, 'events')
          numTrials = length(block.events.endTrialValues);
          if isfield(block.events, 'feedbackValues')
            numCorrect = sum(block.events.feedbackValues == 1);
          end
        else
          numTrials = block.numCompletedTrials;
          if isfield(block, 'trial')&&isfield(block.trial, 'feedbackType')
            numCorrect = sum([block.trial.feedbackType] == 1);
          else
            numCorrect = 0;
          end
        end
      catch ex
        warning('UpdateSessions:TrialData:FailedToGetTrials', '%s', ex.message)
      end
              
      if ~any(strcmp(expRefs{b}, alyxExpRefs))
        % If session doesn't exist on Alyx, create it
        [~,~,expSeq] = dat.parseExpRef(expRefs{b});
        registerSession(subject, block.startDateTime, expSeq, ai, ...
          block.endDateTime, numTrials, numCorrect);
      else
        % If session exists but is missing trial data, patch the data
          sessionData = struct.empty;
          if ~isempty(numCorrect) && ...
              isempty(sessions(strcmp(expRefs{b}, alyxExpRefs)).n_correct_trials)
            sessionData(1).n_correct_trials = numCorrect;
          end
          if ~isempty(numTrials) && ...
              isempty(sessions(strcmp(expRefs{b}, alyxExpRefs)).n_trials)
            sessionData(1).n_trials = numTrials;
          end
          if ~isempty(sessionData)
            ai.postData(sessions(strcmp(expRefs{b}, alyxExpRefs)).url, sessionData, 'patch');
          end
      end
      
      % Check that all ALF files exist and have been registered to Alyx
      files = dir(dat.expPath(expRefs{b},'main', 'master'));
      filenames = {files(cellfun(@alf.isvalid, {files.name})).name};
      sessionFiles = [sessions(strcmp(expRefs{b}, alyxExpRefs)).data_dataset_session_related];
      sessionFiles = iff(isempty(sessionFiles), '', @(){sessionFiles.name});
      toRegister = filenames(~ismember(filenames,sessionFiles));
      if ~isempty(toRegister)
        ai.registerFile(fullfile(files(1).folder, toRegister));
      end
      
      % Update water
%       sessionDate = datestr(block.endDateTime, 'yyyy-mm-dd');
%       endpnt = sprintf('water-requirement/%s?start_date=%s&end_date=%s', subject, sessionDate, sessionDate);
%       wr = ai.getData(endpnt);
%       records = catStructs(wr.records, nan);
    end
    clear('BurgboxCache')
  end

end
warning(w)
end

function registerSession(subject, expDate, expSeq, ai, endDateTime, numTrials, numCorrect)
    expDate = ai.datestr(expDate); % date in Alyx format
    endDateTime = ai.datestr(endDateTime);
    
    %Now create a new SUBSESSION, using the same experiment number
    d = struct;
    d.subject = subject;
    d.procedures = {'Behavior training/tasks'};
    d.narrative = 'auto-generated session';
    d.start_time = expDate;
    d.end_time = endDateTime;
    d.type = 'Experiment';
    d.number = expSeq;
    d.users = {ai.User};
    if ~isempty(numTrials); d.n_trials = numTrials; end
    if ~isempty(numCorrect); d.n_correct_trials = numCorrect; end
    ai.postData('sessions', d);
%     if (isinteger(statusCode) && statusCode == 503) || ai.Headless % Unable to connect, or user is supressing errors
%       warning('NewALF:Register:Failed', 'Failed to create subsession file: %s.', ex.message)
%     end
end