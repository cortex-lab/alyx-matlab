function [alyxInstance] = getToken(baseURL, username, password)
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
    
    alyxInstance = struct('baseURL', baseURL, 'token', '');

    [statusCode, responseBody] = http.jsonPost([baseURL, '/auth-token/'], ['{"username":"', username, '","password":"', password, '"}']);
    if statusCode == 200
        
        resp = loadjson(responseBody);
        alyxInstance.token = resp.token;
        alyxInstance.username = username;
        
        % Flush the local queue on successful login
        alyx.flushQueue(alyxInstance);
        
    else
        error(responseBody)
    end
end

