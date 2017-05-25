function [data,statusCode] = flushQueue(alyxInstance)
% [statusCode, responseBody] = flushQueue(alyxInstance) 
%   
% Description: checks for and uploads queued data to Alyx

    % Get all currently queued posts/puts
    queueDir = alyx.queueConfig;
    alyxQueue = [dir([queueDir filesep '*.post']);dir([queueDir filesep '*.put'])];
    alyxQueueFiles = sort(cellfun(@(x) fullfile(queueDir,x),{alyxQueue.name},'uni',false));
    
    % Leave the function if there aren't any queued commands
    if isempty(alyxQueueFiles)
        return
    end
    
    % Loop through all files, attempt to put/post
    for curr_file = 1:length(alyxQueueFiles)
        
        [~,~,uploadType] = fileparts(alyxQueueFiles{curr_file});
                
        fid = fopen(alyxQueueFiles{curr_file});
        % First line is the endpoint
        endpoint = fgetl(fid);
        fullEndpoint = alyx.makeEndpoint(alyxInstance, endpoint);
        % Rest of the text is the JSON data
        jsonData = fscanf(fid,'%c');
        fclose(fid);

        try
            
            switch uploadType
                case '.post'
                    [statusCode(curr_file), responseBody] = ...
                        http.jsonPost(fullEndpoint, jsonData, 'Authorization', ['Token ' alyxInstance.token]);
                case '.put'
                    [statusCode(curr_file), responseBody] = ...
                        http.jsonPut(fullEndpoint, jsonData, 'Authorization', ['Token ' alyxInstance.token]);
            end
            
            switch floor(statusCode(curr_file)/100)
                case 2
                    % Upload success - delete from queue
                    data(curr_file) = loadjson(responseBody);
                    delete(alyxQueueFiles{curr_file});
                    disp([int2str(statusCode(curr_file)) ' Success, uploaded to Alyx: ' responseBody])
                case 3
                    % Redirect - delete from queue
                    data(curr_file) = loadjson(responseBody);
                    delete(alyxQueueFiles{curr_file});
                    disp([int2str(statusCode(curr_file)) ' Redirect, uploaded to Alyx: ' responseBody])
                case 4 
                    % User error - delete from queue
                    data(curr_file) = loadjson(responseBody);
                    delete(alyxQueueFiles{curr_file});
                    warning([int2str(statusCode(curr_file)) ' Bad upload command: ' responseBody])
                case 5     
                    % Server error - save in queue
                    data(curr_file) = loadjson(responseBody);
                    warning([int2str(statusCode(curr_file)) ' Alyx server error, saved in queue: ' responseBody])
            end 
            
        catch me
            
            % If the JSON command failed (e.g. internet is down)
            warning(['Alyx upload failed - saved in queue']);
            
        end
        
    end

end