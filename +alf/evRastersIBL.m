

function f = evRastersIBL(directory, pars)
% Load ALF data and call evRastersGUI with it
%
% - pars - struct contains:
%   - mode - string, either "mua" or "clu" to get data binned by depth or
%   just cluster number
%   - depthBinSize - in µm

[sp, cweA, cwtA, moveData, lickTimes] = alf.loadIBLAlf(directory);
    
st = sp.st;    
anatData.coords = sp.coords;
anatData.borders = sp.borders;

if isempty(pars)
    mode = 'clu';
else
    mode = pars.mode;
end
switch mode
    case 'mua'
        depthBin = pars.depthBinSize; % µm
        
        sd = sp.spikeDepths;
        
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
        clu = sp.clu;
        wfs = sp.waveforms;
        cids = sp.cids;
        cgs = sp.cgs;
        
        
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
    
    
f = evRastersGUI(st, clu, cweA, cwtA, moveData, lickTimes, anatData);