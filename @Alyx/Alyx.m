classdef Alyx < handle & matlab.mixin.Copyable
  %ALYX
  %   TODO: Document!
  %
  % Dependencies: missing-http, JSONLab
  %
  % Part of Alyx
  
  % 2017 -- created
  
  properties
    Subjects
    % URL to the Alyx database
    BaseURL char = 'https://alyx.cortexlab.net'
    % Set the local directory for saving queued Alyx commands, create if needed
    QueueDir char = 'C:\localAlyxQueue'
  end
  
  properties (SetAccess = private)
    % The username of whoever is logged in
    User
    % A URL of the most-recent subsession created by newExp
    SessionURL
  end
  
  properties (Access = private)
    % The Alyx token acquired after loggin in
    Token
  end
  
  properties (Dependent)
    % A flag indicating whether the user is logged into the database
    IsLoggedIn = false
  end
  
  methods
    function obj = Alyx(user, token, session)
      %ALYX Class constructor
      if nargin
        obj.User = user;
        obj.Token = token;
        obj.SessionURL = session;
      end
    end
    
%     function delete(obj)
%       %DELETE Class destructor
%     end
    
    function logout(obj)
      %LOGOUT Delete token and user data from object
      obj.Token = [];
      obj.User = [];
      obj.SessionURL = [];
    end
    
    function bool = get.IsLoggedIn(obj)
      bool = ~isempty(obj.User)&&~isempty(obj.Token);
    end
    
    function set.QueueDir(obj, qDir)
      %SET.QUEUEDIR Ensure directory exists
      if ~exist(qDir, 'dir'); mkdir(qDir); end
      obj.QueueDir = qDir;
    end
  end
  
  methods
    % UI for retrieving a token from Alyx
    [alyxInstance, username] = login(obj, presetUsername)
    % Returns a complete Alyx Rest API endpoint URL
    fullEndpoint = makeEndpoint(obj, endpoint)
    % Return a specific Alyx/REST read-only endpoint
    [data, statusCode] = getData(obj, endpoint)
    % Recovers the full filepath of a file on the repository, given the datasetURL
    fullPath = getFile(obj, datasetURL)
    % Returns experiment meta-data, given an experiment URL
    expMetaData = getExpMeta(obj, expUrl)
    % Register a filepath to Alyx. The file being registered should already be on the target server.
    [dataset, filerecord] = registerFile(obj, filePath, dataFormatName, sessionURL, datasetTypeName, parentDatasetURL)
    % Register files contained within alfDir to Alyx
    registerALF(obj, alfDir, sessionURL)
    % Post a water value to a given subject in Alyx
    wa = postWater(obj, mouseName, amount, thisDate, isHydrogel)
    % Post a subject's weight to Alyx
    w = postWeight(obj, weight, subject)
    % Create a new unique experiment in the database
    [expRef, expSeq, url] = newExp(subject, expDate, expParams, AlyxInstance)
    % Update an Alyx session or subject narrative
    narrative = updateNarrative(obj, subject, comments, endpoint)
    % Converts input to string for UDP message and back
    [ref, AlyxInstance] = parseAlyxInstance(varargin)
    % TODO
    s = saveobj(obj)
  end
  
  methods (Access = private)
    % Acquire an authentication token for Alyx
    statusCode = getToken(obj, username, password)
    % Post any new data to an Alyx/REST endpoint
    [data, statusCode] = postData(obj, endpoint, data)
    % Put an updated data record to an Alyx/REST endpoint
    [data, statusCode] = putData(obj, endpoint, data)
    % Checks for and uploads queued data to Alyx
    [data, statusCode] = flushQueue(obj)
  end
  
  methods (Static)
    % Returns a datenum in the Alyx format-spec for posting
    outStr = datestr(inDatenum)
    % Returns a MATLAB datenum given a date_time string provided by Alyx
    outDatenum = datenum(date_time)
    % Returns the file path where you can find a specified file
    filePath = expFilePath(subject, queryDate, sessNum, dsetType, conn)
    % TODO
    obj = loadobj(s)
  end
  
end