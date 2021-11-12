function [statusCode, responseBody] = jsonPost(obj, endpoint, jsonData, requestMethod)
%JSONPOST Makes POST, PUT and PATCH requests to endpoint with a JSON request body
% Makes a POST request, with a JSON request body (`Content-Type: application/json`), 
% and asking for a JSON response (`Accept: application/json`).
%   
% Inputs:
%   endpoint      - REST API endpoint to make the request to
%   requestBody   - String to use as request body
%   requestMethod - String indicating HTTP request method, i.e. 'POST'
%                   (default), 'PUT', 'PATCH' or 'DELETE'
%
% Output:
%   statusCode - Integer response code
%   responseBody - String response body or data struct
%
% See also JSONGET, JSONPUT, JSONPATCH

% Validate the inputs
endpoint = obj.makeEndpoint(endpoint); % Ensure absolute URL
if nargin == 3; requestMethod = 'post'; end % Default request method
assert(any(strcmpi(requestMethod, {'post', 'put', 'patch', 'delete'})),...
  '%s not a valid HTTP request method', requestMethod)
% Set the HTTP request method in options
options = obj.WebOptions;
options.RequestMethod = lower(requestMethod);

try % Post data
  responseBody = webwrite(endpoint, jsonData, options);
  statusCode = iff(endsWith(endpoint,'auth-token'), 200, 201);
catch ex
  responseBody = ex.message;
  switch ex.identifier
    case 'MATLAB:webservices:UnknownHost'
      % Can't resolve URL
      warning(ex.identifier, '%s Posting temporarily supressed', ex.message)
      statusCode = 000;
    case {'MATLAB:webservices:CopyContentToDataStreamError'
        'MATLAB:webservices:SSLConnectionFailure'
        'MATLAB:webservices:Timeout'}
      % Connection refused or timed out, set as headless and continue on
      warning(ex.identifier, '%s. Posting temporarily supressed', ex.message)
      statusCode = 000;
    otherwise
      response = regexp(ex.message, '(?:the status )(?<status>\d{3}).*"(?<message>.+)"', 'names');
      if len(response)
        statusCode = str2double(response.status);
        responseBody = response.message;
      else
        statusCode = 000;
        responseBody = ex.message;
      end
  end
end
end