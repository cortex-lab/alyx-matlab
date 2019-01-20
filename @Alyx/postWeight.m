function w = postWeight(obj, weight, subject)
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

% Validate amount
assert(weight > 0, 'Weight must be positive')
if obj.IsLoggedIn; d.user = obj.User; end
d.subject = subject;
d.weight = weight;
w = postData(obj, 'weighings/', d);
