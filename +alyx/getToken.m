function [token, statusCode] = getToken(baseURL, username, password)
%getToken Acquire an authentication token for Alyx
%
% Description: Makes a request for an authentication token to an Alyx
% instance; returns the token and status code.
%
% Example:
% token = getToken('http://alyx.cortexlab.net', 'max', '123')

if isempty(baseURL)
    baseURL = 'http://alyx.cortexlab.net';
end


[statusCode, responseBody] = http.jsonPost([baseURL, '/auth-token/'], ['{"username":"', username, '","password":"', password, '"}']);
if statusCode == 200
    resp = loadjson(responseBody);
    token = resp.token;
else
    error(responseBody)
end
end

