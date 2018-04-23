function writeEventseries(destDir, datasetName, eventTimes, b, timebaseName)
% function writeEventseries(destDir, datasetName, eventTimes, b, timebaseName)
% Writes an "eventseries" dataset in the ALF format, providing conversion to universal
% timebase if desired.
%
% - destDir - where the files go, a path
% - datasetName - a string, a label for this dataset. will get
% datasetName.times.npy
% - eventTimes - vector of the times, in seconds
% - b, optional - a 2-element conversion (slope, intercept) to universal
% timebase
% - timebaseName, optional - a string giving the name for the original
% timebase. If not provided, assumes it is universal. If empty (but b is
% provided) then the original timebase just won't be written.

if ~exist(destDir, 'dir')
    mkdir(destDir);
end

eventTimes = eventTimes(:); % to column

% if there is a conversion provided, convert to universal
if ~isempty(b) && numel(b)==2 
    univTimes = [eventTimes ones(size(eventTimes))]*b(:);
    
    % write universal
    writeNPY(univTimes, fullfile(destDir, [datasetName '.times.npy']));
    
    if ~isempty(timebaseName)
        % write original
        writeNPY(eventTimes, ...
            fullfile(destDir, sprintf('%s.times_%s.npy', datasetName, timebaseName)));
    end
    
else % no conversion
    
    if ~isempty(timebaseName)
        % write original
        writeNPY(eventTimes, ...
            fullfile(destDir, sprintf('%s.times_%s.npy', datasetName, timebaseName)));
    else
        % write original, as universal
        writeNPY(eventTimes, ...
            fullfile(destDir, [datasetName '.times.npy']));
    end
end