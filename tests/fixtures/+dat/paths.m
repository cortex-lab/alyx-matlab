function p = paths(customPathStruct)
persistent customPaths
if nargin == 1 && isstruct(customPathStruct)
  % Set some custom paths to be returned, similar in behaviour to the
  % custom paths set in a rig hardware file
  customPaths = customPathStruct;
end
% path containing rigbox config folders
p.rigbox = fileparts(which('addRigboxPaths'));
% Repository for local copy of everything generated on this rig
testDatDir = fileparts(mfilename('fullpath'));
p.localRepository = fullfile(testDatDir(1:end-5), 'local');
p.mainRepository = fullfile(testDatDir(1:end-5), 'subjects');
p.main2Repository = [p.mainRepository '_alt'];
p.databaseURL = 'https://test.alyx.internationalbrainlab.org';
if ~isempty(customPaths); p = mergeStructs(customPaths, p); end
end