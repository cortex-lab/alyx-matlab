function timelineToALF(Timeline, b, destDir)
% function timelineToALF(timeline, b, destDir)
%
% Converts a Timeline structure to alyx file format
%
% Inputs:
% - Timeline, a timeline structure
% - b, a 2-element conversion vector to universal timebase, optional
% - destDir, a place to put the results

assert(exist('writeNPY', 'file') > 0,...
    'writeNPY not found; cannot proceed saving Timeline to ALF')

% Save each recorded vector into the correct format in Timeline timebase
% and optionally into universal timebase if conversion is provided
inputs = {Timeline.hw.inputs.name};
inputs = inputs([Timeline.hw.inputs.arrayColumn] > -1); % ignore inputs that were unused
nSamps = Timeline.rawDAQSampleCount;
tlTimes = [0 Timeline.rawDAQTimestamps(1); nSamps-1 Timeline.rawDAQTimestamps(end)];
for ii = 1:length(inputs)
    
    dat = Timeline.rawDAQData(:,ii);
    
    writeNPY(dat, fullfile(destDir, [inputs{ii} '.raw.npy']));
    
    writeNPY(tlTimes, fullfile(destDir, [inputs{ii} '.timestamps_Timeline.npy']));
    
    if ~isempty(b) && numel(b)==2
        univTimes = [tlTimes(:,2) [1;1]]*b(:);
        writeNPY(univTimes, fullfile(destDir, [inputs{ii} '.timestamps.npy']));
    end
    
end