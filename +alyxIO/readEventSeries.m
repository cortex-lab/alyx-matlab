
function varargout = readEventSeries(inputFilebase, timebaseName)
% function etStruct = readEventSeries(inputFilebase, timebaseName)
% function [eventTimes, eventTypes, typeDescriptions] = readEventSeries(inputFilebase, timebaseName)

etyFile = [inputFilebase '.event_types.npy'];
if ~exist(etyFile, 'file')
    fprintf(1, 'failed to find %s\n', etyFile);
end
tydFile = [inputFilebase '.type_descriptions.npy'];

etFile = [inputFilebase '.event_times.' timebaseName '.npy'];
if ~exist(etFile)
    fprintf(1, 'no event_times for %s timebase\n', timebaseName);
    d = dir([inputFilebase '.event_times.*']);
    arrayfun(@(x)fprintf(1, 'available timebase: %s\n', x.name), d);
end

eventTimes = readNPY(etFile);
eventTypes = readNPY(etyFile);
td = char(readNPY(tydFile));
typeDescriptions = regexp(td, '\w*\t*', 'match');
% strip the trailing tab
typeDescriptions = cellfun(@(x)x(1:end-1), typeDescriptions, 'uni', false);

if nargout==1
    % want struct format    
    uTypes = unique(eventTypes);
    for q = 1:length(typeDescriptions)
        % uh oh, this is under-specified. need to work it out. 
        etStruct.(typeDescriptions{q}) = eventTimes(eventTypes==uTypes(q));
    end
    varargout{1} = etStruct;
else
    % want separate variables format
    varargout{1} = eventTimes;
    varargout{2} = eventTypes;
    varargout{3} = typeDescriptions;
end