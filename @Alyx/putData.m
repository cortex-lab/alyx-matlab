function [data, statusCode] = putData(obj, endpoint, data)
%PUTDATA Put an updated data record to an Alyx/REST endpoint
%   Makes a request to an Alyx endpoint with new data as a MATLAB struct;
%   returns the JSON response data as a MATLAB struct.
%
%   This function will overwrite data of an existing record. If you would
%   like to create a new record, see postData instead.
%
%   Example:
%     subjects = obj.putData('subjects/AR060/', myStructData)
%
% See also ALYX, POSTDATA, SAVEJSON
%
% Part of Alyx

% 2017 -- created

% Create the JSON command
jsonData = savejson('', data);

% Make a filename for the current command
queueFilename = [datestr(now, 'dd-mm-yyyy-HH-MM-SS-FFF') '.put'];
queueFullfile = fullfile(obj.QueueDir, queueFilename);

% Save the endpoint and JSON locally
fid = fopen(queueFullfile, 'w');
fprintf(fid, '%s\n%s', endpoint, jsonData);
fclose(fid);

% Flush the queue if logged in
if obj.IsLoggedIn
  [data, statusCode] = obj.flushQueue();
else
  warning('Not connected to Alyx - saved in queue');
end

end
