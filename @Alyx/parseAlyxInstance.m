function UDP_string = parseAlyxInstance(obj, expRef)
%PARSEALYXINSTANCE Converts input to string for UDP message and back
%   The pattern for 'expRef' should be '{date}_{seq#}_{subject}', with two
%   date formats accepted, either 'yyyy-mm-dd' or 'yyyymmdd'.
%
%   AlyxInstance should an Alyx object that is currently logged in, i.e.
%   with the following properties set: 'BaseURL', 'Token', 'User'[,
%   'SessionURL'].
%
% Part of Alyx

% 2017-10 MW created

if nargin < 2; expRef = []; end
d.expRef = expRef;
d.baseURL = obj.BaseURL;
d.token = obj.Token;
d.username = obj.User;
d.sessionURL = obj.SessionURL;
UDP_string = jsonencode(d);
