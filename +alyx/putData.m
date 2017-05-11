function [data, statusCode] = putData(alyxInstance, endpoint, data)
%postData PUT updated data to an Alyx/REST endpoint
%   
% Description: Makes a request to an Alyx endpoint with new data as a MATLAB struct;
% returns the JSON response data as a MATLAB struct.
%
% This function will overwrite data of an existing record. If you would
% like to create a new record, see postData instead. 
% 
% Example:
% subjects = putData(alyxInstance, 'subjects/AR060/', myStructData)

    % Create the endpoint and json command for the current put    
    fullEndpoint = alyx.makeEndpoint(alyxInstance, endpoint);
    jsonData = savejson('', data);
   
    % Make a filename for the current put
    queueDir = alyx.queueConfig;
    queueFilename = [datestr(now,'dd-mm-yyyy-HH-MM-SS-FFF') '.put'];
    queueFullfile = fullfile(queueDir,queueFilename);

    % Save the endpoint and json locally
    fid = fopen(queueFullfile,'w');
    fprintf(fid,'%s\n%s',fullEndpoint,jsonData);
    fclose(fid);
        
    % Flush the queue
    [data, statusCode] = alyx.flushQueue(alyxInstance);

end
    