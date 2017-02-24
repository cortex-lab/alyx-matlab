function [data, statusCode] = getData(alyxInstance, endpoint)
%getData GET any Alyx/REST read-only endpoint
%
% Description: Makes a request to an Alyx endpoint; returns the data as a
% MATLAB struct.
%
% Example:
% subjects = getData(alyxInstance, 'subjects')

    fullEndpoint = alyx.makeEndpoint(alyxInstance, endpoint);        
        
    [statusCode, responseBody] = http.jsonGet(fullEndpoint, 'Authorization', ['Token ' alyxInstance.token]);
    if statusCode == 200
        data = loadjson(responseBody);
    else
        error(responseBody)
    end
end

