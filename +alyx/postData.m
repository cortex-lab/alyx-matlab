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
% subjects = postData(alyxInstance, 'subjects/', myStructData)

    % Create the JSON command
    jsonData = savejson('', data);
   
    % Make a filename for the current command
    queueDir = alyx.queueConfig;
    queueFilename = [datestr(now,'dd-mm-yyyy-HH-MM-SS-FFF') '.post'];
    queueFullfile = fullfile(queueDir,queueFilename);

    % Save the endpoint and json locally
    fid = fopen(queueFullfile,'w');
    fprintf(fid,'%s\n%s',endpoint,jsonData);
    fclose(fid);
    
    % Flush the queue
    if ~isempty(alyxInstance)
        [data, statusCode] = alyx.flushQueue(alyxInstance);
    else
        warning(['Not connected to Alyx - saved in queue']);
    end
    
end
    