
function writeEventSeries(outputFilebase, timebaseName, varargin)
% function writeEventSeries(outputFilebase, eventTimesStruct)
% OR
% function writeEventSeries(outputFilebase, eventTimes, eventTypes, typeDescriptions)
%
% Writes NPY files in format compatible with the alyx scheme
% outputFilebase should be a full path and filename without any extension
% eventTimes must be nEv x 1
%
% TODO: add support for multi-dimensional types, i.e. if eventTypes is size
% [nEv x 3] or whatever. How to do typeDescriptions?

if nargin==3
    et = varargin{1};
    fn = fieldnames(et);
    typeDescriptions = sprintf('%s\t', fn{:}); % tab-separated list    
    ts = cellfun(@(x)et.(x), fn, 'uni', false); % ts is a cell array with all the stamps
    eventTimes = cat(1, ts{:}); % make them into one big vector
    [eventTimes, ii] = sort(eventTimes);
    eventTypes = arrayfun(@(x)(ones(size(ts{x}))*x), 1:length(fn), 'uni', false);
    eventTypes = cat(1, eventTypes{:});
    eventTypes = eventTypes(ii); % sort to match eventTimes
    
else
    
    eventTimes = varargin{1};
    eventTypes = varargin{2};
    typeDescriptions = varargin{3};
    
end

writeNPY(eventTypes, [outputFilebase '.event_types.npy']);
writeNPY(uint16(typeDescriptions), [outputFilebase '.type_descriptions.npy']);

alyxIO.writeTimestamp(outputFilebase, timebaseName, eventTimes);

