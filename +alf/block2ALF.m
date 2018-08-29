function [fullpath, filename] = block2ALF(data)
% ALF.BLOCK2ALF Extracts and saves ALF data from a block structure
%  TODO: Extract and save ALFs from old ChoiceWorld blocks
%  For more info on the dataset type, visit 
%  https://docs.google.com/spreadsheets/d/1DqyQ-Ho4eObR0B4nZMQz397TAUReaef-9dRWKwIa3JM0

expPath = dat.expPath(data.expRef, 'main', 'master');
expDef = getOr(data, {'expDef' 'expType'}); %TODO
namespace = iff(strcmp(expDef, 'choiceWorld'), '_ibl_', '_misc_');
expStartTime = data.events.expStartTimes; % CW: data.experimentStartedTime
evts = removeIncompleteTrials(data.events, length(data.events.endTrialTimes));

% Write feedback
feedback = getOr(evts, 'feedbackValues', NaN);
feedback = double(feedback);
feedback(feedback == 0) = -1;
if ~isnan(feedback)
  writeNPY(feedback(:), fullfile(expPath, [namespace 'trials.feedbackType.npy']));
  alf.writeEventseries(expPath, [namespace 'trials.feedback_times'],...
    evts.feedbackTimes, [], []);
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
  alf.writeEventseries(expPath, [namespace 'trials.goCue_times'], interactiveOn, [], []);
else
  warning('No ''interactiveOn'' events recorded, cannot register to Alyx')
end

% Write response
response = getOr(evts, 'responseValues', NaN);
if max(response) == 3
  response(response == 3) = 0; % No go
  response(response == 1) = -1; % CCW
  response(response == 2) = 1; % CW
else
  response = -sign(response); % -ve now means CCW
end
if ~isnan(response)
  writeNPY(response(:), fullfile(expPath, [namespace 'trials.choice.npy']));
  responseTimes = evts.responseTimes - expStartTime;
  alf.writeEventseries(expPath, [namespace 'trials.response_times'],...
    responseTimes, [], []);
else
  warning('No ''feedback'' events recorded, cannot register to Alyx')
end

% Write stim on times
stimOnTimes = getOr(evts, 'stimulusOnTimes', NaN);
if ~isnan(stimOnTimes)
  alf.writeEventseries(expPath, [namespace 'trials.stimOn_times'], stimOnTimes, [], []);
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

% Write trial intervals
startTimes = evts.newTrialTimes(:)-expStartTime;
endTimes = evts.endTrialTimes(:)-expStartTime;
if length(endTimes) < length(startTimes)
  endTimes(end+1) = evts.expStopTimes-expStartTime;
end
alf.writeInterval(expPath, [namespace 'trials.intervals'], startTimes, endTimes, [], []);
repNum = evts.repeatNumValues(:);
writeNPY(repNum == 1, fullfile(expPath, [namespace 'trials.included.npy']));
writeNPY(repNum, fullfile(expPath, [namespace 'trials.repNum.npy']));

% Write wheel times, position and velocity
Fs = 1000;
t = data.inputs.wheelTimes(1):1/Fs:data.inputs.wheelTimes(end);
t = t - expStartTime;
rawPos = wheel.correctCounterDiscont(data.inputs.wheelValues);
pos = interp1(data.inputs.wheelTimes-expStartTime, rawPos, t, 'linear');

switch lower(data.rigName) % TODO: add to rig hardware
  case {'zym1', 'zym2', 'zym3'}
    encRes = 360;
  case 'zurprise'
    encRes = 100;
  otherwise
    encRes = 1024;
end
pos = pos./(4*encRes)*2*pi*31; % convert to mm

alf.writeTimeseries(expPath, [namespace 'wheel'], t(:), [], []);
writeNPY(pos, fullfile(expPath, [namespace 'wheel.position.npy']));
writeNPY(wheel.computeVelocity2(pos, 0.03, Fs), ...
  fullfile(expPath, [namespace 'wheel.velocity.npy']));

[moveOnsets, moveOffsets] = wheel.findWheelMoves3(data.inputs.wheelValues, ...
  data.inputs.wheelTimes-expStartTime, Fs, []);

hasTurn = response~=0;
resp = response(hasTurn);
intStartTime = interactiveOn(hasTurn);
respTime = responseTimes(hasTurn);
moveType = wheel.classifyWheelMoves(data.inputs.wheelTimes-expStartTime, ...
  data.inputs.wheelValues, moveOnsets, moveOffsets, intStartTime, respTime, resp);

txtMoveType(moveType==0) = "flinch";
txtMoveType(moveType==1) = "CCW";
txtMoveType(moveType==-1) = "CW";

alf.writeInterval(expPath, [namespace 'wheelMoves.intervals'], ...
  moveOnsets, moveOffsets, [], []);
fid = fopen(fullfile(expPath, [namespace 'wheelMoves.type.csv']),'w');
fprintf(fid, '%s', strjoin(txtMoveType,','));
fclose(fid);

% Collate paths
files = dir(expPath);
isNPY = cellfun(@(f)endsWith(f, '.npy'), {files.name});
isCSV = cellfun(@(f)endsWith(f, '.csv'), {files.name});
files = files(isNPY|isCSV);
fullpath = fullfile({files.folder}, {files.name});
filename = {files.name};
end

function S = removeIncompleteTrials(S, completedTrials)
    lengths = structfun(@length, S);
    names = fieldnames(S);
    names = names(lengths == completedTrials+1);
    s = cellfun(@(x) x(1:completedTrials), pick(S, names), 'UniformOutput', 0);
    for n = 1:length(s)
        S.(names{n}) = s{n};
    end
end