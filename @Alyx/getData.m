function [data, statusCode] = getData(obj, endpoint)
%GETDATA Return a specific Alyx/REST read-only endpoint
%   Makes a request to an Alyx endpoint; returns the data as a MATLAB struct.
%
%   Examples:
%     sessions = obj.getData('sessions')
%     sessions = obj.getData('https://alyx.cortexlab.net/sessions')
%     sessions = obj.getData('sessions?type=Base')
%
% See also ALYX, MAKEENDPOINT, REGISTERFILE
%
% Part of Alyx

% 2017 PZH created

% Validate input If the endpoint url contains query name-value pairs,
% extract them
data = [];
fullEndpoint = obj.makeEndpoint(endpoint); % Get complete URL
if ~obj.IsLoggedIn; obj = obj.login; end % Log in if necessary
try
  data = webread(fullEndpoint, obj.WebOptions);
  statusCode = 200; % Success
  return
catch ex
  switch ex.identifier
    case {'MATLAB:webservices:UnknownHost', 'MATLAB:webservices:Timeout', ...
        'MATLAB:webservices:CopyContentToDataStreamError'}
      warning(ex.identifier, '%s', ex.message)
      statusCode = 000;
    otherwise
      response = regexp(ex.message, '(?:the status )(\d{3})', 'tokens');
      statusCode = str2double(cellflat(response));
      if statusCode == 403 % Invalid token
        warning('Alyx:getData:InvalidToken', 'Invalid token, please re-login')
        obj = obj.logout; % Delete token
        if ~obj.Headless % Prompts not supressed
          obj = obj.login; % Re-login
          data = obj.getData(fullEndpoint); % Retry
        end
      else
        rethrow(ex)
      end
  end
end
end