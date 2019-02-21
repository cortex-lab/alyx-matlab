function [data, statusCode] = postData(obj, endpoint, data, requestMethod)
%POSTDATA Post any new data to an Alyx/REST endpoint
%   Description: Makes a request to an Alyx endpoint with new data as a
%   MATLAB struct; returns the JSON response data as a MATLAB struct.
%
%   This function will create a new record by default, if requestMethod is
%   undefined. Other methods include 'PUT', 'PATCH and 'DELETE'.
%
%   Example:
%     subjects = obj.postData('subjects', myStructData, 'post')
%
% See also ALYX, JSONPOST, FLUSHQUEUE, REGISTERFILE, GETDATA
%
% Part of Alyx

% 2017 -- created

% Validate inputs
if nargin == 3; requestMethod = 'post'; end % Default request method
assert(any(strcmpi(requestMethod, {'post', 'put', 'patch', 'delete'})),...
  '%s not a valid HTTP request method', requestMethod)

% Create the JSON command
jsonData = jsonencode(data);

% Make a filename for the current command
queueFilename = [datestr(now, 'yyyy-mm-dd-HH-MM-SS-FFF') '.' lower(requestMethod)];
queueFullfile = fullfile(obj.QueueDir, queueFilename);
% If local Alyx queue directory doesn't exist, create one
if ~exist(obj.QueueDir, 'dir'); mkdir(obj.QueueDir); end

% Save the endpoint and json locally
fid = fopen(queueFullfile, 'w');
fprintf(fid, '%s\n%s', endpoint, jsonData);
fclose(fid);

% Flush the queue
if obj.IsLoggedIn
  [data, statusCode] = obj.flushQueue();
  % Return only relevent data
  if numel(statusCode) > 1; statusCode = statusCode(end); end
  if floor(statusCode/100) == 2 && ~isempty(data)
    data = data(end);
  end
else
  statusCode = 000;
  data = [];
  warning('Alyx:flushQueue:NotConnected','Not connected to Alyx - saved in queue');
end

end