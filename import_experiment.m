import logindlg.*

% Data about the subject to be input
subjectInfo = struct('nickname', 'AR123', 'responsible_user', 'kenneth');

% Basic parameters
baseURL = 'http://alyx.cortexlab.net/';
options = weboptions('RequestMethod', 'post');

% First, we need to get an authentication token. Present the user with a
% login prompt
[uname, pwd] = logindlg;

% Authenticate and get a token
auth = webread([baseURL 'auth-token/'], 'username', uname, 'password', pwd, options);
authOptions = weboptions('KeyName', 'Authorization', 'KeyValue', ['Token ' auth.token]);
options = weboptions('MediaType','application/json', 'KeyName', 'Authorization', 'KeyValue', ['Token ' auth.token]);

% List subjects
subjects = webread([baseURL 'subjects/'], options)

% Try add our own subject
newSubject = webwrite([baseURL 'subjects/'], options, subjectInfo);

