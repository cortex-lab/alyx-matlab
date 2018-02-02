function wa = postWater(obj, mouseName, amount, thisDate, isHydrogel)
%POSTWATER Post a water value to a given subject in Alyx
%   Post a specified amount of water (ml) to Alyx for mouseName on
%   thisDate.  isHydrogel is a boolean.
%
%   TODO: Explain what 'wa' is
%
% See also ALYX, POSTDATA, POSTWEEKENDGEL
%
% Part of Alyx

% 2017 -- created

% Validate date
if ~ischar(thisDate) %Assume MATLAB datenum
  % Convert to string in Alyx format-spec
  d.date_time = obj.datestr(thisDate);
else % Already in the correct format
  d.date_time = thisDate;
end
d.hydrogel = isHydrogel;
d.user = obj.User;
d.subject = mouseName; % Subject name
d.water_administered = amount; % Units of mL

wa = obj.postData('water-administrations', d);
