function s = saveobj(obj)
%SAVEOBJ Return the instance of Alyx as a struct
%   Detailed explanation goes here
%
% See also LOADOBJ, HLP_DESERIALIZE
%
% Part of Alyx

% 2018 MW created

warning('off', 'MATLAB:structOnObject');
s = struct(obj);
warning('on', 'MATLAB:structOnObject');

end