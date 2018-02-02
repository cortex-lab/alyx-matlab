function outDatenum = datenum(date_time)
% DATENUM Returns a MATLAB datenum given a date_time string provided by Alyx
% 
% See also DATESTR
%
% Part of Alyx

% 2017 -- created

date_time = strrep(date_time, 'T', ' ');
date_time = strrep(date_time, 'Z', '');
outDatenum = datenum(date_time);