
function dn = datenum(ds)
% function dn = datenum(ds)
% returns a MATLAB datenum given a date_time string provided by alyx

ds = strrep(ds, 'T', ' ');
ds = strrep(ds, 'Z', '');
dn = datenum(ds);