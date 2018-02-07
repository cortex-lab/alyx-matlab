function narrative = updateNarrative(obj, subject, comments, endpoint)
%UPDATENARRATIVE Update an Alyx session or subject narrative
%   narrative = UPDATENARRATIVE(obj, subject, comments[, endpoint])
%   Update an Alyx narrative field with comments.  If an endpoint is
%   specified, the narrative for that record is updated, otherwise the last
%   subsession URL is used.  If the SessionURL property is empty and no
%   endpoint is specified, the narrative field of the subject's Alyx record
%   is updated.
%
%   See also ALYX, DAT.UPDATELOGENTRY, EUI.EXPPANEL/SAVELOGENTRY, PUTDATA
%
% Part of Alyx

% 2018-02 MW created

% If no specific endpoint is specified, use the last created subsession
if nargin < 4
  if ~isempty(obj.SessionURL)
    endpoint = obj.SessionURL;
  else % Assume post is intended for subject narrative
    % TODO: retreive subject narrative endpoint
  end
end
% Remove trailing whitespaces, and ensure string is 1D.  Replace newlines
% with escape charecters
narrative = deblank(strrep(mat2DStrTo1D(comments), newline, '\n'));

data = struct('subject', subject, 'narrative', narrative);
data = obj.putData(endpoint, data);
if ~isempty(data)
  narrative = strrep(data.narrative, '\n', newline);
end