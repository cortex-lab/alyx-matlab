
function colNames = myColNames(curs)
% function colNames = myColNames(curs)
% - curs is a database "cursor"
%
% The point of this function is that the built-in "columnnames" function
% returns a stupid comma-separated string, so this parses it. 

% built-in function gets the string
c = columnnames(curs);

% find all the things that have a word surrounded by single quotes
cn = regexp(c, '''\w*''', 'match');

% strip the single quotes
colNames = cellfun(@(x)x(2:end-1), cn, 'uni', false); 