

function outStr = datestr(inDatenum)
% function outStr = datestr(inDatenum)
%
% convert a datenum to the format that alyx wants for posting
outStr = datestr(inDatenum, 'yyyy-mm-ddTHH:MM:SS');