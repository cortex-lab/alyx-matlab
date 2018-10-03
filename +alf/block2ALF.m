function [fullpath, filename] = block2ALF(data, varargin)
% ALF.BLOCK2ALF Extracts and saves ALF data from a block structure
%  TODO: Extract and save ALFs from old ChoiceWorld blocks
%  For more info on the dataset type, visit 
%  https://docs.google.com/spreadsheets/d/1DqyQ-Ho4eObR0B4nZMQz397TAUReaef-9dRWKwIa3JM0
% [fullpath, filename] = block2ALF(data_from_blockfile)
% [...] = block2ALF(...,'namespace', '_ibĺ_')
% [...] = block2ALF(...,'expPath', '/path/to/my/portable/experiment/subject/yyyy-mm-dd/1/')


% compute default namespace
expDef = getOr(data, {'expDef' 'expType'}); %TODO
namespace = iff(endsWith(expDef, 'choiceWorld.m'), '_ibl_', '_misc_');

% handle input parameters
p = inputParser;
addParameter(p,'expPath', dat.expPath(data.expRef, 'main', 'master'))
addParameter(p,'namespace', namespace)
parse(p,varargin{:});
for fn = fieldnames(p.Results)'; eval([fn{1} '= p.Results.' (fn{1}) ';']); end

expStartTime = data.events.expStartTimes; % CW: data.experimentStartedTime
evts = removeIncompleteTrials(data.events, length(data.events.endTrialTimes));
if isempty(evts.endTrialTimes)
    data.outputs.rewardValues =[];
else
    data.outputs.rewardValues(data.outputs.rewardTimes>evts.endTrialTimes(end)) = [];
end

% Write feedback
feedback = getOr(evts, 'feedbackValues', NaN);
feedback = double(feedback);
feedback(feedback == 0) = -1;
if ~isnan(feedback)
  writeNPY(int8(feedback(:)), fullfile(expPath, [namespace 'trials.feedbackType.npy']));
  alf.writeEventseries(expPath, [namespace 'trials.feedback'],...
    evts.feedbackTimes - expStartTime, [], []);
  rewardValues = feedback;
  rewardValues(feedback==1) = data.outputs.rewardValues;
  rewardValues(feedback==-1) = 0;
  writeNPY(rewardValues(:), ...
    fullfile(expPath, [namespace 'trials.rewardVolume.npy']));
else
  warning('No ''feedback'' events recorded, cannot register to Alyx')
end

% Write go cue
interactiveOn = getOr(evts, 'interactiveOnTimes', NaN);
if ~isnan(interactiveOn)
  interactiveOn = interactiveOn - expStartTime;
  alf.writeEventseries(expPath, [namespace 'trials.goCue'], interactiveOn, [], []);
else
  warning('No ''interactiveOn'' events recorded, cannot register to Alyx')
end

% Write response
response = getOr(evts, 'responseValues', NaN);
if max(response) == 3
  response(response == 3) = 0; % No go
  response(response == 2) = -1; % CCW
else
  response = -sign(response); % -ve now means CCW
end
if ~isnan(response)
  writeNPY(int8(response(:)), fullfile(expPath, [namespace 'trials.choice.npy']));
  responseTimes = evts.responseTimes - expStartTime;
  alf.writeEventseries(expPath, [namespace 'trials.response'],...
    responseTimes, [], []);
else
  responseTimes = [];
  warning('No ''feedback'' events recorded, cannot register to Alyx')
end

% Write stim on times
stimOnTimes = getOr(evts, 'stimulusOnTimes', NaN);
if ~isnan(stimOnTimes)
  stimOnTimes = stimOnTimes - expStartTime;
  alf.writeEventseries(expPath, [namespace 'trials.stimOn'], stimOnTimes, [], []);
else
  warning('No ''stimulusOn'' events recorded, cannot register to Alyx')
end
contL = getOr(evts, 'contrastLeftValues', NaN);
contR = getOr(evts, 'contrastRightValues', NaN);
if ~any(isnan(contL))&&~any(isnan(contR))
  writeNPY(contL(:), fullfile(expPath, [namespace 'trials.contrastLeft.npy']));
  writeNPY(contR(:), fullfile(expPath, [namespace 'trials.contrastRight.npy']));
else
  warning('No ''contrastLeft'' and/or ''contrastRight'' events recorded, cannot register to Alyx')
end

% Write probability left
probLeft = getOr(evts, 'proportionLeftValues', ...
  ones(length(data.events.endTrialTimes),1)*0.5);
writeNPY(probLeft(:), fullfile(expPath, [namespace 'trials.probabilityLeft.npy']));

% Write trial intervals
startTimes = evts.newTrialTimes(:)-expStartTime;
endTimes = evts.endTrialTimes(:)-expStartTime;
if length(endTimes) < length(startTimes)
  endTimes(end+1) = evts.expStopTimes-expStartTime;
end
alf.writeInterval(expPath, [namespace 'trials'], startTimes, endTimes, [], []);
repNum = uint8(evts.repeatNumValues(:));
writeNPY(repNum == 1, fullfile(expPath, [namespace 'trials.included.npy']));
writeNPY(repNum, fullfile(expPath, [namespace 'trials.repNum.npy']));

% Write wheel times, position and velocity
Fs = 1000;
t = data.inputs.wheelTimes(1):1/Fs:data.inputs.wheelTimes(end);
t = t - expStartTime;
rawPos = wheel.correctCounterDiscont(data.inputs.wheelValues);
pos = interp1(data.inputs.wheelTimes-expStartTime, rawPos, t, 'linear');
pos = pos - pos(1); % Position relative to beginning of session

switch lower(data.rigName) % TODO: add to rig hardware
  case {'zym1', 'zym2', 'zym3'}
    encRes = 360;
  case 'zurprise'
    encRes = 100;
  otherwise
    encRes = 1024;
end
pos = pos./(4*encRes)*2*pi*3.1; % convert to cm

alf.writeTimeseries(expPath, [namespace 'wheel'], t(:), [], []);
writeNPY(pos, fullfile(expPath, [namespace 'wheel.position.npy']));
writeNPY(wheel.computeVelocity2(pos, 0.03, Fs), ...
  fullfile(expPath, [namespace 'wheel.velocity.npy']));

[moveOnsets, moveOffsets] = wheel.findWheelMoves3(data.inputs.wheelValues, data.inputs.wheelTimes-expStartTime, Fs, []);

hasTurn = response~=0;
resp = response(hasTurn);
% Convert response to type required by classifyWheelMoves
resp(resp == 0) = 3; % No go
resp(resp == -1) = 2; % CCW
intStartTime = interactiveOn(hasTurn);
respTime = responseTimes(hasTurn);
moveType = wheel.classifyWheelMoves(data.inputs.wheelTimes-expStartTime, ...
  data.inputs.wheelValues, moveOnsets, moveOffsets, intStartTime, respTime, resp);

txtMoveType(moveType==0) = "flinch";
txtMoveType(moveType==1) = "CW";
txtMoveType(moveType==2) = "CCW";
txtMoveType(moveType==3) = "other";

alf.writeInterval(expPath, [namespace 'wheelMoves'], ...
  moveOnsets, moveOffsets, [], []);
fid = fopen(fullfile(expPath, [namespace 'wheelMoves.type.csv']),'w');
fprintf(fid, '%s', strjoin(txtMoveType,','));
fclose(fid);

% For IBL data, copy the matlab files in an ALF format under a _rigbox_ workspace
if strcmp( namespace, '_ibl_')
from_to =   {
		[ expPath filesep data.expRef '_parameters.json' ], [expPath filesep '_rigbox_jsonParameters.raw.json']; ...
		[ expPath filesep data.expRef '_parameters.mat' ], [expPath filesep '_rigbox_matParameters.raw.mat']; ...
		[ expPath filesep data.expRef '_Block.mat' ], [expPath filesep '_rigbox_block.raw.mat']; ...
		[ expPath filesep data.expRef '_expDef.m' ], [expPath filesep '_rigbox_code.raw.m']; ...
		[ expPath filesep data.expRef '_Timeline.mat' ], [expPath filesep '_rigbox_timeLine.raw.mat']; ...
		[ expPath filesep data.expRef '_hardwareInfo.json' ], [expPath filesep '_rigbox_hardwareInfo.raw.json']; ...
		};
    for m = 1:size(from_to,1)
        try
            copyfile(from_to{m,1}, from_to{m,2})
        catch
            warning([from_to{m,1} ' not found !'])
        end
    end
    ALFnames = {'raw.json', 'raw.mat', 'raw.m'};
else
    ALFnames = {};
end

% Collate paths
files = dir(expPath);
% Contruct paths
ALFnames = cat(2, ALFnames, {...
  'trials.feedbackType.npy',...
  'trials.feedback_times.npy',...
  'trials.rewardVolume.npy',...
  'trials.goCue_times.npy',...
  'trials.choice.npy',...
  'trials.response_times.npy',...
  'trials.stimOn_times.npy',...
  'trials.contrastLeft.npy',...
  'trials.contrastRight.npy',...
  'trials.probabilityLeft.npy',...
  'trials.intervals.npy',...
  'trials.included.npy',...
  'trials.repNum.npy',...
  'wheel.position.npy',...
  'wheel.velocity.npy',...
  'wheel.timestamps.npy',...
  'wheelMoves.type.csv',...
  'wheelMoves.intervals.npy'});
incl = cellfun(@(f)endsWith(f, ALFnames), {files.name});
files = files(incl);
fullpath = fullfile({files.folder}, {files.name})';
filename = {files.name}';
end

function S = removeIncompleteTrials(S, completedTrials)
    lengths = structfun(@length, S);
    names = fieldnames(S);
    names = names(lengths == completedTrials+1 | lengths == completedTrials+2);
    s = cellfun(@(x) x(1:completedTrials), pick(S, names), 'UniformOutput', 0);
    for n = 1:length(s)
        S.(names{n}) = s{n};
    end
end