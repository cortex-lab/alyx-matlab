

function conn = openAlyxSQL()
% function conn = openAlyxSQL()
% 
% Opens a read-only connection with alyx to do SQL queries. Some
% installation steps are necessary first - see exampleSQLquery.m

datasourcename = 'alyx';
driver ='org.postgresql.Driver';
databaseurl = 'jdbc:postgresql://cone.cortexlab.net:5432/';

username = 'alyx_ro'; % special read-only account

% load password from user directory
alyxUserDir = fullfile(getuserdir, '.alyx');
alyxPassFile = fullfile(alyxUserDir, 'alyx_ro_password');
if exist(alyxPassFile)
    fid = fopen(alyxPassFile, 'r');
    pass = fscanf(fid, '%s'); 
    fclose(fid);
else
    % try to look for it on zserver?
    
    % open a window to type it? 
end    

try
    conn = database(datasourcename,username,pass,driver,databaseurl);
catch me
    fprintf(1, 'Could not open connection with alyx!\n')
    fprintf(1, 'May need to follow installation steps - see exampleSQLquery.m\n');
    rethrow(me)
end

% if the user typed it or it came from zserver, and the password was 
% successful, save it to the hidden directory so it's there next time. 



% from https://uk.mathworks.com/matlabcentral/fileexchange/15885-get-user-home-directory
function userDir = getuserdir
%GETUSERDIR   return the user home directory.
%   USERDIR = GETUSERDIR returns the user home directory using the registry
%   on windows systems and using Java on non windows systems as a string
%
%   Example:
%      getuserdir() returns on windows
%           C:\Documents and Settings\MyName\Eigene Dateien
if ispc
    userDir = winqueryreg('HKEY_CURRENT_USER',...
        ['Software\Microsoft\Windows\CurrentVersion\' ...
         'Explorer\Shell Folders'],'Personal');
else
    userDir = char(java.lang.System.getProperty('user.home'));
end