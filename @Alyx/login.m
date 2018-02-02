function login(obj, presetUsername)
%LOGINWINDOW UI for retrieving a token from Alyx
%   [alyxInstance, username] = obj.loginWindow(presetUsername)
%   Opens a login window to get an alyx token. Returns empty if you click
%   cancel.
%
% See also ALYX, GETTOKEN
%
% Part of Alyx

% 2017 -- created

while ~obj.IsLoggedIn
  if nargin < 2 % No preset username
    prompt = {'Alyx username:'};
    dlg_title = 'Alyx login';
    num_lines = 1;
    defaultans = {'',''};
    answer = inputdlg(prompt, dlg_title, num_lines, defaultans);
    
    if isempty(answer)
      % this happens if you click cancel
      return;
    end
    
    username = answer{1};
  else
    username = presetUsername;
  end
  
  pwd = passwordUI();
  
  try
    obj.getToken(username, pwd);
    %         alyxInstance = alyx.getToken('http://127.0.0.1:8000', username, pwd);
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
      else % onLoad not in path
        error(ex.identifier, ['Please locate ''onLoad'' (missing-http) function and add to MATLAB''s '...
          '<a href="matlab: opentoline(which(''startup.m''),1,1)">startup.m</a> file'])
      end
    else % Another error altogether
      rethrow(ex)
    end
  end
end
