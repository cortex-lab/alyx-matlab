function outStr = datestr(inDatenum)
% DATESTR Convert a datenum to Alyx format-spec for posting
%   Converts a MATLAB datenum value into yyyy-mm-ddTHH:MM:SS, which is the
%   format specification for posting to the Alyx database.
%
%   Example:
%    outStr = Alyx.datenum(7.3710e+05)
%    outStr =
%      '2018-02-07T11:21:14.628537Z'
%
% See also DATENUM
%
% Part of Alyx

% 2017 -- created
if nargin < 1; inDatenum = now; end
outStr = datestr(inDatenum, 'yyyy-mm-ddTHH:MM:SS');