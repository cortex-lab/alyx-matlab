function s = saveobj(obj)
%SAVEOBJ Return the instance of Alyx as a struct
%   SReturns an Alyx instance in the form of a struct with the same
%   fieldnames as the object's properties.
%
%   FIXME: This is a sub-optimal solution to the problem of serializing the
%   object for sending over Web sockets. Ideally this method should be
%   private.
%
% See also LOADOBJ, HLP_DESERIALIZE
%
% Part of Alyx

% 2018 MW created

% Ignore warnings about private attributes
warning('off', 'MATLAB:structOnObject');
% Turn object into struct
s = struct(obj);
% Remove weboptions object
s.WebOptions = [];
% Turn warnings back on
warning('on', 'MATLAB:structOnObject');
end