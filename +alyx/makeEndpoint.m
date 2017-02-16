

function fullEndpoint = makeEndpoint(alyxInstance, endpoint)
% function fullEndpoint = makeEndpoint(alyxInstance, endpoint)
%
% determines whether the endpoint is a full url or just a relative url,
% returns a full url

if strcmp(endpoint(1:4), 'http')
    % this is a full url already
    fullEndpoint = endpoint;
else
    fullEndpoint = [alyxInstance.baseURL, '/', endpoint];
end

% drop trailing slashes
if strcmp(fullEndpoint(end), '/')
    fullEndpoint = fullEndpoint(1:end-1);
end