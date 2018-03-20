function [data, statusCode] = flushQueue(obj)
% FLUSHQUEUE Checks for and uploads queued data to Alyx
%   Checks all .post and .put files in obj.QueueDir and tries to post/put
%   them to the database.  If the upload is successfull, the queued file is
%   deleted.  If an error is returned the queued file is also deleted,
%   unless it was a server error.
%
%   Status codes:
%     200: Upload success - delete from queue
%     300: Redirect - delete from queue
%     400: User error - delete from queue
%     403: Invalid token - delete from queue
%     500: Server error - save in queue
%
% See also ALYX, HTTP.JSONPOST, LOADJSON
%
% Part of Alyx

% 2017 -- created

% Get all currently queued posts/puts
alyxQueue = [dir([obj.QueueDir filesep '*.post']); dir([obj.QueueDir filesep '*.put'])];
alyxQueueFiles = sort(cellfun(@(x) fullfile(obj.QueueDir, x), {alyxQueue.name}, 'uni', false));

% Leave the function if there aren't any queued commands
if isempty(alyxQueueFiles); return; end

% Loop through all files, attempt to put/post
statusCode = ones(1,length(alyxQueueFiles))*401; % Initialize with user error code
data = cell(1,length(alyxQueueFiles));
for curr_file = 1:length(alyxQueueFiles)
  [~, ~, uploadType] = fileparts(alyxQueueFiles{curr_file});
  fid = fopen(alyxQueueFiles{curr_file});
  % First line is the endpoint
  endpoint = fgetl(fid);
  fullEndpoint = obj.makeEndpoint(endpoint);
  % Rest of the text is the JSON data
  jsonData = fscanf(fid,'%c');
  fclose(fid);
  
  try
    switch uploadType
      case '.post'
        [statusCode(curr_file), responseBody] = ...
          http.jsonPost(fullEndpoint, jsonData, 'Authorization', ['Token ' obj.Token]);
      case '.put'
        [statusCode(curr_file), responseBody] = ...
          http.jsonPut(fullEndpoint, jsonData, 'Authorization', ['Token ' obj.Token]);
    end
    
    switch floor(statusCode(curr_file)/100)
      case 2
        % Upload success - delete from queue
        data{curr_file} = loadjson(responseBody);
        delete(alyxQueueFiles{curr_file});
        disp([int2str(statusCode(curr_file)) ' Success, uploaded to Alyx: ' responseBody])
      case 3
        % Redirect - delete from queue
        data{curr_file} = loadjson(responseBody);
        delete(alyxQueueFiles{curr_file});
        disp([int2str(statusCode(curr_file)) ' Redirect, uploaded to Alyx: ' responseBody])
      case 4
        if statusCode(curr_file) == 403 % Invalid token
          obj.logout; % delete token
          if ~obj.Headless % if user can see dialog...
            obj.login; % prompt for login
            [data, statusCode] = obj.flushQueue; % Retry
          else % otherwise - save in queue
            warning([int2str(statusCode(curr_file)) ' Invalid token, saved in queue: ' responseBody])
          end
        else % User error - delete from queue
          data{curr_file} = loadjson(responseBody);
          delete(alyxQueueFiles{curr_file});
          warning([int2str(statusCode(curr_file)) ' Bad upload command: ' responseBody])
        end
      case 5
        % Server error - save in queue
        data{curr_file} = loadjson(responseBody);
        warning([int2str(statusCode(curr_file)) ' Alyx server error, saved in queue: ' responseBody])
    end
  catch
    % If the JSON command failed (e.g. internet is down)
    warning('Alyx:flushQueue:NotConnected', 'Alyx upload failed - saved in queue');
  end
  data = cellflat(data(~cellfun('isempty',data))); % Remove empty cells
  data = catStructs(data); % Convert cell array into struct
end

end