
function alyxInstance = loginWindow()
% function alyxInstance = loginWindow()
% Open a login window to get an alyx token
% Returns empty if you click cancel.

loginSuccessful = false;
alyxInstance = [];

while ~loginSuccessful

    prompt = {'Alyx username:'};
    dlg_title = 'Alyx login';
    num_lines = 1;
    defaultans = {'',''};
    answer = inputdlg(prompt,dlg_title,num_lines,defaultans);

    if isempty(answer)
        % this happens if you click cancel
        return;
    end
    
    pwd = passwordUI();
    
    try
        alyxInstance = alyx.getToken([], answer{1}, pwd);
    catch
    end

    if ~isempty(alyxInstance)
        loginSuccessful = true;
    end
end
