function writeTimeseries(destDir, datasetName, timestamps, b, timebaseName)
% function writeTimeseries(destDir, datasetName, data, timestamps, b, timebaseName)
% Writes an "timeseries" dataset in the ALF format, providing conversion to universal
% timebase if desired. Does not write the data - just the timestamps part.
%
% - destDir - where the files go, a path
% - datasetName - a string, a label for this dataset. will get
% datasetName.times.npy
% - timestamps - specifying the timestamps of the elements of the
% associated data. Several specifications are possible: 
%   - a vector. In this case, interpreted as the literal timestamps of
%   every element. 
%   - an nx2 matrix. In this case, the first column is sample numbers
%   (0-indexed) and the second is the time in seconds of those samples
%   - a 2-element vector. In this case, the first element is interpreted as
%   the number of elements in the data, and the second as a sampling rate.
% - b, optional - a 2-element conversion (slope, intercept) to universal
% timebase
% - timebaseName, optional - a string giving the name for the original
% timebase. If not provided, assumes it is universal. If empty (but b is
% provided) then the original timebase just won't be written.

if ~exist(destDir, 'dir')
    mkdir(destDir);
end

if numel(timestamps)==2
    % interpret this as [nSamples, Fs]
    nSamp = timestamps(1); Fs = timestamps(2);
    times = [0 0; nSamp-1 (nSamp-1)/Fs];
elseif min(size(timestamps))==1 % is a row or column
    timestamps = timestamps(:); % to column
    
    % I don't know a general algorithm to "compress" these but we'll just
    % check one quick case - if the whole vector is evenly sampled  
    dt = diff(timestamps);
    mndt = mean(dt);
    if max(dt-mndt)<1e-6 % the differences are consistent to within a microsecond 
        nSamp = numel(timestamps); 
        Fs = 1/mndt;
        times = [0 0; nSamp-1 (nSamp-1)/Fs];
    else
        % have to represent the whole thing
        nSamp = numel(timestamps);
        times = [(0:nSamp-1)' timestamps];
    end
elseif size(timestamps,2)==2 % is n x 2
    assert(all(round(timestamps(:,1))==timestamps(:,1)), ...
        sprintf('first column of timestamps must be integers for %s', datasetName));
    [sampNums,ii] = sort(timestamps(:,1));
    sampTimes = timestamps(ii,2); 
    assert(issorted(sampTimes), sprintf('sample times are out of order for %s', datasetName));
    times = [sampNums sampTimes];
else
    error('timestamps size (%d, %d) is not interpretable for %s. Must be [2,1], [nSamp, 1], or [nSamp, 2]',...
        size(timestamps,1), size(timestamps,2), datasetName);
end
    
% if there is a conversion provided, convert to universal
if ~isempty(b) && numel(b)==2 
    univT = [times(:,2) ones(size(times(:,2)))]*b(:);
    univTimes = [times(:,1) univT];
    
    % write universal
    writeNPY(univTimes, fullfile(destDir, [datasetName '.timestamps.npy']));
    
    if ~isempty(timebaseName)
        % write original
        writeNPY(times, ...
            fullfile(destDir, sprintf('%s.timestamps_%s.npy', datasetName, timebaseName)));
    end
    
else % no conversion
    
    if ~isempty(timebaseName)
        % write original
        writeNPY(times, ...
            fullfile(destDir, sprintf('%s.timestamps_%s.npy', datasetName, timebaseName)));
    else
        % write original, as universal
        writeNPY(times, ...
            fullfile(destDir, [datasetName '.timestamps.npy']));
    end
end