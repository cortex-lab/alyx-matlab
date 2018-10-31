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
% See also ALYX, ALYX.JSONPOST
%
% Part of Alyx

% 2017 -- created

% Get all currently queued posts, puts, etc.
alyxQueue = [dir([obj.QueueDir filesep '*.post']);...
  dir([obj.QueueDir filesep '*.put']);...
  dir([obj.QueueDir filesep '*.patch'])];
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
  % Rest of the text is the JSON data
  jsonData = fscanf(fid,'%c');
  fclose(fid);
  
  try
    [statusCode(curr_file), responseBody] = obj.jsonPost(endpoint, jsonData, uploadType(2:end));
%     [statusCode(curr_file), responseBody] = http.jsonPost(obj.makeEndpoint(endpoint), jsonData, 'Authorization', ['Token ' obj.Token]);
    switch floor(statusCode(curr_file)/100)
      case 2
        % Upload success - delete from queue
        data{curr_file} = responseBody;
        delete(alyxQueueFiles{curr_file});
        disp([int2str(statusCode(curr_file)) ' Success, uploaded to Alyx: ' jsonData])
      case 3
        % Redirect - delete from queue
        data{curr_file} = responseBody;
        delete(alyxQueueFiles{curr_file});
        disp([int2str(statusCode(curr_file)) ' Redirect, uploaded to Alyx: ' jsonData])
      case 4
        if statusCode(curr_file) == 403 % Invalid token
          obj.logout; % delete token
          if ~obj.Headless % if user can see dialog...
            obj.login; % prompt for login
            [data, statusCode] = obj.flushQueue; % Retry
          else % otherwise - save in queue
            warning('Alyx:flushQueue:InvalidToken', '%s (%i): %s saved in queue',...
              responseBody, statusCode(curr_file), alyxQueue(curr_file).name)
          end
        else % User error - delete from queue
          delete(alyxQueueFiles{curr_file});
          warning('Alyx:flushQueue:BadUploadCommand', '%s (%i): %s',...
            responseBody, statusCode(curr_file), alyxQueue(curr_file).name)
        end
      case 5
        % Server error - save in queue
        warning('Alyx:flushQueue:InternalServerError', '%s (%i): %s saved in queue',...
          responseBody, statusCode(curr_file), alyxQueue(curr_file).name)
    end
  catch ex
      if strcmp(ex.identifier, 'MATLAB:weboptions:unrecognizedStringChoice')
          warning('Alyx:flushQueue:MethodNotSupported',...
              '%s method not supported', upper(uploadType(2:end)));
      else
          % If the JSON command failed (e.g. internet is down)
          warning('Alyx:flushQueue:NotConnected', 'Alyx upload failed - saved in queue');
      end
  end
end
data = cellflat(data(~cellfun('isempty',data))); % Remove empty cells
data = catStructs(data); % Convert cell array into struct
end