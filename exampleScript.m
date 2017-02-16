

% Example script for alyx-matlab usage

%% installation/set paths

% download https://github.com/psexton/missing-http/releases/tag/missing-http-1.0.0
% clone https://github.com/cortex-lab/alyx-matlab/
% install https://uk.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files
%  -- (download tooolbox and run it)

addpath(genpath('C:\Users\Nick\Documents\MATLAB\missing-http-1.0.0'));
onLoad; % initializes missing-http
addpath(genpath('C:\Users\Nick\Documents\GitHub\alyx-matlab'));

%% open an instance

myAlyx = alyx.getToken([], 'nick', '123');

%% create some data to post for a weighing

clear d
d.subject = 'Whipple'; % note lower-case "subject", it is case sensitive
d.weight = 22.1; 
d.user = 'nick';
% other fields are "date_time" (defaults to now) and "weighing_scale" (not
% currently used)

%% post it 

newWeighing = alyx.postData(myAlyx, 'weighings/', d) % note trailing / on "weighings" and lower-case, both critical
% it has returned the full new entry that you created

%% create some data to post for a water administration

clear d
d.subject = 'Whipple'; % note lower-case "subject", it is case sensitive
d.water_administered = 0.97; %units of mL 
d.user = 'nick';
% other field is "date_time" (defaults to now)

%% post it 

newWater = alyx.postData(myAlyx, 'water-administrations/', d)
% it has returned the full new entry that you created
