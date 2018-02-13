function [obj, statusCode] = getToken(obj, username, password)
%GETTOKEN Acquire an authentication token for Alyx
%   Makes a request for an authentication token to an Alyx instance;
%   returns the token and status code.
%
% Example:
% statusCode = getToken('https://alyx.cortexlab.net', 'max', '123')
%
% See also ALYX, LOGIN

[statusCode, responseBody] = http.jsonPost([obj.BaseURL, '/auth-token/'],...
  ['{"username":"', username, '","password":"', password, '"}']);
if statusCode == 200
  resp = loadjson(responseBody);
  obj.Token = resp.token;
  obj.User = username;
  
  % Flush the local queue on successful login
  obj.flushQueue();
else
  error(responseBody)
end
end

