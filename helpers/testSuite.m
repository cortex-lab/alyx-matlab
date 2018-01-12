%testSuite
%Runs a bunch of tests on alyx-dev

%% Load alyx instance
alyxInstance = alyx.loginWindowDev();

%% Tests
fprintf('Test: Get a subject\n');
s = alyx.getData(alyxInstance, ['subjects?nickname=Beadle']);
assert(contains(s{1}.nickname,'Beadle'), 'Bad subject returned');

fprintf('Test: Get a session for a specific subject, type, and date\n');
s = alyx.getData(alyxInstance, ['sessions?subject=Beadle&type=Experiment&start_date=2018-01-11']);
assert(~isempty(s),'No sessions found');

fprintf('Test: Create a dataset\n');
d=struct;
d.created_by = alyxInstance.username;
d.dataset_type = 'Block';
d.session = 'https://alyx-dev.cortexlab.net/sessions/00cb6d7b-7da0-4173-bfcf-f9860750f42c';
d.created_date = alyx.datestr(15135355);
dataset = alyx.postData(alyxInstance, 'datasets', d);

fprintf('Test: Create filerecord\n');
d = struct;
d.dataset = dataset.url;
d.data_repository = 'zserver';
d.relative_path = 'bla/bla/bla';
filerecord = alyx.postData(alyxInstance, 'files', d);

fprintf('Test: Registering a file with alyx.RegisterFile\n');
alyx.registerFile('Beadle',[],'Block','\\zserver.cortexlab.net\Data2\Subjects\Beadle\2018-01-11\2\2018-01-11_2_Beadle_Block.mat','zserver',alyxInstance);




