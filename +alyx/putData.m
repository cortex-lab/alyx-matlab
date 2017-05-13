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

    % Create the JSON command
    jsonData = savejson('', data);
   
    % Make a filename for the current command
    queueDir = alyx.queueConfig;
    queueFilename = [datestr(now,'dd-mm-yyyy-HH-MM-SS-FFF') '.put'];
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
