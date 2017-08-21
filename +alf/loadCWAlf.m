
function [sp, cweA, cwtA, moveData, lickTimes] = loadCWAlf(mouseName, thisDate, ephysTag)
% function [sp, cweA, cwtA, moveData, lickTimes] = loadCWAlf(mouseName, thisDate, ephysTag)
%

 
rootE = dat.expPath(mouseName, thisDate, 1, 'main', 'master');
root = fileparts(rootE);
alfDir = fullfile(root, 'alf');

% - st - vector of spike times
st = readNPY(fullfile(alfDir, ephysTag, 'spikes.times.npy'));
sp.st = st;


% - clu - vector of cluster identities
clu = readNPY(fullfile(alfDir, ephysTag, 'spikes.clusters.npy'));
sp.clu = clu;

wfs = readNPY(fullfile(alfDir, ephysTag, 'clusters.waveforms.npy'));
cids = readNPY(fullfile(alfDir, ephysTag, 'clusters.ids.npy'));
cgs = readNPY(fullfile(alfDir, ephysTag, 'clusters.groups.npy'));
cds = readNPY(fullfile(alfDir, ephysTag, 'clusters.depths.npy'));
sd = readNPY(fullfile(alfDir, ephysTag, 'spikes.depths.npy'));
sa = readNPY(fullfile(alfDir, ephysTag, 'spikes.amps.npy'));

sp.spikeAmps = sa;
sp.spikeDepths = sd;
sp.clusterDepths = cds;
sp.cgs = cgs;
sp.cids = cids;
sp.waveforms = wfs;

% - cweA - table of trial labels, containing contrastLeft, contrastRight,
% choice, and feedback
contrastLeft = readNPY(fullfile(alfDir, 'cwStimOn.contrastLeft.npy'));
contrastRight = readNPY(fullfile(alfDir, 'cwStimOn.contrastRight.npy'));
choice = readNPY(fullfile(alfDir, 'cwResponse.choice.npy'));
feedback = readNPY(fullfile(alfDir, 'cwFeedback.type.npy'));
inclTrials = readNPY(fullfile(alfDir, 'cwTrials.inclTrials.npy'));
repNum = readNPY(fullfile(alfDir, 'cwTrials.repNum.npy'));
cweA = table(contrastLeft, contrastRight, choice, feedback, inclTrials, repNum);

% - cwtA - table of times of events in trials, containing stimOn, beeps,
% and feedbackTime
stimOn = readNPY(fullfile(alfDir, 'cwStimOn.times.npy'));
beeps = readNPY(fullfile(alfDir, 'cwGoCue.times.npy'));
feedbackTime = readNPY(fullfile(alfDir, 'cwFeedback.times.npy'));
cwtA = table(stimOn, beeps, feedbackTime);

% - moveData - a struct with moveOnsets, moveOffsets, moveType
wheelMoves = readNPY(fullfile(alfDir, 'wheelMoves.intervals.npy'));
moveOnsets = wheelMoves(:,1); moveOffsets = wheelMoves(:,2);
moveType = readNPY(fullfile(alfDir, 'wheelMoves.type.npy'));
moveData.moveOnsets = moveOnsets; moveData.moveOffsets = moveOffsets; moveData.moveType = moveType;

% - lickTimes - a vector of lick times
lickTimes = readNPY(fullfile(alfDir, 'licks.times.npy'));

%   - coords - [nCh 2] coordinates of sites on the probe
coords = readNPY(fullfile(root, ['ephys_' ephysTag], 'sorting', 'channel_positions.npy'));

%   - borders - table containing upperBorder, lowerBorder, acronym
bordersFile = fullfile(alfDir, ephysTag, ['borders_' ephysTag '.tsv']);
if exist(bordersFile, 'file')
    borders = readtable(bordersFile ,'Delimiter','\t', 'FileType', 'text');
else
    upperBorder = max(coords(:,2)); lowerBorder = min(coords(:,2)); acronym = {'??'};
    borders = table(upperBorder, lowerBorder, acronym);
end

sp.coords = coords;
sp.borders = borders;
