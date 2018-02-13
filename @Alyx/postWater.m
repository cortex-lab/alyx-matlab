function wa = postWater(obj, mouseName, amount, thisDate, isHydrogel)
%POSTWATER Post a water value to a given subject in Alyx
%   Post a specified amount of water (ml) to Alyx for mouseName on
%   thisDate.  isHydrogel is a boolean.
%
%   On succsess, function returns a struct of the new water administration
%   record:
%    date_time: '2018-02-07T11:18:31Z'
%    hydrogel: 1
%    subject: 'test'
%    url: 'https://alyx.cortexlab.net/water-administrations/245a5c9f-9807-44b3-b1d8-d038193859f9'
%    user: 'miles'
%    water_administered: 25
%
% See also ALYX, POSTDATA, POSTWEEKENDGEL
%
% Part of Alyx

% 2017 -- created

if nargin < 4; thisDate = now; end
if nargin < 5; isHydrogel = true; end

% Validate date
if ~ischar(thisDate) %Assume MATLAB datenum
  % Convert to string in Alyx format-spec
  d.date_time = obj.datestr(thisDate);
else % Already in the correct format
  d.date_time = thisDate;
end
d.hydrogel = isHydrogel;
if obj.IsLoggedIn; d.user = obj.User; end
d.subject = mouseName; % Subject name
d.water_administered = amount; % Units of mL

wa = obj.postData('water-administrations', d);