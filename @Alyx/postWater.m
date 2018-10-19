function wa = postWater(obj, mouseName, amount, thisDate, type, session)
%POSTWATER Post a water value to a given subject in Alyx
%   Post a specified amount of water (ml) to Alyx for mouseName on
%   thisDate.  
%
%   mouseName (char): subject name
%   amount (double): amount administered (ml)
%   thisDate (datestr|datenum): datetime of administration (default: now)
%   type (char): water type, e.g. 'Water' (default), 'Hydrogel', '15%
%                Sucrose', etc.
%   isSupplement (logical): whether the water was given during an
%   experiment or as a 'top-up' supplement (default)
%
%   On succsess, function returns a struct of the new water administration
%   record:
%    date_time: '2018-02-07T11:18:31Z'
%    type: 'Hydrogel'
%    subject: 'test'
%    url: 'https://alyx.cortexlab.net/water-administrations/245a5c9f-9807-44b3-b1d8-d038193859f9'
%    session: 'https://alyx.cortexlab.net/water-administrations/95h55c9f-6532-46k8-c0d8-587g3g43bgghd'
%    user: 'miles'
%    water_administered: 25
%
% See also ALYX, POSTDATA, POSTWEEKENDGEL
%
% Part of Alyx

% 2017 -- created

if nargin < 4; thisDate = now; end
if nargin < 5; type = 'Water'; end

% Validate date
if ~ischar(thisDate) %Assume MATLAB datenum
  % Convert to string in Alyx format-spec
  d.date_time = obj.datestr(thisDate);
else % Already in the correct format
  d.date_time = thisDate;
end
d.water_type = type;
if nargin == 6 && ~isempty(session)
  d.session = session; %TODO double check full url
end
if obj.IsLoggedIn; d.user = obj.User; end
d.subject = mouseName; % Subject name
d.water_administered = amount; % Units of mL

wa = obj.postData('water-administrations', d);