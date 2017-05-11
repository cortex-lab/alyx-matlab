function [data,statusCode] = flushQueue(alyxInstance)
% [statusCode, responseBody] = flushQueue(alyxInstance) 
%   
% Description: checks for and puts/posts queued data to Alyx

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
        fullEndpoint = fgetl(fid);
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
        catch me
            error(['JSON command failed'])
        end
        
        if statusCode(curr_file) >= 200 && statusCode(curr_file) <=300 % anything in the 200s is a Success code
            data(curr_file) = loadjson(responseBody);
            % delete the local queue entry
            delete(alyxQueueFiles{curr_file});
        else
            error(['Status: ' int2str(statusCode(curr_file)) ' with response: ' responseBody])
        end  
        
    end

end