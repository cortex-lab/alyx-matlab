


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
% pass = ''; % declare this variable yourself, see wiki for password
% (http://wiki.cortexlab.net/index.php/Alyx_database#Data_queries_from_matlab)

conn = database(datasourcename,username,pass,driver,databaseurl);


%% make a query
tic
q = fetch(exec(conn, 'select username from auth_user')); 
cell2table(q.Data, 'VariableNames', myColNames(q))

q = fetch(exec(conn, ['select nickname from subjects_subject '...
    'inner join auth_user on subjects_subject.responsible_user_id=auth_user.id '...
    'where username in (''nick'')']));
cell2table(q.Data, 'VariableNames', myColNames(q))
toc
% rock on. 

%% search over json fields

tic; 
q = fetch(exec(conn, ['select * from electrophysiology_extracellularrecording '...
    'where json::json->>''expNum''=''2'''])); 
cell2table(q.Data, 'VariableNames', myColNames(q))

toc

%% Q: How do you know what are the names of all the tables and fields? 
% A: Several methods - 

% 1) run the Database Explorer gui thing. 
% 1a. Under Apps, find database explorer
% 1b. Click New then JDBC
% 1c. Select Postgres SQL. Enter in the details: 
%   - server name = rod.cortexlab.net
%   - port number = 5432
%   - username = alyx_ro
%   - password = [see wiki: http://wiki.cortexlab.net/index.php/Alyx_database#Data_queries_from_matlab]
%   - database = alyx
% Then you can use the Database Browser to see all the tables and data. 
% This may only work after you have used the command-line version of
% connecting (above) at least once (or that seemed to be the case for me,
% anyway). 

% 2) To get the table names, query this directly:
q = fetch(exec(conn, 'select table_name from information_schema.tables where table_schema=''public'' AND table_type=''BASE TABLE'''));
q.Data

% 3) To get the field names when you know the table name, run an empty
% query on that table:
myColNames(fetch(exec(conn, 'select * from subjects_subject where false')))


