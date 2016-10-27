function [data, statusCode] = postData(baseURL, endpoint, token, data)
%postData POST any new data to an Alyx/REST endpoint
%   
% Description: Makes a request to an Alyx endpoint with new data as a MATLAB struct;
% returns the JSON response data as a MATLAB struct.
% 
% Example:
% subjects = postData('http://alyx.cortexlab.net', 'subjects', token, myStructData)

    if isempty(baseURL)
        baseURL = 'http://alyx.cortexlab.net';
    end
    

    jsonData = savejson(data);

    [statusCode, responseBody] = http.jsonPost([baseURL, '/', endpoint], jsonData, 'Authorization', ['Token ' token]);
    if statusCode >= 200 && statusCode <=300 % anything in the 200s is a Success code
        data = loadjson(responseBody);
    else
        error(['Status: ' int2str(statusCode) ' with response: ' responseBody])
    end

end
    