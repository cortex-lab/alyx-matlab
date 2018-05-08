classdef Alyx
  %ALYX An class for interating with the Alyx database
  %   Creates an object that allows the user to log in, GET, PUT and POST
  %   data to the Alyx database primarily via the REST API.  For a tutorial
  %   on how to use see the README and Examples files.
  % 
  %   All public methods such as POSTWATER, etc. should call the private
  %   methods that actually post data and set the token. 
  %
  %   Example:
  %     ai = Alyx();
  %     ai.login;
  %     subjects = ai.getData('subjects');
  %     ai.postWater('test', 0.25);
  %     ai.logout;
  %
  %   Dependencies: missing-http
  %
  %   See also EUI.ALYXPANEL
  %
  % Part of Alyx
  
  % 2017 -- created
  
  properties
    % URL to the Alyx database
    BaseURL char = 'https://alyx.cortexlab.net'
    % Set the local directory for saving queued Alyx commands, create if needed
    QueueDir char = 'C:\localAlyxQueue'
    % Set whether input dialogs should appear, e.g. login window
    Headless logical = false
    % A URL of the most-recent subsession created by newExp
    SessionURL
  end
  
  properties (SetAccess = private)
    % The username of whoever is logged in
    User
  end
  
  properties (Access = private)
    % The Alyx token acquired after loggin in
    Token
    % Options for reading and writing to database via http
    WebOptions = weboptions('MediaType','application/json','Timeout',10);
  end
  
  properties (Dependent)
    % A flag indicating whether the user is logged into the database
    IsLoggedIn = false
  end
  
  methods
    function obj = Alyx(user, token)
      %ALYX Class constructor
      if nargin
        obj.User = user;
        obj.Token = token;
      else
        obj = obj.login;
      end
    end
    
    function obj = logout(obj)
      %LOGOUT Delete token and user data from object
      % Unsets the User, Token and SessionURL attributes
      % Example:
      %   ai = Alyx;
      %   ai.login; % Get token, set user
      %   ai.logout; % Remove token, unset user
      % See also LOGIN
      obj.Token = [];
      obj.WebOptions.HeaderFields = []; % Remove token from header field
      obj.User = [];
    end
    
    function bool = get.IsLoggedIn(obj)
      bool = ~isempty(obj.User)&&~isempty(obj.Token);
    end
    
    function obj = set.QueueDir(obj, qDir)
      %SET.QUEUEDIR Ensure directory exists
      if ~exist(qDir, 'dir'); mkdir(qDir); end
      obj.QueueDir = qDir;
    end
  end
  
  methods
    % UI for retrieving a token from Alyx
    obj = login(obj, presetUsername)
    % Returns a complete Alyx Rest API endpoint URL
    fullEndpoint = makeEndpoint(obj, endpoint)
    % Return a specific Alyx/REST read-only endpoint
    [data, statusCode] = getData(obj, endpoint, varargin)
    % Post any new data to an Alyx/REST endpoint
    [data, statusCode] = postData(obj, endpoint, data, requestMethod)
    % Checks for and uploads queued data to Alyx
    [data, statusCode] = flushQueue(obj)
    % Recovers the full filepath of a file on the repository, given the datasetURL
    fullPath = getFile(obj, datasetURL)
    % Lists recorded subjects
    subjects = listSubjects(obj, stock, alive, sortByUser)
    % Returns the file path where you can find a specified file
    [fullpath, filename, fileID, records] = expFilePath(obj, varargin)
    % Returns experiment meta-data, given an experiment URL
    expMetaData = getExpMeta(obj, sessionURL)
    % Register a filepath to Alyx. The file being registered should already be on the target server.
    [dataset, filerecord] = registerFile(obj, filePath, dataFormatName, sessionURL, datasetTypeName, parentDatasetURL)
    % Register files contained within alfDir to Alyx
    registerALF(obj, alfDir, sessionURL)
    % Post a water value to a given subject in Alyx
    wa = postWater(obj, mouseName, amount, thisDate, isHydrogel)
    % Post a subject's weight to Alyx
    w = postWeight(obj, weight, subject)
    % Create a new unique experiment in the database
    [expRef, expSeq, url] = newExp(obj, subject, expDate, expParams)
    % Update an Alyx session or subject narrative
    narrative = updateNarrative(obj, subject, comments, endpoint)
    % Return the instance of Alyx as a struct
    s = saveobj(obj)
  end
  
  methods (Access = private)
    % Acquire an authentication token for Alyx
    [obj, statusCode] = getToken(obj, username, password)
    % Makes POST, PUT and PATCH requests to endpoint with a JSON request body
    [statusCode, responseBody] = jsonPost(obj, endpoint, jsonData, requestMethod)
    % Makes POST, PUT and PATCH requests to endpoint URL encoded web form
    [statusCode, responseBody] = httpPost(obj, endpoint, varargin)
  end
    
  methods (Static)
    % Returns a datenum in the Alyx format-spec for posting
    outStr = datestr(inDatenum)
    % Returns a MATLAB datenum given a date_time string provided by Alyx
    outDatenum = datenum(date_time)
    % Converts input to string for UDP message and back
    [ref, AlyxInstance] = parseAlyxInstance(varargin)
    % Load an Alyx object from a struct
    obj = loadobj(s)
  end
  
end