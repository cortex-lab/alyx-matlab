


% Example script for executing SQL queries from Alyx in matlab

%% one-time installation: JDBC

% See https://uk.mathworks.com/help/database/ug/postgresql-jdbc-windows.html
% for installation instructions. 
%
% If you follow the links, the driver will come from here:
% https://jdbc.postgresql.org/download.html

% On my computer, when I do
version -java

% I get 1.7, so I downloaded the 4.1 driver as per the suggestion on that
% page. 

%% settings

pathToDriver = 'C:\Users\Nick\Documents\MATLAB\postgresql-42.0.0.jre7.jar';

javaaddpath(pathToDriver)
setdbprefs('DataReturnFormat','cellarray')


%% open a connection

datasourcename = 'alyx';
driver ='org.postgresql.Driver';
databaseurl = 'jdbc:postgresql://rod.cortexlab.net:5432/';

username = 'alyx_ro'; % special read-only account
% pass = ''; % declare this variable yourself, it is x**!***

conn = database(datasourcename,username,pass,driver,databaseurl);


%% make a query

q = fetch(exec(conn, 'select username from auth_user')); 
usernames = q.Data

% rock on. 