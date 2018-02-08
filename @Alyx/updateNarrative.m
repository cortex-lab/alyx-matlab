function narrative = updateNarrative(obj, comments, endpoint, subject)
%UPDATENARRATIVE Update an Alyx session or subject narrative
%   Update an Alyx narrative field with comments.  If an endpoint is
%   specified, the narrative for that record is updated, otherwise the last
%   subsession URL is used.  If the SessionURL property is empty and no
%   endpoint is specified, the narrative field of the subject's Alyx record
%   is updated.
%
%   NARRATIVE = UPDATENARRATIVE(OBJ)
%   If SessionURL is set, display comments dialog and post input to that
%   subsession narrative, otherwise it returns an error.
%
%   NARRATIVE = UPDATENARRATIVE(OBJ, COMMENTS)
%   If SessionURL is set, posts COMMENTS to that subsession narrative,
%   otherwise it returns an error. If COMMENTS is empty and not a charector
%   array, prompts user for input.
%
%   NARRATIVE = UPDATENARRATIVE(OBJ, COMMENTS, ENDPOINT)
%   Posts COMMENTS to ENDPOINT.  If COMMENTS is empty and not a charector
%   array, prompts user for input.
%
%   NARRATIVE = UPDATENARRATIVE(OBJ, COMMENTS, ENDPOINT, SUBJECT)
%   Posts COMMENTS to ENDPOINT narrative.  If ENDPOINT is empty, posts
%   COMMENTS to SUBJECT description.
%   
%   See also ALYX, DAT.UPDATELOGENTRY, EUI.EXPPANEL/SAVELOGENTRY, PUTDATA
%
% Part of Alyx

% 2018-02 MW created

% Validate inputs
if nargin < 2; comments = []; end
if nargin < 4; subject = []; end

% If no specific endpoint is specified, use the last created subsession
if nargin < 3
  if ~isempty(obj.SessionURL)
    endpoint = obj.SessionURL;
  else % Nothing to go on, throw error
    error('No endpoint specified and no subsession URL set');
  end
end

if isempty(comments) && ~isa(comments, 'char')
  if ~isempty(subject) && isempty(endpoint)
    titleStr = 'Update subject description';
  else
    titleStr = 'Update session narrative';
  end
  comments = inputdlg('Enter narrative:', titleStr, [10 60]);
end

if ~isempty(subject)
  % Assume post is intended for subject description
  warning('This feature is not yet implemented')
  return
  % TODO: retreive subject narrative endpoint, requires endpoint to allow
  % PUT requests and /subject=%s option.  NB: subject's 'narrative' field
  % is called 'description'
else
  % Remove trailing whitespaces, and ensure string is 1D.  Replace newlines
  % with escape charecters
  narrative = deblank(strrep(mat2DStrTo1D(comments), newline, '\n'));
  if iscell(narrative); narrative = narrative{:}; end % Make sure not a cell
  try
    session = obj.getData(endpoint); % Get subject name from endpoint (FIXME: subject is a required field)
    data = struct('subject', session.subject, 'narrative', narrative);
    data = obj.putData(endpoint, data); % Update the record
    if ~isempty(data.narrative); narrative = strrep(data.narrative, '\n', newline); end
  catch ex
    rethrow(ex)
  end
end