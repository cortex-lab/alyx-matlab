function outStr = datestr(inDatenum)
% DATESTR Convert a datenum to Alyx format-spec for posting
%   Converts a MATLAB datenum value into yyyy-mm-ddTHH:MM:SS, which is the
%   format specification for posting to the Alyx database.
%
% See also DATENUM
%
% Part of Alyx

% 2017 -- created

outStr = datestr(inDatenum, 'yyyy-mm-ddTHH:MM:SS');