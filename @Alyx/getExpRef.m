function ref = getExpRef(obj, eid)
% GETEXPREF Return experiment reference string given a list of session eids
%   Returns one or more experiment reference strings given a list of
%   session eids or urls.  
%
%   Note: To convert refs to eids, see Alyx.getSessions
%
%   Examples:
%     ref = ai.getExpRef('cf264653-2deb-44cb-aa84-89b82507028a')
%     refs = ai.getExpRef({...
%       'cf264653-2deb-44cb-aa84-89b82507028a', ...
%       ai.makeEndpoint('sessions/e84cfbc9-20f6-4e85-b221-aae3c18b2fd9')})
%
% See also ALYX.GETSESSIONS

singleArg = ~iscell(eid);
try % Get eid from url (if provided)
  eid = mapToCell(@(e)e(end-35:end), ensureCell(eid));
catch
  error('Alyx:getExpRef:InvalidID', 'Invalid session url or eid')
end
sessions = obj.getSessions(eid); % Query sessions

% Construct our experiment references
ref = dat.constructExpRef(...
  {sessions.subject}, ...
  obj.datenum({sessions.start_time})', ...
  {sessions.number});

% if non-cell inputs were supplied, make sure we don't return a cell
if singleArg
  ref = ref{1};
end