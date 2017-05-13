function queueDir = queueConfig
% queueDir = queueConfig
% 
% Set the local directory for saving queued Alyx commands, create if needed

if ispc
    queueDir = 'C:\localAlyxQueue';
elseif ismac
    error('queue directory needs to be defined for macs')
    queueDir = '';
elseif isunix
    error('queue directory needs to be defined for linux')
    queueDir = '';
end

if ~exist(queueDir,'dir')
    mkdir(queueDir)
end

end
    