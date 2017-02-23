

function alyxFigLaunch(mouseName, thisDate, varargin)

if isempty(varargin)

    % get Alyx credentials
    ai = alyx.loginWindow();

    if isempty(ai)
        % cancelled or failed login
        return;
    end

else
    ai = varargin{1};
end
    
% open the figure and place gui elements
alyxExpFig(mouseName, thisDate, ai); 

