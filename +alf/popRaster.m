

function popRaster(mouseName, thisDate, ephysTag, pars)
% function popRaster(mouseName, thisDate, tag, pars)
%
% Loads the population raster viewer for a dataset from alf format

rootE = dat.expPath(mouseName, thisDate, 1, 'main', 'master');
root = fileparts(rootE);
alfDir = fullfile(root, 'alf');

s.st = readNPY(fullfile(alfDir, ephysTag, 'spikes.times.npy'));

s.clu = readNPY(fullfile(alfDir, ephysTag, 'spikes.clusters.npy'));
s.cids = readNPY(fullfile(alfDir, ephysTag, 'clusters.ids.npy'));
s.cgs = readNPY(fullfile(alfDir, ephysTag, 'clusters.groups.npy'));
cluDepths = readNPY(fullfile(alfDir, ephysTag, 'clusters.depths.npy'));

s.yAxOrderings(1).name = 'depth value'; 
s.yAxOrderings(1).yPos = cluDepths(:);
s.yAxOrderings(2).name = 'depth index'; 
[~,ii] = sort(cluDepths); dpOrder = zeros(size(cluDepths)); dpOrder(ii) = 1:numel(cluDepths);
s.yAxOrderings(2).yPos = dpOrder(:);
s.yAxOrderings(3).name = 'clu'; 
s.yAxOrderings(3).yPos = [1:numel(s.cids)]';
[vals,inst] = countUnique(s.clu);
assert(numel(vals)==numel(s.cids)&&all(vals==s.cids));
[~,ii] = sort(inst); frOrder = zeros(size(inst)); frOrder(ii) = 1:numel(inst);
s.yAxOrderings(4).name = 'firing rate'; 
s.yAxOrderings(4).yPos = frOrder(:);
% add: by firing rate, by feature(s)

s.colorings(1).name = 'random'; 
cm = colorcet('C6'); % cm = hsv(100); 
rcm = zeros(numel(s.cids),3);
thisR = rand(1,numel(s.cids));
for c = 1:3    
    rcm(:,c) = interp1(linspace(0, 1, size(cm,1)), cm(:,c), thisR);
end
s.colorings(1).colors = rcm;
s.colorings(2).name = 'by group'; 
s.colorings(2).colors = zeros(numel(s.cids), 4);
s.colorings(2).colors(s.cgs>1,:) = 1;
s.colorings(3).name = 'depth'; 
cm = colorcet('C6'); %cm = hsv(100); 
dcm = zeros(numel(s.cids),3);
for c = 1:3
    dcm(:,c) = interp1(linspace(min(cluDepths), max(cluDepths),size(cm,1)), cm(:,c), cluDepths);
end
s.colorings(3).colors = dcm;
% add: by spike amplitude, by anatomical region

if exist(fullfile(alfDir, 'cwStimOn.times.npy'), 'file')
    visColorsL = copper(4); visColorsL = visColorsL(2:4, [3 1 2]);
    visColorsR = copper(4); visColorsR = visColorsR(2:4, [1 3 2]);
    stimOn = readNPY(fullfile(alfDir, 'cwStimOn.times.npy'));
    cL = readNPY(fullfile(alfDir, 'cwStimOn.contrastLeft.npy'));
    uL = unique(cL);
    cR = readNPY(fullfile(alfDir, 'cwStimOn.contrastRight.npy'));
    uR = unique(cR);
    n = 1;
    events(n).times = stimOn(cR==uR(2)); events(n).name = 'stim right low';
    events(n).spec = {'Color', visColorsR(1,:), 'LineWidth',0.5};
    n = n+1;
    events(n).times = stimOn(cR==uR(3)); events(n).name = 'stim right med';
    events(n).spec = {'Color', visColorsR(2,:), 'LineWidth',1.0};
    n = n+1;
    events(n).times = stimOn(cR==uR(4)); events(n).name = 'stim right high';
    events(n).spec = {'Color', visColorsR(3,:), 'LineWidth',2.0};
    n = n+1;
    events(n).times = stimOn(cL==uL(2)); events(n).name = 'stim left low';
    events(n).spec = {'Color', visColorsL(1,:), 'LineWidth',0.5, 'LineStyle', '--'};
    n = n+1;
    events(n).times = stimOn(cL==uL(3)); events(n).name = 'stim left med';
    events(n).spec = {'Color', visColorsL(2,:), 'LineWidth',1.0, 'LineStyle', '--'};
    n = n+1;
    events(n).times = stimOn(cL==uL(4)); events(n).name = 'stim left high';
    events(n).spec = {'Color', visColorsL(3,:), 'LineWidth',2.0, 'LineStyle', '--'};
    
    
    beeps = readNPY(fullfile(alfDir, 'cwGoCue.times.npy'));
    n = n+1;
    events(n).times = beeps; events(n).name = 'go cue'; events(n).spec = {'Color', [0 1 0]};
    
    feedbackTime = readNPY(fullfile(alfDir, 'cwFeedback.times.npy'));
    n = n+1;
    events(n).times = feedbackTime; events(n).name = 'feedback'; events(n).spec = {'Color',[0 0 1]};
    
else 
    stimOn = 1;
    events = [];
end

wheelVel = readNPY(fullfile(alfDir, 'wheel.velocity.npy'));
wheelT = readNPY(fullfile(alfDir, 'wheel.timestamps.npy'));
wheelT = interp1(wheelT(:,1), wheelT(:,2), (0:numel(wheelVel)-1));
traces(1).t = wheelT; traces(1).v = wheelVel; traces(1).name = 'wheel velocity';
traces(1).color = [1 1 1];

if exist(fullfile(alfDir, 'cwStimOn.times.npy'), 'file')
    lickSig = readNPY(fullfile(alfDir, 'lickSignal.trace.npy'));
    lickT = readNPY(fullfile(alfDir, 'lickSignal.timestamps.npy'));
    lickT = interp1(lickT(:,1), lickT(:,2), (0:numel(lickSig)-1));
    traces(2).t = lickT; traces(2).v = lickSig; traces(2).name = 'lick signal';
    traces(2).color = [0 1 0];
end

% how to get expNum here: see which timeline is registered to ephys master
% (a bit hacky, but ok, whatever)
alignDir = fullfile(root, 'alignments');
d = dir(fullfile(alignDir, 'correct_timeline*'));
if ~isempty(d)
    q = sscanf(d.name, 'correct_timeline_%d_to_ephys_%s.npy');
    tlExpNum = q(1);
end

auxVid = prepareAuxVids(mouseName, thisDate, tlExpNum);
tFace = readNPY(fullfile(alfDir, 'face.timestamps.npy'));
auxVid(1).data{2} = interp1(tFace(:,1), tFace(:,2), (0:auxVid(1).data{1}.NumberOfFrames-1));
tEye = readNPY(fullfile(alfDir, 'eye.timestamps.npy'));
auxVid(2).data{2} = interp1(tEye(:,1), tEye(:,2), (0:auxVid(2).data{1}.NumberOfFrames-1));

viewerPars.startTime = stimOn(1);

popRasterViewer(s, events, traces, auxVid, [], viewerPars)
