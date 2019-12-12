function [sessions, eids] = getSessions(obj, varargin)
% GETSESSIONS Return sessions and eids for a given search query
%   Returns Alyx records for specific refs (eid and/or expRef strings)
%   and/or those matching search queries.  Values may be char arrays,
%   strings, or cell strings.  If searching dates, values may also be a
%   datenum or array thereof.
%
%   Examples:
%     sessions = ai.getSessions('cf264653-2deb-44cb-aa84-89b82507028a')
%     sessions = ai.getSessions('2018-07-13_1_flowers')
%     sessions = ai.getSessions('cf264653-2deb-44cb-aa84-89b82507028a', ...
%                 'subject', {'flowers', 'ZM_307'})
%     sessions = ai.getSessions('lab', 'cortexlab', ...
%                 'date_range', datenum([2018 8 28 ; 2018 8 31]))
%     sessions = ai.getSessions('date', now)
%     sessions = ai.getSessions('data', {'clusters.probes', 'eye.blink'})
%     [~, eids] = ai.getSessions(expRefs)
%
% See also ALYX.UPDATESESSIONS, ALYX.GETDATA

p = inputParser;
if mod(length(varargin),2) % Uneven num args when ref is first input
  validationFcn = @(x)(iscellstr(x) || isstring(x) || ischar(x));
  addOptional(p, 'ref', [], validationFcn);
end
% Parse Name-Value paired args
addParameter(p, 'subject', '');
addParameter(p, 'users', '');
addParameter(p, 'lab', '');
addParameter(p, 'date_range', '', 'PartialMatchPriority', 2);
addParameter(p, 'dataset_types', '');
addParameter(p, 'number', 1);
addParameter(p, 'type', '');

[sessions, results, eids] = deal({}); % Initialize as empty
parse(p, varargin{:})

% Convert search params back to cell
names = setdiff(fieldnames(p.Results), [{'ref'} p.UsingDefaults]);
% Get values, and if nessesary convert datenums to datestrs
values = cellfun(@(fn)processValue(fn), names, 'uni', 0);
assert(length(names) == length(values))
queries = cell(length(names)*2,1);
queries(1:2:end) = names;
queries(2:2:end) = values;

% Get sessions for specified refs
if isfield(p.Results, 'ref') && ~isempty(p.Results.ref)
  refs = cellstr(p.Results.ref);
  parsedRef = regexp(refs, dat.expRefRegExp, 'names');
  sessFromRef = @(ref)obj.getData('sessions/', ...
    'subject', ref.subject, 'date_range', [ref.date ',' ref.date], 'number', ref.seq);
  isRef = ~emptyElems(parsedRef);
  sessions = [mapToCell(@(eid)obj.getData(['sessions/' eid]), refs(~isRef))...
    mapToCell(sessFromRef, parsedRef(isRef))];
  sessions = rmEmpty(sessions);
end

% Do search for other queries
if ~isempty(queries); results = obj.getData('sessions', queries{:}); end
% Return on empty
if isempty(sessions) && isempty(results); return; end
sessions = catStructs([sessions, ensureCell(results)]);
if nargout > 1
  eids = obj.url2eid({sessions.url});
end

  function value = processValue(name)
    % If the value is a datenum, convert to string
    if contains(name,'date')
      % Ensure date range
      if isnumeric(p.Results.(name))
        value = iff(numel(p.Results.(name))==1, repmat(p.Results.(name),1,2), p.Results.(name));
        value = string(datestr(value, 'yyyy-mm-dd'));
      elseif isscalar(string(p.Results.(name))) && ~any(p.Results.(name)==',')
        value = repmat(string(p.Results.(name)),2,1);
      else
        error('Alyx:getSessions:InvalidInput', 'The value of ''date_range'' is invalid')
      end
    else
      value = p.Results.(name);
    end
    % Cat arrays for url
    if iscellstr(value)||isstring(value); value = strjoin(value,','); end
  end
end