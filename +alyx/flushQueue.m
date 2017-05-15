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
            
            if statusCode(curr_file) >= 200 && statusCode(curr_file) <=300
                % If the upload was a success (code in the 200's)
                data(curr_file) = loadjson(responseBody);
                % delete the local queue entry
                delete(alyxQueueFiles{curr_file});
                disp(['Success uploading to Alyx: ' responseBody])
            else
                % If the upload failed (e.g. Alyx is down)
                error(['Status: ' int2str(statusCode(curr_file)) ' with response: ' responseBody])
            end
            
        catch me
            
            % If the JSON command failed (e.g. internet is down)
            warning(['JSON command failed - saved in queue']);
            
        end
        
    end

end