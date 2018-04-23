function [ref, AlyxInstance] = parseAlyxInstance(varargin)
%PARSEALYXINSTANCE Converts input to string for UDP message and back
%   [UDP_string] = DATA.PARSEALYXINSTANCE(ref, AlyxInstance)
%   [ref, AlyxInstance] = DATA.PARSEALYXINSTANCE(UDP_string)
%   
%   AlyxInstance should be an Alyx object.
%
% See also SAVEOBJ, LOADOBJ
%
% Part of Alyx

% 2017-10 MW created

if nargin > 1 % in [ref, AlyxInstance]
  ref = varargin{1}; % extract expRef
  ai = varargin{2}; % extract AlyxInstance struct
  if isa(ai, 'Alyx') % if there is an AlyxInstance
    d = ai.saveobj;
  end
  d.expRef = ref; % Add expRef field
  ref = jsonencode(d); % Convert to JSON string
else % in [UDP_string]
    s = jsondecode(varargin{1}); % Convert JSON to structure
    ref = s.expRef; % Extract the expRef
    AlyxInstance = Alyx('',''); % Create empty Alyx object
    if numel(fieldnames(s)) > 1 % Assume to be Alyx object as struct
      AlyxInstance = AlyxInstance.loadobj(s); % Turn into object
    end
end