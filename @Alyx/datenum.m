function outDatenum = datenum(date_time)
% DATENUM Returns a MATLAB datenum given a date_time string provided by Alyx
%   Example:
%    outDateNum = Alyx.datenum('2018-02-07T11:21:14.628537Z')
%    outDateNum =
%      7.3710e+05
%
% See also DATESTR
%
% Part of Alyx

% 2017 -- created
date_time = strrep(date_time, 'T', ' ');
date_time = strrep(date_time, 'Z', '');
outDatenum = datenum(date_time);