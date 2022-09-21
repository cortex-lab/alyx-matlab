function timelineToALF(Timeline, ~, destDir)
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

% Save raw timeline data
nSamps = Timeline.rawDAQSampleCount;
tlTimes = [0 Timeline.rawDAQTimestamps(1); nSamps-1 Timeline.rawDAQTimestamps(end)];
writeNPY(tlTimes, fullfile(destDir, '_timeline_DAQdata.timestamps.npy'));
writeNPY(Timeline.rawDAQData, fullfile(destDir, '_timeline_DAQdata.raw.npy'));

%  write hardware info to a JSON file for compatibility with database
fid = fopen(fullfile(destDir, '_timeline_DAQdata.meta.json'), 'w');
fprintf(fid, '%s', jsonencode(Timeline.hw));
fclose(fid);