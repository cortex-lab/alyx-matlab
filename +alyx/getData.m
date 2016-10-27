function [data, statusCode] = getData(baseURL, endpoint, token)
%getData GET any Alyx/REST read-only endpoint
%
% Description: Makes a request to an Alyx endpoint; returns the data as a
% MATLAB struct.
%
% Example:
% subjects = getData('http://alyx.cortexlab.net', 'subjects', token)
if isempty(baseURL)
    baseURL = 'http://alyx.cortexlab.net';
end

[statusCode, responseBody] = http.jsonGet([baseURL, '/', endpoint], 'Authorization', ['Token ' token]);
if statusCode == 200
    data = loadjson(responseBody);
else
    error(responseBody)
end

end

