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

% write any recorded software times
fnames = fieldnames(Timeline);
fields = mapToCell(@(fn) fn(1:length(fn)-6), fnames(endsWith(fnames, 'Events')));
if isempty(fields)
  return  % No software events to save
end
nEvents = sum(cellfun(@(fn) Timeline.([fn, 'Count']), fields));
T = table(...
  'Size', [nEvents 3], ...
  'VariableTypes', {'double', 'string', 'string'}, ...
  'VariableNames', {'time', 'name', 'info'});
i = 1;
for fn = string(fields)
  n = Timeline.([char(fn) 'Count']);
  T.time(i:n) = Timeline.([char(fn) 'Times'])(1:n);
  T.name(i:n) = repmat(fn, 1, n);
  T.info(1:n) = Timeline.([char(fn) 'Events'])(1:n);
  i = i+n;
end
T = sortrows(T);
filename = fullfile(destDir, '_timeline_softwareEvents.log.htsv');
writetable(T, filename, 'FileType', 'text', 'Delimiter', '\t', 'QuoteStrings', true)