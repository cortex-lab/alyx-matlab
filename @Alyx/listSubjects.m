function subjects = listSubjects(obj, stock, alive, sortByUser)
%ALYX.LISTSUBJECTS Lists recorded subjects
%   subjects = ALYX.LISTSUBJECTS([stock, alive, sortByUser]) Lists the
%   experimental subjects present in main repository.  If logged in,
%   returns a subject list generated from Alyx, with the option of
%   filtering by stock (default false) and alive (default true).  The
%   sortByUser flag, when (default) true, returns the list with the user's
%   animals at the top.  If not logged into Alyx, returns the alphabetized
%   directory names in the main repository.
%
% Part of Alyx

% 2013-03 CB created
% 2018-01 NS added alyx compatibility
% 2018-02 MW added to class

if nargin < 4; sortByUser = true; end
if nargin < 3; alive = true; end
if nargin < 2; stock = false; end

if obj.IsLoggedIn % user provided an alyx instance
  % convert bool to string for endpoint
  alive = iff(islogical(alive)&&alive, 'True', 'False');
  stock = iff(islogical(stock)&&stock, 'True', 'False');
  
  % get list of all living, non-stock mice from alyx
  s = obj.getData(sprintf('subjects?stock=%s&alive=%s', stock, alive));
  
  % return on empty
  if isempty(s); subjects = {'default'}; return; end
  
  % get cell array of subject names
  subjNames = {s.nickname};
  
  if sortByUser
    % determine the user for each mouse
    respUser = {s.responsible_user};
    
    % determine which subjects belong to this user
    thisUserSubs = sort(subjNames(strcmp(respUser, obj.User)));
    
    % all the subjects
    otherUserSubs = sort(subjNames(~strcmp(respUser, obj.User)));
    
    % the full, ordered list
    subjects = [{'default'}, thisUserSubs, otherUserSubs]';
  else
    subjects = [{'default'}, subjNames]';
  end
else
  % The remote 'main' repositories are the reference for the existence of
  % experiments, as given by the folder structure
  subjects = dat.listSubjects;
end
end