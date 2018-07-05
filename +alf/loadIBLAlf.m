
function [sp, cweA, cwtA, moveData, lickTimes] = loadIBLAlf(alfDir)
% function [sp, cweA, cwtA, moveData, lickTimes] = loadIBLAlf(directory)
%

if ~exist(alfDir, 'dir')
    error('no alf files found at %s', alfDir);
end

% - st - vector of spike times
st = readNPY(fullfile(alfDir, 'spikes.times.npy'));
sp.st = st;

% - clu - vector of cluster identities
clu = readNPY(fullfile(alfDir, 'spikes.clusters.npy'));
sp.clu = clu;

% wfs = readNPY(fullfile(alfDir, ephysTag, 'clusters.waveforms.npy'));
wfDat = readNPY(fullfile(alfDir, 'clusters.templateWaveforms.npy'));
wfCh = readNPY(fullfile(alfDir, 'clusters.templateWaveformChans.npy'));
cp = readNPY(fullfile(alfDir, 'clusters.probes.npy'));
chanprobe = readNPY(fullfile(alfDir, 'channels.probe.npy'));
np = max(chanprobe(:))+1;

% shift wfCh up on the probe
lastEndCh = find(chanprobe==0,1,'last');
for p = 2:np    
    wfCh(cp==p-1,:) = wfCh(cp==p-1,:)+lastEndCh;
    lastEndCh = lastEndCh+numel(chanprobe==p-1);
end

wfs = zeros(size(wfDat,1),size(wfDat,2),max(wfCh(:)+1));
for q = 1:size(wfDat,1)
    wfs(q,:,wfCh(q,:)+1) = squeeze(wfDat(q,:,:));
end

cids = [0:size(wfDat,1)-1]';
cgs = readNPY(fullfile(alfDir, 'clusters._phy_annotation.npy'));
cds = readNPY(fullfile(alfDir, 'clusters.depths.npy'));
sd = readNPY(fullfile(alfDir, 'spikes.depths.npy'));
sa = readNPY(fullfile(alfDir, 'spikes.amps.npy'));

% shift cluster depths and spike depths for subsequent probes
coords = readNPY(fullfile(alfDir, 'channels.sitePositions.npy')); 

for p = 2:np
    maxLastProbe = max(coords(chanprobe==p-2,2));
    coords(chanprobe==p-1,2) = coords(chanprobe==p-1,2)+maxLastProbe;
    
    cds(cp==p-1) = cds(cp==p-1)+maxLastProbe;
    sd(ismember(clu,find(cp==p-1))) = sd(ismember(clu,find(cp==p-1)))+maxLastProbe;
end

sp.spikeAmps = sa;
sp.spikeDepths = sd;
sp.clusterDepths = cds;
sp.cgs = cgs;
sp.cids = cids;
sp.waveforms = wfs;

%   - borders - table containing upperBorder, lowerBorder, acronym
brainLoc = readtable(fullfile(alfDir, 'channels.brainLocation.tsv'),...
    'Delimiter','\t', 'FileType', 'text');

aa = brainLoc.allen_ontology;
adiff = arrayfun(@(x)~strcmp(aa{x}, aa{x-1}), 2:numel(aa));
starts = [1;find(adiff)'+1]; ends = [find(adiff)'+1; size(coords,1)];
acronym = aa(starts);
lowerBorder = coords(starts, 2);
upperBorder = coords(ends,2);
borders = table(upperBorder, lowerBorder, acronym);

sp.coords = coords;
sp.borders = borders;


% - cweA - table of trial labels, containing contrastLeft, contrastRight,
% choice, and feedback
contrastLeft = readNPY(fullfile(alfDir, '_ns_trials.visualStim_contrastLeft.npy'));
contrastRight = readNPY(fullfile(alfDir, '_ns_trials.visualStim_contrastRight.npy'));
choice = readNPY(fullfile(alfDir, '_ns_trials.response_choice.npy'));
choice(choice==0) = 3; % No go
choice(choice==-1) = 2; % CCW
feedback = readNPY(fullfile(alfDir, '_ns_trials.feedbackType.npy'));
inclTrials = readNPY(fullfile(alfDir, '_ns_trials.included.npy'));
repNum = readNPY(fullfile(alfDir, '_ns_trials.repNum.npy'));
cweA = table(contrastLeft, contrastRight, choice, feedback, inclTrials, repNum);

% - cwtA - table of times of events in trials, containing stimOn, beeps,
% and feedbackTime
stimOn = readNPY(fullfile(alfDir, '_ns_trials.visualStim_times.npy'));
beeps = readNPY(fullfile(alfDir, '_ns_trials.goCue_times.npy'));
feedbackTime = readNPY(fullfile(alfDir, '_ns_trials.feedback_times.npy'));
cwtA = table(stimOn, beeps, feedbackTime);

% - moveData - a struct with moveOnsets, moveOffsets, moveType
wheelMoves = readNPY(fullfile(alfDir, '_ns_wheelMoves.intervals.npy'));
moveOnsets = wheelMoves(:,1); moveOffsets = wheelMoves(:,2);
moveType = readNPY(fullfile(alfDir, '_ns_wheelMoves.type.npy'));
moveData.moveOnsets = moveOnsets; moveData.moveOffsets = moveOffsets; moveData.moveType = moveType;

% - lickTimes - a vector of lick times
lickTimes = readNPY(fullfile(alfDir, 'licks.times.npy'));

if exist(fullfile(alfDir, 'include.recording.npy'))
    incl = readNPY(fullfile(alfDir, 'include.recording.npy'));
else
    incl = [];
end
