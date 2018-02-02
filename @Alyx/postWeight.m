function w = postWeight(obj, weight, subject)
%POSTWEIGHT Post a subject's weight to Alyx.  If no inputs are provided,
% create an input dialog for the user to input a weight.  If no
% subject is provided, use this object's currently selected
% subject.
%
% TODO: Explain 'w' variable
%
% See also ALYX, EUI.ALYXPANEL, POSTDATA

d.subject = subject;
d.weight = weight;
u = postData(obj, 'weighings/', d);
w  = 1;