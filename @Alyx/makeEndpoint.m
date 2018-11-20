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
    &&ischar(endpoint)...
    &&length(endpoint) > 3, 'Invalid endpoint');

if strcmp(endpoint(1:4), 'http')
  % this is a full url already
  fullEndpoint = endpoint;
else
  fullEndpoint = [obj.BaseURL, '/', endpoint];
end

% drop trailing slash
fullEndpoint = strip(fullEndpoint, '/');