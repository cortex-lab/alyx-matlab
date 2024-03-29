function obj = login(obj, presetUsername, presetPassword)
%LOGINWINDOW UI for retrieving a token from Alyx
%   obj = obj.login(presetUsername, presetPassword) Opens a login window to
%   get an alyx token. Returns empty if you click cancel.  When called
%   without one or both input arguments a dialog is created for the user to
%   input them.
%
% See also ALYX, GETTOKEN
%
% Part of Alyx

% 2017 -- created

if nargin ~= 3 && obj.Headless % Don't prompt user if headless flag set
  warning('Alyx:HeadlessLoginFail','Unable to log in; dialogs supressed')
  return
end

noDisplay = usejava('jvm') && ~feature('ShowFigureWindows');
while ~obj.IsLoggedIn
  if nargin < 2 || isempty(presetUsername) % no preset user
    prompt = {'Alyx username:'};
    if noDisplay
      % use text-based alternative
      answer = strip(input([prompt{:} ' '], 's'));
    else
      % use GUI dialog
      dlg_title = 'Alyx login';
      num_lines = 1;
      defaultans = {'',''};
      answer = newid(prompt, dlg_title, num_lines, defaultans);
    end
    
    if isempty(answer)
      % this happens if you click cancel
      return;
    end
    
    if iscell(answer) % true if using newid
      username = answer{1};
    else
      username = answer;
    end
  else
    username = presetUsername;
  end
  
  if nargin < 3 || isempty(presetPassword)
    if noDisplay
      diaryState = get(0, 'Diary');
      diary('off'); % At minimum we can keep out of dairy log file
      pwd = input('Alyx password <strong>**INSECURE**</strong>: ', 's');
      diary(diaryState);
    else
      pwd = passwordUI();
    end
  else
    pwd = presetPassword;
  end
  
  try
    obj = obj.getToken(username, pwd);
  catch ex
    products = ver;
    toolboxes = matlab.addons.toolbox.installedToolboxes;
    % Check the correct toolboxes are installed
    if numel(toolboxes) == 0 || (~any(contains({products.Name},'JSONlab')) &&...
        ~any(contains({toolboxes.Name},'JSONlab')) && contains(ex.message, 'loadjson'))
      % JSONlab not installed
      error(ex.identifier, 'JSONLab Toolbox required.  Click <a href="matlab:web(''%s'',''-browser'')">here</a> to install.',...
        'https://uk.mathworks.com/matlabcentral/fileexchange/33381-jsonlab--a-toolbox-to-encode-decode-json-files')
    elseif strcmp(ex.identifier, 'Alyx:Login:FailedToConnect')
       obj.Headless = true;
       break
    elseif contains(ex.message, 'credentials')||strcmpi(ex.message, 'Bad Request')
      if obj.Headless == true
        warning('Alyx:LoginFail:BadCredentials', 'Unable to log in with provided credentials.')
        return
      else
        disp('Unable to log in with provided credentials.')
        presetPassword = [];
      end
    elseif contains(ex.message, 'password')&&contains(ex.message, 'blank')
      disp('Password may not be left blank')
    else % Another error altogether
      rethrow(ex)
    end
  end
end
