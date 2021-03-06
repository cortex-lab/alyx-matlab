function fullEndpoint = makeEndpoint(obj, endpoint)
% MAKEENDPOINT Returns a complete Alyx Rest API endpoint URL
%   Determines whether the endpoint is a full url or just a relative url
%   and returns a full one.
%
% See also ALYX, FLUSHQUEUE
%
% Part of Alyx

% 2017 -- created

% validate endpoint
assert(~isempty(endpoint)...
       && (ischar(endpoint) || isStringScalar(endpoint))...
       && endpoint ~= "", ...
       'Alyx:makeEndpoint:invalidInput', 'Invalid endpoint');

if startsWith(endpoint, 'http')
  % this is a full url already
  fullEndpoint = endpoint;
else
  fullEndpoint = [obj.BaseURL, '/', char(endpoint)];
  if isstring(endpoint)
    fullEndpoint = string(fullEndpoint);
  end
end

% drop trailing slash
fullEndpoint = strip(fullEndpoint, '/');