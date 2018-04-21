%% Example dataset creation & file registration on Alyx
% The simplst way to interface with Alyx via MATLAB is through the RESTful
% interface.  The Alyx class (found in Rigbox/alyx-matlab/@Alyx) creates an
% instance of an Alyx object that can be passed around rigs and used to get
% and post data from/to the database.  NB: Alyx is actually a value class,
% not a handle one.  More on that later.
doc Alyx

%% Logging in/out
% To instantiate an instance of Alyx, call the constructor like so:
ai = Alyx; %#ok<*NASGU>

% When called with no arguments, a login window is automatically displayed.
% To instantiate the object without immediately logging in, call it with
% the first two arguments empty.  NB: The inputs are the Username and
% Token.
ai = Alyx('','');

% To log in use the login method.  Upon success, this sets the Token
% property with a token from Alyx.  To determine whether you're logged in,
% use the IsLoggedIn property. After logging in the object automatically
% flushes any posts in the queue (more later). NB: Alyx is not a handle
% class, so make sure you assign the output to itself.
ai.IsLoggedIn % false
ai = ai.login;

ai.IsLoggedIn % true
ai = ai.logout;

ai.IsLoggedIn % false

%% Using endpoints to GET data
% A list of availiable endpoints can be found at
% https://alyx.cortexlab.net/  Most of these endpoints already have methods
% associated with them.  For instance the listSubjects method returns a
% list of subjects from the subjects endpoint:
ai = ai.login;
subjects = ai.listSubjects();

% You can use the getData method to retrieve data directly from the
% specified endpoint.  For instance to retrieve session data:
sessions = ai.getData('sessions'); % NB: Don't run this line, it will be very slow!

% getData uses the makeEndpoint method to create the full URL using the
% BaseURL property.  To interact with the alyx-dev branch instead, either
% provide the full URL or change the BaseURL property accordingly.
ai.BaseURL = 'https://alyx-dev.cortexlab.net/';
sessions = ai.getData('sessions'); % NB: Don't run this line, it will be very slow!

% The data are return as a struct.  The second output argument is the
% server status code.  For a full list of status codes and their meanings:
doc matlab.net.http.StatusCode

% To use any URL queries, just add them the endpoint string in the standard
% URL format:
sessions = ai.getData('sessions?type=Base&subject=test');

% For more info:
doc webread

% The query options are set on the server side.  You can find which options
% are availible for each endpoint by vising the endpoint URL, but be warned
% it is slow to load as you are running a GET within the browser.  NB: Not
% all endpoints have a GET options, again see the DJANGO API page
% Example: https://alyx.cortexlab.net/sessions
% HTTP 200 OK % HTTP version
% Allow: GET, PUT, PATCH, DELETE, HEAD, OPTIONS % Methods allowed
% Content-Type: application/json % Post using Alyx.jsonPost
% Vary: Accept

%% Posting data
% POST requests (those that create new records on Alyx) can be made with
% the postData method.  Upon success postData returns the created record.
% For creating a new experiment, use the newExp method.  This is the same
% as the dat.newExp function, but with the addition of creating session
% records on Alyx.  
%
% Alyx.newExp first creates a base session if one doesn't exist.  This is a
% session corresponding to a particular day (the yyyy-mm-dd part of an
% experiment reference, see dat.parseExpRef).  On Alyx, base sessions have
% the type 'Base'. It then creates a new subsession.  Subsessions
% correspond to the experiment sequence number of an expRef.  On the
% database, these sessions are identified by the type field being
% 'Experiment'.  For example, you may have three subsessions related to a
% base session, meaning on that particular day, you ran three expeiments,
% perhaps training the mouse on a rig, then later doing RF mapping, then
% doing some imaging with behaviour.  Alyx supports further nesting of
% sessions, however Alyx.newExp currently doesn't support this.
%
% The newExp method returns the new subsession URL which may then be saved
% in SessionURL property of the object for further posts.  This URL is in
% itself an endpoint for ameding (with PUT) session information (or even
% creating a nested subsession).
[expRef, expSeq, url] = ai.newExp('test');
ai.SessionURL = url; % Now holds the current (most recent) subsession URL.

% Let's update the session narrative:
comments = 'This is a dummy session';
narrative = ai.updateNarrative(comments, ai.SessionURL);

% Let's create a nested subsession
d = struct;
d.subject = 'test';
d.procedures = {'Behavior training/tasks'};
d.narrative = 'sub-sub-session';
d.start_time = ai.datestr(now); % date in Alyx format
d.type = 'Experiment';
d.parent_session = ai.SessionURL;
d.number = 1;

[subsession, statusCode] = ai.postData('sessions', d) %#ok<*ASGLU,*NOPTS>

% With this method you can also make PUT and PATCH requests to amending a
% record.  NB: Only for those endpoints with these options availible.
% Let's update the session's end time:
d = struct('end_time', ai.datestr(now), 'subject', 'test'); % Subject is a required field
ai.postData(ai.SessionURL, d, 'put'); % Update the record

% The postData method uses the jsonPost method, which in turn uses the
% built in MATLAB function webwrite.  More info:
doc Alyx.jsonPost
doc webwrite

clear d subsession statusCode url comments expSeq
%% Datasets
% One of the purposes of Alyx is to make sharing data to a wider group
% simple and accessible.  In order to do this effectively there are a few
% things imposed on the user in terms of how data and meta-data are stored:

% 1. Files must be stored in a directory by mouse name, then experiment
% date (corresponding to the base session on Alyx), then
% experiment/sequence number (corresponding to subsessions on Alyx). Alyx
% infers information about the files based on this directory structure.

% 2. Where the files are saved must correspond to a data repository that
% has been created on Alyx.  One such example is zubjects.  The data
% repository records are used by Globus to map the drive in order to copy
% selected files to The Flatiron Institute (availiable to other labs - only
% subjects under the project 'IBL' are copied).  More information:
% https://alyx.cortexlab.net/admin/data/datarepository/

% 3. The files must have a corresponding dataset type.  This is a record on
% Alyx that includes a human readable description of what the data are and
% a filename pattern for identifying the file.  It is suggested that the
% filename pattern correspond either to the ALF standard, or the Rigbox
% standard of expRef_type (more on this later).  Datasets, like sessions,
% are hierachical, for instance you could have a parent dataset type (with
% no corresponding files) that is called 'twoPhoton', with the ALF pattern
% '*_2P*.*'.  Child dataset types could include ROI files (e.g.
% '*_2P_ROI.*') and raw frames (e.g. '*_2P_ROI.*'). More info:
% https://alyx.cortexlab.net/admin/data/datasettype/
% ALFs (feel free to add):
% https://docs.google.com/spreadsheets/d/1DqyQ-Ho4eObR0B4nZMQz397TAUReaef-9dRWKwIa3JM/edit#gid=0

% 4. The files must have a valid format, defined on Alyx by the data format
% records.  These records include a description of the file format, the
% filename pattern (e.g. '*.mat' or '*.*.npy' for ALF files), and the
% function name for loading the file in MATLAB and Python.  More info:
% https://alyx.cortexlab.net/admin/data/dataformat/

%% Saving files
% Saving files in a standard way can be easily achieved by using
% dat.expFilePath to return the path and file name for your data.  The main
% data repository is defined in dat.paths, the folder tree by
% dat.canstructExpRef (used by dat.newExp), and the file name is
% constructed from the expRef + '_filetype'.  The list of file types are
% found here:
opentoline(which('dat.expFilePath'),45,1)
doc dat % further info

% For example, let's create a new experiment, then save the associated
% eye tracking data:
expRef = ai.newExp('test'); % Create new experiment ref and Alyx (sub)session
fullpath = dat.expFilePath(expRef, 'eyetracking', 'master')
% Without specifying the which repo location (i.e. 'master' or 'local'),
% you get both paths returned.
fullpaths = dat.expFilePath(expRef, 'eyetracking')

clear fullpaths
%% File registration
% In order to successfully register a file to Alyx, you must make sure the
% dataset type, repository and format records are created on the database
% first.  To register a file, you can use the registerFile method:
[datasets, filerecords] = ai.registerFile(fullpath) % Register a specific file
% The returned dataset records should contain the associated session URL
% and the dataset type, as well as a list of filerecords.  The filerecords
% contain the path to the files and what repository they're found on.

% You can also input a cell array of paths, including whole directories:
expPath = dat.expPath(expRef, 'main', 'master') % Returns the directory
[datasets, filerecords] = ai.registerFile(expPath)
% Returns the datasets are filerecords of all successfully registered files
% in the provided directory.  You can register the same file multiple
% times.  If a filerecord already exists, Alyx simply returns the original.

%% Alyx queue
% All posts to Alyx are first saved as a JSON file in a location specified
% by the objects QueueDir property.  This means that when a post fails for
% reasons other than user error, the posts remain in the queue until
% further notice.  Each time a user 'logs in', the queue is flushed,
% meaning that all saved posts are re-submitted to Alyx.  You can manually
% flush the queue by called in the flushQueue method:
ai.flushQueue

%% Debugging with http.jsonPost
% Unfortunately, the MATLAB built in http interface functions are limited
% in terms of debugging, as they don't directly return the server's
% responses upon failure.  Status codes must be extracted from the error
% message bodies, and the full reponse of the server is usually not
% returned.  In order to debug your Alyx posts, you can use the missing
% http package's jsonPost function instead.  See line 47 of
% Alyx.flushQueue:
opentoline(which('flushQueue'),47,1)

%% Sending Alyx around
% An Alyx instance can be sent between rigs in one of two ways:
% 1. Via Java Websockets using the io.WSJCommunicator.server/client object.
%   This object uses the hlp_serialize/deserialize functions to send the
%   object.
% 2. Via UDP using Rigbox services objects (using udp and pnet functions).
%   The Alyx.parseAlyxInstance method can be used to convert the object
%   into a JSON string and back again.
% Both methods ultimately use saveobj and loadobj methods to convert the
% Alyx object.  This isn't really important to know.
% More info: 
doc Alyx.parseAlyxInstance % Used by srv.BasicUDPService and tl.mpepListener
doc io.WSJCommunicator.server % Used by expServer to communicate with mc
doc srv.StimulusControl % Used by mc to communicate with expServer

%% Headless Alyx
% Before sending an instance of Alyx to a stimulus computer, consider
% setting the Headless property to 'true'.  This means that the object will
% not spawn any user prompts, and will supress some errors.  This can also
% be set when the database become unreachable.  All posts are still saved
% in the queue for when a user logs in on that computer.  NB: Even when
% headless the Alyx object may throw errors.  On recording computers,
% always put GET/POST related methods in a try-catch, or only attempt such
% things at the end of the experiment
ai.Headless = true;
ai = ai.logout;
ai = ai.login; % Dialog surpressed
ai.registerFile(expPath); % Dialog surpressed

%% MySQL queries
% One can also interact with Alyx through connection to the underlying
% MySQL database.  This currently isn't really supported by the alyx-matlab
% package and isn't encouraged.  More information:
open openAlyxSQL.m
doc alyx.expFilePath

%% Etc.