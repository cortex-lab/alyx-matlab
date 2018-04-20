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

[subsession, statusCode] = ai.postData('sessions', d) %#ok<*NOPTS>

% With this method you can also make PUT and PATCH requests to amending a
% record.  NB: Only for those endpoints with these options availible.
data = obj.postData(endpoint, data, 'put'); % Update the record

%% Datasets
% Data repository

% Dataset type

% Data formats
doc dat
opentoline(which('dat.expFilePath'),45,1)
% ALFs
% https://docs.google.com/spreadsheets/d/1DqyQ-Ho4eObR0B4nZMQz397TAUReaef-9dRWKwIa3JM/edit#gid=0

%% File registration

%% Alyx queue

%% Debugging with http.jsonPost

%% Sending Alyx around

%% Headless Alyx

%% 

%% MySQL queries

%% Etc.