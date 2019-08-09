function wa = postWater(obj, subjectName, amount, thisDate, type, session)
%POSTWATER Posts a water value to a given subject in Alyx
% Posts a specified amount of water (ml) to Alyx for `subjectName` on
% `thisDate`, and returns a struct containing the corresponding water 
% administration record.  
%
% Inputs:
%   `subjectName`: A char of the subject's name
%   `amount`: A numeric of the amount of water administered (mL)
%   `thisDate`: A char (datestr) or numeric (datenum) of the time of the 
%     water administration. (default `now`)
%   `type`: A char of the water type. (default `'Water'`)
%   `session`: A char of the uuid (or url) of the session during which the
%     water was administered. An empty value indicates 'top-up' supplement.
%     (default `[]`)
%
% Outputs:
%   `wa`: A struct containing the new water administration record. This
%   struct has the following fields:
%     date_time: `thisDate`
%     type: `type`
%     subject: `subjectName`
%     url: A char of the Alyx database URL.
%     session: `session`
%     user: A char of the Alyx user who ran the water administration.
%     water_administered: `amount`
%
% Example: Record administration of 0.25 mL of water to 'test' subject:
%
%
%  TODO Verify date format correct
%
% See also Alyx, postData
%
% Part of alyx-matlab

% 2017 -- created

if nargin < 4; thisDate = now; end
if nargin < 5; type = 'Water'; end

% Validate amount
assert(~isempty(amount) && amount > 0, ...
  'Alyx:PostWeight:InvalidAmount', 'Amount must be positive')
% Validate date
if ~ischar(thisDate) %Assume MATLAB datenum
  % Convert to string in Alyx format-spec
  d.date_time = obj.datestr(thisDate);
else % Already in the correct format
  d.date_time = thisDate;
end
d.water_type = type;
if nargin == 6 && ~isempty(session)
  % Extract session uuid from url
  session = strip(session, '/');
  slashIdx = find(session=='/', 1, 'last');
  if slashIdx; session = session(slashIdx+1:end); end
  d.session = session;
end
if obj.IsLoggedIn; d.user = obj.User; end
d.subject = subjectName; % Subject name
d.water_administered = round(amount, 4, 'significant'); % Units of mL

wa = obj.postData('water-administrations', d);
