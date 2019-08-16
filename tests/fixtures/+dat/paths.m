function p = paths(~)
% path containing rigbox config folders
p.rigbox = fileparts(which('addRigboxPaths'));
% Repository for local copy of everything generated on this rig
testDatDir = fileparts(mfilename('fullpath'));
p.localRepository = fullfile(testDatDir(1:end-5), 'subjects');
p.mainRepository = p.localRepository;
p.main2Repository = [p.mainRepository '_alt'];
p.databaseURL = 'https://test.alyx.internationalbrainlab.org';
end