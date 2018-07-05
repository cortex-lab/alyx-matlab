

function popRasterIBL(iblDir)
% function popRaster(mouseName, thisDate, tag, pars)
%
% Loads the population raster viewer for a dataset from alf format

[s, cweA, cwtA] = alf.loadIBLAlf(iblDir);

cluDepths = s.clusterDepths;

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
% add: by feature(s)

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

% task events/data
visColorsL = copper(4); visColorsL = visColorsL(2:4, [3 1 2]);
visColorsR = copper(4); visColorsR = visColorsR(2:4, [1 3 2]);
stimOn = cwtA.stimOn;
cL = cweA.contrastLeft;
uL = unique(cL);
cR = cweA.contrastRight;
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


beeps = cwtA.beeps;
n = n+1;
events(n).times = beeps; events(n).name = 'go cue'; events(n).spec = {'Color', [0 1 0]};

feedbackTime = cwtA.feedbackTime;
n = n+1;
events(n).times = feedbackTime; events(n).name = 'feedback'; events(n).spec = {'Color',[0 0 1]};
    


wheelP = readNPY(fullfile(iblDir, '_ibl_wheel.position.npy'));
wheelT = readNPY(fullfile(iblDir, '_ibl_wheel.timestamps.npy'));
wheelT = interp1(wheelT(:,1), wheelT(:,2), (0:numel(wheelP)-1));
wheelVel = conv(diff(wheelP),myGaussWin(0.02, 1/mean(diff(wheelT))), 'same');
traces(1).t = wheelT; traces(1).v = wheelVel; traces(1).name = 'wheel velocity';
traces(1).color = [1 1 1];

lickSig = readNPY(fullfile(iblDir, '_ibl_lickPiezo.raw.npy'));
lickT = readNPY(fullfile(iblDir, '_ibl_lickPiezo.timestamps.npy'));
lickT = interp1(lickT(:,1), lickT(:,2), (0:numel(lickSig)-1));
traces(2).t = lickT; traces(2).v = lickSig; traces(2).name = 'lick signal';
traces(2).color = [0 1 0];

vrf = VideoReader(fullfile(iblDir, 'face.mj2'));
vre = VideoReader(fullfile(iblDir, 'eye.mj2'));

tFace = readNPY(fullfile(iblDir, 'face.timestamps.npy'));
tf = interp1(tFace(:,1), tFace(:,2), (0:vrf.NumberOfFrames-1));
tEye = readNPY(fullfile(iblDir, 'eye.timestamps.npy'));
te = interp1(tEye(:,1), tEye(:,2), (0:vre.NumberOfFrames-1));

auxVid(1).data = {vrf, tf};
auxVid(1).f = @plotMJ2frame;
auxVid(1).name = 'face';
auxVid(2).data = {vre, te};
auxVid(2).f = @plotMJ2frame;
auxVid(2).name = 'eye';

viewerPars.startTime = stimOn(1);

popRasterViewer(s, events, traces, auxVid, [], viewerPars)
