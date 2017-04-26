function [data, statusCode] = postData(alyxInstance, endpoint, data)
%postData POST any new data to an Alyx/REST endpoint
%
% Description: Makes a request to an Alyx endpoint with new data as a MATLAB struct;
% returns the JSON response data as a MATLAB struct.
%
% This function will create a new record. If you would
% like to overwrite data in an existing record, see putData instead.
%
% Example:
% subjects = postData(alyxInstance, 'subjects', myStructData)

    jsonData = savejson('', data);

    fullEndpoint = alyx.makeEndpoint(alyxInstance, endpoint);

    [statusCode, responseBody] = http.jsonPost(fullEndpoint, jsonData, 'Authorization', ['Token ' alyxInstance.token]);
    if statusCode >= 200 && statusCode <=300 % anything in the 200s is a Success code
        data = loadjson(responseBody);
    else
        error(['Status: ' int2str(statusCode) ' with response: ' responseBody])
    end

end
