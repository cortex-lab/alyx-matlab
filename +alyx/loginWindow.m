
function [alyxInstance, username] = loginWindow(presetUsername)
%LOGINWINDOW UI for retrieving a token from Alyx
%   [alyxInstance, username] = loginWindow(presetUsername)
%   Opens a login window to get an alyx token. Returns empty if you click
%   cancel.
%
% See Also ALYX.GETTOKEN

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
        loginSuccessful = true;
    catch ex
      products = ver;
      toolboxes = matlab.addons.toolbox.installedToolboxes;
      % Check the correct toolboxes are installed
      if ~any(contains({products.Name},'JSONlab'))&&...
          ~any(contains({toolboxes.Name},'JSONlab'))&&contains(ex.message, 'loadjson')
        % JSONlab not installed
        error(ex.identifier, 'JSONLab Toolbox required.  Click <a href="matlab:web(''%s'',''-browser'')">here</a> to install.',...
          'https://uk.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files')
      elseif ~any(strcmp({products.Name}, 'missing-http'))
        % missing-http not installed
        error(ex.identifier, 'missing-http required.  Click <a href="matlab:web(''%s'',''-browser'')">here</a> to install.',...
          'https://github.com/psexton/missing-http/releases')
      elseif contains(ex.message, 'psexton')
        % onLoad not run
        if ~isempty(which('onLoad'))
          onLoad
          warning('Please add ''onLoad'' to MATLAB''s <a href="matlab: opentoline(which(''startup.m''),1,1)">startup.m</a> file')
          loginSuccessful = true;
        else % onLoad not in path
          error(ex.identifier, ['Please locate ''onLoad'' (missing-http) function and add to MATLAB''s '...
            '<a href="matlab: opentoline(which(''startup.m''),1,1)">startup.m</a> file'])
        end
      else % Another error altogether
        rethrow(ex)
      end
    end
end
