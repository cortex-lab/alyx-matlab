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
  
  % get cell array of subject names
  subjNames = cellfun(@(x)x.nickname, s, 'uni', false);
  
  if sortByUser
    % determine the user for each mouse
    respUser = cellfun(@(x)x.responsible_user, s, 'uni', false);
    
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
  % The master 'expInfo' repository is the reference for the existence of
  % experiments, as given by the folder structure
  expInfoPath = dat.reposPath('main', 'master');
  
  dirs = file.list(expInfoPath, 'dirs');
  subjects = setdiff(dirs, {'@Recently-Snapshot', '@Recycle'}); %exclude the trash directories
end
end