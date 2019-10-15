function eid = url2eid(url)
% URL2EID Return eid portion of Alyx URL
%   Provided a url (or array thereof) returns the eid portion.
%
%   Example:
%     url =
%     'https://www.url.com/sessions/bc93a3b2-070d-47a8-a2b8-91b3b6e9f25c';
%     eid = Alyx.url2eid(url)
%
% See also ALYX.MAKEENDPOINT
%
% Part of Alyx
% 2019 MW created

if iscell(url)
  eid = mapToCell(@Alyx.url2eid, url);
  return
end

eid_length = 36; % Length of our uuids
% Ensure url longer than minimum length
assert(numel(url) >= eid_length, ...
'Alyx:url2Eid:InvalidURL', 'URL may not contain eid')

% Remove trailing slash if present
url = strip(url, 'right', '/');
% Get eid component of url
% eid = mapToCell(@(str)str(end-eid_length+1:end), url);
eid = url(end-eid_length+1:end);