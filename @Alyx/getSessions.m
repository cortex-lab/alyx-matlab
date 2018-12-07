function sessions = getSessions(obj, varargin)
p = inputParser;
addRequired(p, 'subject');
addParameter(p, 'uuid', '');
addParameter(p, 'start_date', datestr(now, 'yyyy-mm-dd'));
addParameter(p, 'end_date', datestr(now, 'yyyy-mm-dd'));
addParameter(p, 'starts_after', '2016-01-01', 'PartialMatchPriority', 2);
addParameter(p, 'starts_before', datestr(now, 'yyyy-mm-dd'), 'PartialMatchPriority', 3);
addParameter(p, 'ends_before', datestr(now+1, 'yyyy-mm-dd'), 'PartialMatchPriority', 2);
addParameter(p, 'ends_after', '2016-01-01', 'PartialMatchPriority', 3);
addParameter(p, 'dataset_types', '');

parse(p, varargin{:})
names = setdiff(fieldnames(p.Results), p.UsingDefaults);
values = cellfun(@(fn)p.Results.(fn), names, 'uni', 0);
assert(length(names) == length(values))
queries = cell(length(names)*2,1);
queries(1:2:end) = names;
queries(2:2:end) = values;

sessions = obj.getData('sessions', queries{:});
end