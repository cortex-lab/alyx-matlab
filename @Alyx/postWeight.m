function w = postWeight(obj, weight, subject, thisDate)
%POSTWEIGHT Post a subject's weight to Alyx.  If no inputs are provided,
% create an input dialog for the user to input a weight.  If no
% subject is provided, use this object's currently selected
% subject.
%
% On success, returns the new weight record as a struct:
%   date_time: '2018-02-07T11:21:14.628537Z'
%   subject: 'test'
%   url: 'https://alyx.cortexlab.net/weighings/c1b0a93d-fe40-449c-baf1-3305bfaae50f'
%   user: 'miles'
%   weighing_scale: []
%   weight: 20
%
% See also ALYX, EUI.ALYXPANEL, POSTDATA

% Validate weight
assert(~isempty(weight) && weight > 0, ...
  'Alyx:PostWeight:InvalidWeight', 'Weight must be positive')
if obj.IsLoggedIn; d.user = obj.User; end

% Validate date
if nargin < 4; thisDate = now; end
if ~ischar(thisDate) %Assume MATLAB datenum
  % Convert to string in Alyx format-spec
  d.date_time = obj.datestr(thisDate);
else % Already in the correct format
  d.date_time = thisDate;
end

d.subject = subject;
d.weight = round(weight, 4, 'significant');
w = postData(obj, 'weighings/', d);