
function [alyxInstance, username] = loginWindowDev(presetUsername)
% function alyxInstance = loginWindowDev()
% Open a login window to get an alyx-dev token
% Returns empty if you click cancel.

loginSuccessful = false;
alyxInstance = [];
username = [];


while ~loginSuccessful
    


    if nargin < 1
        prompt = {'Alyx username:'};
        dlg_title = 'Alyx login';
        num_lines = 1;
        defaultans = {'',''};
        answer = inputdlg(prompt,dlg_title,num_lines,defaultans);

        if isempty(answer)
            % this happens if you click cancel
            return;
        end
    
        username = answer{1};
    elseif nargin > 0 
        username = presetUsername;
    end
    
    pwd = passwordUI();
    
    try
        alyxInstance = alyx.getToken('https://alyx-dev.cortexlab.net', username, pwd);
    catch
    end

    if ~isempty(alyxInstance)
        loginSuccessful = true;
    elseif isempty(strfind(lower(path),lower('missing-http')))
        error('missing-http toolbox not found. is it installed and on the path?')
    end
    
end
