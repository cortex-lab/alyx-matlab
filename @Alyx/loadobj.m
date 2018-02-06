function obj = loadobj(obj_struct)
%LOADOBJ Load an Alyx object from a struct
%   Detailed explanation goes here
%
% See also SAVEOBJ, HLP_SERIALIZE
%
% Part of Alyx

% 2018 MW created

obj = Alyx();
obj.BaseURL = obj_struct.BaseURL;
obj.QueueDir = obj_struct.QueueDir;
obj.User = obj_struct.User;
obj.SessionURL = obj_struct.SessionURL;
obj.Token = obj_struct.Token;