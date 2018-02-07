function obj = loadobj(obj_struct)
%LOADOBJ Load an Alyx object from a struct
%   Loads an Alyx instance from a struct with the same fieldnames as the
%   object's properties.  
%
%   FIXME: This is a sub-optimal solution to the problem of serializing the
%   object for sending over Web sockets. Ideally this method should be
%   private.
%
% See also SAVEOBJ, HLP_SERIALIZE
%
% Part of Alyx

% 2018 MW created

% Create new object
obj = Alyx();
% Set all the relevant attributes
obj.BaseURL = obj_struct.BaseURL;
obj.QueueDir = obj_struct.QueueDir;
obj.User = obj_struct.User;
obj.SessionURL = obj_struct.SessionURL;
obj.Token = obj_struct.Token;