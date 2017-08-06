

function evRastersALF(mouseName, thisDate, ephysTag, pars)
% Load ALF data and call evRastersGUI with it
%
% - pars - struct contains:
%   - mode - string, either "mua" or "clu" to get data binned by depth or
%   just cluster number
%   - depthBinSize - in µm

if isempty(pars)
    mode = 'clu';
else
    mode = pars.mode;
end
 
rootE = dat.expPath(mouseName, thisDate, 1, 'main', 'master');
root = fileparts(rootE);
alfDir = fullfile(root, 'alf');

% - st - vector of spike times
st = readNPY(fullfile(alfDir, ephysTag, 'spikes.times.npy'));

% - clu - vector of cluster identities
% see below - need coords first 

% - cweA - table of trial labels, containing contrastLeft, contrastRight,
% choice, and feedback
contrastLeft = readNPY(fullfile(alfDir, 'cwStimOn.contrastLeft.npy'));
contrastRight = readNPY(fullfile(alfDir, 'cwStimOn.contrastRight.npy'));
choice = readNPY(fullfile(alfDir, 'cwResponse.choice.npy'));
feedback = readNPY(fullfile(alfDir, 'cwFeedback.type.npy'));
cweA = table(contrastLeft, contrastRight, choice, feedback);

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

% - anatData - a struct with: 
%   - coords - [nCh 2] coordinates of sites on the probe
%   - wfLoc - [nClu nCh] size of the neuron on each channel
%   - borders - table containing upperBorder, lowerBorder, acronym
coords = readNPY(fullfile(root, ['ephys_' ephysTag], 'sorting', 'channel_positions.npy'));
borders = readtable(fullfile(alfDir, ephysTag, ['borders_' ephysTag '.tsv']) ,'Delimiter','\t', 'FileType', 'text');

anatData.coords = coords;
anatData.borders = borders;

switch mode
    case 'mua'
        depthBin = pars.depthBinSize; % µm
        
        sd = readNPY(fullfile(alfDir, ephysTag, 'spikes.depths.npy'));
        
        clu = ceil(sd/depthBin)*depthBin;
        
        % create a simulated set of "waveforms" that will just highlight the
        % correct segment of the probe
        uClu = unique(clu);
        fakeWF = zeros(numel(uClu), numel(coords(:,1)));
        ycBins = ceil(coords(:,2)/depthBin)*depthBin;
        for c = 1:numel(uClu)
            fakeWF(c,ycBins==uClu(c)) = 1;
        end
        anatData.wfLoc = fakeWF;
        
    case 'clu'
        clu = readNPY(fullfile(alfDir, ephysTag, 'spikes.clusters.npy'));
        wfs = readNPY(fullfile(alfDir, ephysTag, 'clusters.waveforms.npy'));
        cids = readNPY(fullfile(alfDir, ephysTag, 'clusters.ids.npy'));
        cgs = readNPY(fullfile(alfDir, ephysTag, 'clusters.groups.npy'));
        
        % don't include MUA here
        inclCID = cids(cgs>1);
        st = st(ismember(clu, inclCID));
        clu = clu(ismember(clu, inclCID));
        wfs = wfs(cgs>1,:,:);                
        
        wfLoc = squeeze(max(abs(wfs), [], 2));
        
        % find max position, to order by it
        [~,maxChan] = max(wfLoc, [], 2);
        [~,ii] = sort(maxChan);           
        anatData.clusterIDs = inclCID(ii);
        anatData.wfLoc = wfLoc(ii,:);
        anatData.waveforms = permute(wfs(ii,20:end,:), [1 3 2]);
end

evRastersGUI(st, clu, cweA, cwtA, moveData, lickTimes, anatData)