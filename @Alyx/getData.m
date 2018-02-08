function [data, statusCode] = getData(obj, endpoint)
%GETDATA Return a specific Alyx/REST read-only endpoint
%   Makes a request to an Alyx endpoint; returns the data as a bMATLAB struct.
%
%   Example:
%     subjects = obj.getData('subjects')
%
% See also ALYX, MAKEENDPOINT, REGISTERFILE, HTTP.JSONGET, LOADJSON
%
% Part of Alyx

% 2017 PZH created

fullEndpoint = obj.makeEndpoint(endpoint); % Get complete URL
[statusCode, responseBody] = http.jsonGet(fullEndpoint, 'Authorization', ['Token ' obj.Token]);

if statusCode == 200 % Success
  data = loadjson(responseBody);
elseif statusCode == 403 % Invalid token
  obj.logout; % Delete token
  if ~obj.Headless % Prompts not supressed
    obj.login; % Re-login
    data = obj.getData(fullEndpoint); % Retry
  else
    error(responseBody) % Throw error
  end
else % Fail
  error(responseBody)
end

end