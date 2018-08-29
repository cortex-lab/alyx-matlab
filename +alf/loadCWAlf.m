
function [sp, cweA, cwtA, moveData, lickTimes, passiveStim] = loadCWAlf(mouseName, thisDate, ephysTag)
% function [sp, cweA, cwtA, moveData, lickTimes, passiveStim] = loadCWAlf(mouseName, thisDate, ephysTag)
%

 
root = getRootDir(mouseName, thisDate);
alfDir = getALFdir(mouseName, thisDate);

if ~exist(alfDir, 'dir')
    error('no alf files found at %s', alfDir);
end

if isempty(ephysTag)
    sp = [];
else
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
    
    % identify acronym for each cluster
%     acr = cell(size(cds)); 
%     for q = 1:numel(acr)
%         bInd = find(cds(q)>borders.lowerBorder & cds(q)<=borders.upperBorder);
%         if ~isempty(bInd)
%             acr{q} = borders.acronym{bInd}; 
%         end
%     end
    [acr, d] = listInclArea(); st = loadStructureTree();
    stAcr = arrayfun(@(x)standardAcrByDepth(borders, x, acr, d, st), cds, 'uni', false);
    
    sp.acr = stAcr;
    sp.coords = coords;
    sp.borders = borders;
    
end

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

% - wheel data, to include in moveData struct
moveData.wheelPos = readNPY(fullfile(alfDir, 'wheel.position.npy'));
moveData.wheelT = readNPY(fullfile(alfDir, 'wheel.timestamps.npy'));
% moveData.wheelT = interp1(wt(:,1), wt(:,2), (0:(numel(moveData.wheelPos)-1))');

% - lickTimes - a vector of lick times
lickTimes = readNPY(fullfile(alfDir, 'licks.times.npy'));



%passive data
ad = alfDir;
if exist(fullfile(ad, 'passiveStimOn.times.npy'), 'file')
    stimOn = readNPY(fullfile(ad, 'passiveStimOn.times.npy'));
    contrastLeft = readNPY(fullfile(ad, 'passiveStimOn.contrastLeft.npy'));
    contrastRight = readNPY(fullfile(ad, 'passiveStimOn.contrastRight.npy'));
    valveClick = readNPY(fullfile(ad, 'passiveValveClick.times.npy'));
    whiteNoise = readNPY(fullfile(ad, 'passiveWhiteNoise.times.npy'));
    beep = readNPY(fullfile(ad, 'passiveBeep.times.npy'));
    
    isValveClick = false(size(stimOn));
    isWhiteNoise = false(size(stimOn));
    isBeep = false(size(stimOn));
    
    if ~isnan(valveClick(1))
        stimOn = [stimOn; valveClick];
        contrastLeft = [contrastLeft; zeros(size(valveClick))];
        contrastRight = [contrastRight; zeros(size(valveClick))];
        isValveClick = [isValveClick; true(size(valveClick))];
        isWhiteNoise = [isWhiteNoise; false(size(valveClick))];
        isBeep = [isBeep; false(size(valveClick))];
    end
    
    if ~isnan(whiteNoise(1))
        stimOn = [stimOn; whiteNoise];
        contrastLeft = [contrastLeft; zeros(size(whiteNoise))];
        contrastRight = [contrastRight; zeros(size(whiteNoise))];
        isValveClick = [isValveClick; false(size(whiteNoise))];
        isWhiteNoise = [isWhiteNoise; true(size(whiteNoise))];
        isBeep = [isBeep; false(size(whiteNoise))];
    end
    
    if ~isnan(beep(1))
        stimOn = [stimOn; beep];
        contrastLeft = [contrastLeft; zeros(size(beep))];
        contrastRight = [contrastRight; zeros(size(beep))];
        isValveClick = [isValveClick; false(size(beep))];
        isWhiteNoise = [isWhiteNoise; false(size(beep))];
        isBeep = [isBeep; true(size(beep))];
    end
    
else
    fprintf(1, 'passive not found\n')
    stimOn = []; contrastLeft = []; contrastRight = [];
    isValveClick = []; isWhiteNoise = []; isBeep = [];
end

passiveStim = table(stimOn, contrastLeft, contrastRight, isValveClick, isWhiteNoise, isBeep);
passiveStim = sortrows(passiveStim, 'stimOn');



% if exist(fullfile(alfDir, 'include.recording.npy'))
%     incl = readNPY(fullfile(alfDir, 'include.recording.npy'));
% else
%     incl = [];
% end
