
function writeTimestamp(outputFilebase, timebaseName, eventTimes)
% function writeTimestamp(outputFilebase, timebaseName, eventTimes)
% Writes a timestamp model

writeNPY(eventTimes, [outputFilebase '.event_times.' timebaseName '.npy']);