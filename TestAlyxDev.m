%Runs a bunch of tests on alyx-dev
mode = 'normal'; %'dev' (for alyx-dev) or 'normal' (for alyx)

%Setup 1:  Test basic HTTP communication to the server
[statusCode, responseBody] = http.jsonGet(URL, 'Authorization', '');
assert(statusCode==200,'Could not communicate');
assert(~isempty(responseBody), 'Could not get list of endpoints');

%Setup 2: login to alyx-dev to create an alyxInstance
try
    switch(mode)
        case 'dev'
            URL = 'https://alyx-dev.cortexlab.net';
            alyxInstance = alyx.loginWindowDev();
        case 'normal'
            URL = 'https://alyx.cortexlab.net';
            alyxInstance = alyx.loginWindow();
    end
    
    % Pre-Test: Check that alyxInstance object is correct
    assert( isfield(alyxInstance, 'token') , 'Token not found in alyxInstance object');
    assert( strcmp(alyxInstance.baseURL , URL), 'Token URL does not match the chosen URL');
catch
    error('Problem logging in');
end

datetime = alyx.datestr(now); %Use today's date for various tests later

%Define a temp file on zserver which will be used later for file record
%registration
serverFile = '\\zubjects.cortexlab.net\Lab\Share\PeterZH\testAlyxFile.mat';

%% Test: Get the 'test' subject from the database
s = alyx.getData(alyxInstance, ['subjects?nickname=test']);
assert( length(s)==1, 'Should only be returning one object');
assert( all(isfield(s{1},{'nickname','id','url','birth_date'})) , 'Does not contain proper fields');
assert( strcmp(s{1}.nickname,'test'), 'Subject nickname is not test name');

%% Test: Posting water for the subject test
try
    alyx.postWater(alyxInstance, 'test', 1, datetime, 1);
catch
    error('Failed to post water');
end

%% Test: Create a BASE and EXPERIMENT session, and then get it back
%First create a base session
d = struct('subject','test','procedure',{'Behavior training/tasks'},'narrative','auto-generated session',...
    'start_time',datetime, 'type', 'Base');
try
    base_submit = alyx.postData(alyxInstance, 'sessions', d);
    assert( startsWith(base_submit.url, URL), 'BASE Session object does not contain the right URL');
catch
    error('Creating a BASE session did not work');
end

%Second create an experiment session
d = struct('subject','test','procedure',{'Behavior training/tasks'},'narrative','auto-generated session',...
    'start_time',datetime, 'type', 'Experiment','parent_session',base_submit.url, 'number', 1);
try
    expt_submit = alyx.postData(alyxInstance, 'sessions', d);
    assert( startsWith(expt_submit.url, URL), 'EXPT Session object does not contain the right URL');
catch
    error('Creating an EXPT session did not work');
end

%Third get the base and experiment sessions back, specifying the mouse name
%and full date
sessions = alyx.getData(alyxInstance,['sessions?subject=test&start_time=' datetime]);
assert( length(sessions)==2, 'Unexpected number of returned sessions');

%Fourth get the sessions again, but only specifying the name and date (not
%time). Test that the sessions returned were indeed just for this date
sessions = alyx.getData(alyxInstance,['sessions?subject=test&start_date=' datetime(1:10)]);
dates = floor( cellfun(@(s) alyx.datenum(s.start_time), sessions, 'uni', 1) );
assert( all(dates == floor(alyx.datenum(datetime))), 'At least one returned session was not from todays date');

%% Test: Create datasets & filerecord
%Get the experiment session created earlier
sessions = alyx.getData(alyxInstance,['sessions?subject=test&type=Experiment&start_time=' datetime]);
assert( length(sessions)==1, 'Unexpected number of returned sessions');

%Create a parent dataset
d = struct('created_by',alyxInstance.username,...
    'dataset_type','Block',...
    'session',sessions{1}.url);
try
    parent_dataset = alyx.postData(alyxInstance, 'datasets', d);
catch
    error('Problem creating parent dataset');
end

%Create a child dataset
d = struct('created_by',alyxInstance.username,...
    'dataset_type','Block',...
    'session',sessions{1}.url,...
    'parent_dataset',parent_dataset.url);
try
    child_dataset = alyx.postData(alyxInstance, 'datasets', d);
catch
    error('Problem creating child dataset');
end

%Create a filerecord
d = struct('dataset',child_dataset.url,...
    'data_repository','zubjects',...
    'relative_path','bla\bla\bla');
try
    filerecord = alyx.postData(alyxInstance, 'files', d);
catch
    error('Problem creating file record');
end

%% Test: alyx.registerFile
sessions = alyx.getData(alyxInstance,['sessions?subject=test&type=Experiment&start_time=' datetime]);
assert( length(sessions)==1, 'Unexpected number of returned sessions');
fid = fopen(serverFile, 'wt' ); fclose(fid);

[dataset,filerecord] = alyx.registerFile(serverFile,'mat',sessions{1}.url,'Block',[],alyxInstance);

%Delete file
delete(serverFile);

%% Test: Get the dataset(s) associated with a particular date
filePath = alyx.expFilePath('test', datetime(1:10), 1, []);

