function UDP_string = parseAlyxInstance(obj, expRef)
%PARSEALYXINSTANCE Converts input to string for UDP message and back
%   [UDP_string] = obj.parseAlyxInstance(expRef)
%
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
d = obj.saveobj;
d.expRef = expRef;
UDP_string = jsonencode(d);