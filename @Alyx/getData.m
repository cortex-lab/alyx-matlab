function [data, statusCode] = getData(obj, endpoint)
%GETDATA Return a specific Alyx/REST read-only endpoint
%   Makes a request to an Alyx endpoint; returns the data as a MATLAB struct.
%
%   Examples:
%     subjects = obj.getData('sessions')
%     subjects = obj.getData('https://alyx.cortexlab.net/sessions')
%     subjects = obj.getData('sessions?type=Base')
%
% See also ALYX, MAKEENDPOINT, REGISTERFILE
%
% Part of Alyx

% 2017 PZH created

% Validate input If the endpoint url contains query name-value pairs,
% extract them
fullEndpoint = obj.makeEndpoint(endpoint); % Get complete URL

try
  data = webread(fullEndpoint, obj.WebOptions);
  statusCode = 200; % Success
  return
catch ex
  switch ex.identifier
    case 'MATLAB:webservices:UnknownHost'
      rethrow(ex)
    otherwise
      response = regexp(ex.message, '(?:the status )\d{3}', 'tokens');
      statusCode = str2double(response);
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