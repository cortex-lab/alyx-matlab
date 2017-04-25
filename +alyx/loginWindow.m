
function [alyxInstance, username] = loginWindow(presetUsername)
% function alyxInstance = loginWindow()
% Open a login window to get an alyx token
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
        alyxInstance = alyx.getToken([], username, pwd);
%         alyxInstance = alyx.getToken('http://127.0.0.1:8000', username, pwd);
    catch
    end

    if ~isempty(alyxInstance)
        loginSuccessful = true;
    end
end
