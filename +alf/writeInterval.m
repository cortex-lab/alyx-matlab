

function writeInterval(destDir, datasetName, onsetTimes, offsetTimes, b, timebaseName)
% function writeInterval(destDir, datasetName, onsetTimes, offsetTimes, b, timebaseName)
% Writes an "interval" dataset in the ALF format, with checks to try to
% make sure it comes out correctly, and providing conversion to universal
% timebase if desired.
%
% - destDir - where the files go, a path
% - datasetName - a string, a label for this dataset. will get
% datasetName.intervals.npy
% - onsetTimes, offsetTimes - vectors of onsets and offsets
% - b, optional - a 2-element conversion (slope, intercept) to universal
% timebase
% - timebaseName, optional - a string giving the name for the original
% timebase. If not provided, assumes it is universal. If empty (but b is
% provided) then the original timebase just won't be written.
%
% note, intervals are allowed to overlap

if ~exist(destDir, 'dir')
    mkdir(destDir);
end

onsetTimes = onsetTimes(:); % to column
offsetTimes = offsetTimes(:);

% check that onsetTimes and offsetTimes have the right number of entries;
% pad with -Inf/+Inf if not
if numel(onsetTimes)==0 && numel(offsetTimes)==1
    onsetTimes = -Inf;
elseif numel(onsetTimes)==1 && numel(offsetTimes)==0
    offsetTimes = Inf;
elseif numel(onsetTimes)>0 && numel(offsetTimes)>0
    % since we're encoding these as intervals, want to make sure they are
    % all complete
    if numel(offsetTimes)>numel(onsetTimes) 
        % assume there are too many offsets because the first one didn't
        % have a start
        onsetTimes = [-Inf; onsetTimes]; 
    end
    if numel(onsetTimes)>numel(offsetTimes) 
        % assume there are too many onsets because the last one didn't end
        offsetTimes = [offsetTimes; Inf]; 
    end
end

% check that onset and offset times specify valid intervals (offsets follow
% onsets)
assert(numel(onsetTimes)==numel(offsetTimes), ...
    sprintf('wrong numbers of onset (%d) and offset (%d) times for interval %s',...
    numel(onsetTimes), numel(offsetTimes), datasetName));
assert(~any((offsetTimes-onsetTimes)<0), ...
    sprintf('not all offset times follow onset times for interval %s',...
    datasetName));

% if there is a conversion provided, convert to universal
if ~isempty(b) && numel(b)==2 
    univOnset = [onsetTimes ones(size(onsetTimes))]*b(:);
    univOffset = [offsetTimes ones(size(offsetTimes))]*b(:);
    univTimes = [univOnset univOffset];
    
    % write universal
    writeNPY(univTimes, fullfile(destDir, [datasetName '.intervals.npy']));
    
    if ~isempty(timebaseName)
        % write original
        writeNPY([onsetTimes offsetTimes], ...
            fullfile(destDir, sprintf('%s.intervals_%s.npy', datasetName, timebaseName)));
    end
    
else % no conversion
    
    if ~isempty(timebaseName)
        % write original
        writeNPY([onsetTimes offsetTimes], ...
            fullfile(destDir, sprintf('%s.intervals_%s.npy', datasetName, timebaseName)));
    else
        % write original, as universal
        writeNPY([onsetTimes offsetTimes], ...
            fullfile(destDir, [datasetName '.intervals.npy']));
    end
end

return;

%% test cases


datasetName = 'test1';
on = [1 2 3]; 
off = on+0.5;
b = []; timebaseName = [];
alf.writeInterval(destDir, datasetName, on, off, b, timebaseName);
q = readNPY(fullfile(destDir, [datasetName '.intervals.npy']));
if all(q(:,1)==on(:)) && all(q(:,2)==off(:))
    fprintf(1, 'test1 success\n');
else
    fprintf(1, 'test1 failed\n');
end

%%
destDir = './';
datasetName = 'test2';
on = [1 2 3]; 
off = on-0.5;
b = []; timebaseName = [];
alf.writeInterval(destDir, datasetName, on, off, b, timebaseName);
% should give an error

%%

datasetName = 'test3';
on = [1 2 3]; 
off = on+0.5; off = off(1:end-1);
b = []; timebaseName = [];
alf.writeInterval(destDir, datasetName, on, off, b, timebaseName);
q = readNPY(fullfile(destDir, [datasetName '.intervals.npy']))
if all(q(:,1)==on(:)) && all(q(:,2)==[off(:);Inf])
    fprintf(1, '%s success\n', datasetName);
else
    fprintf(1, '%s failed\n', datasetName);
end

%%

datasetName = 'test4';
on = [1 2 3]; 
off = [1.5 2.5 3.5 4.5 5.5];
b = []; timebaseName = [];
alf.writeInterval(destDir, datasetName, on, off, b, timebaseName);
q = readNPY(fullfile(destDir, [datasetName '.intervals.npy']))
% should give an error

%%
datasetName = 'test5';
on = [1 2 3]; 
off = on+0.5;
b = [1 10]; timebaseName = 'orig';
alf.writeInterval(destDir, datasetName, on, off, b, timebaseName);
q = readNPY(fullfile(destDir, [datasetName '.intervals.npy']))
q_orig = readNPY(fullfile(destDir, [datasetName '.intervals_orig.npy']))
if all(q_orig(:,1)==on(:)) && all(q_orig(:,2)==off(:)) && ...
        all(q(:,1)==on(:)+10) && all(q(:,2)==off(:)+10)
    fprintf(1, '%s success\n', datasetName);
else
    fprintf(1, '%s failed\n', datasetName);
end
