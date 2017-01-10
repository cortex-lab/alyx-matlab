function [data, statusCode] = putData(alyxInstance, endpoint, data)
%postData PUT updated data to an Alyx/REST endpoint
%   
% Description: Makes a request to an Alyx endpoint with new data as a MATLAB struct;
% returns the JSON response data as a MATLAB struct.
% 
% Example:
% subjects = postData(alyxInstance, 'subjects/AR060/', myStructData)
    
    jsonData = savejson('', data);

    [statusCode, responseBody] = http.jsonPut([alyxInstance.baseURL, '/', endpoint], jsonData, 'Authorization', ['Token ' alyxInstance.token]);
    if statusCode >= 200 && statusCode <=300 % anything in the 200s is a Success code
        data = loadjson(responseBody);
    else
        error(['Status: ' int2str(statusCode) ' with response: ' responseBody])
    end

end
    