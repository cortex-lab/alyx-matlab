function [fullpath, filename] = block2ALF(data, overwrite)
% ALF.BLOCK2ALF Extracts and saves ALF data from a block structure
%  If overwrite is true, any existing ALF files will be overwritten.
%  For more info on the dataset type, visit
%  https://docs.google.com/spreadsheets/d/1DqyQ-Ho4eObR0B4nZMQz397TAUReaef-9dRWKwIa3JM0
%
%  TODO: Cut down redundency in code
%  TODO: Write extra rewards ALF when present

if nargin < 2; overwrite = false; end

expPath = dat.expPath(data.expRef, 'main', 'master');
expDef = getOr(data, {'expDef' 'expType'});
namespace = iff(endsWith(expDef, 'ibl.m'), '_ibl_', '_misc_');
iff(strcmp(expDef, 'ChoiceWorld'), @()extractChoiceWorld(data), @()extractSignals(data));

% Collate paths
files = dir(expPath);
% Contruct paths
ALFnames = {...
  'trials.feedbackType.npy',...
  'trials.feedback_times.npy',...
  'trials.rewardVolume.npy',...
  'trials.goCue_times.npy',...
  'trials.choice.npy',...
  'trials.response_times.npy',...
  'trials.stimOn_times.npy',...
  'trials.contrastLeft.npy',...
  'trials.contrastRight.npy',...
  'trials.probabilityLeft.npy',...
  'trials.intervals.npy',...
  'trials.included.npy',...
  'trials.repNum.npy',...
  'wheel.position.npy',...
  'wheel.velocity.npy',...
  'wheel.timestamps.npy',...
  'wheelMoves.type.csv',...
  'wheelMoves.intervals.npy'};
incl = cellfun(@(f)endsWith(f, ALFnames), {files.name});
files = files(incl);
fullpath = fullfile({files.folder}, {files.name});
filename = {files.name};

  function extractSignals(data)
    % EXTRACTSIGNALS Extract ALF files from a Signals block file.
    if ~isfield(data,'events')||length(data.events.newTrialValues)<20||endsWith(expDef,'habituationWorld.m')
      return
    end
    
    expStartTime = data.events.expStartTimes; % CW: data.experimentStartedTime
    evts = removeIncompleteTrials(data.events, length(data.events.endTrialTimes));
    data.outputs.rewardValues(data.outputs.rewardTimes>evts.endTrialTimes(end)) = [];
    % Write feedback
    if ~exist(fullfile(expPath, [namespace 'trials.feedbackType.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.feedback_times.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.rewardVolume.npy']), 'file') || ...
        overwrite == true
      feedback = getOr(evts, 'feedbackValues', NaN);
      feedback = double(feedback);
      feedback(feedback == 0) = -1;
      if ~isnan(feedback)
        writeNPY(int8(feedback(:)), fullfile(expPath, [namespace 'trials.feedbackType.npy']));
        alf.writeEventseries(expPath, [namespace 'trials.feedback'],...
          evts.feedbackTimes - expStartTime, [], []);
        rewardValues = feedback;
        rewardValues(feedback==1) = data.outputs.rewardValues;
        rewardValues(feedback==-1) = 0;
        writeNPY(rewardValues(:), ...
          fullfile(expPath, [namespace 'trials.rewardVolume.npy']));
      else
        warning('No ''feedback'' events recorded, cannot register to Alyx')
      end
    end
    
    % Write go cue
    interactiveOn = getOr(evts, 'interactiveOnTimes', NaN);
    interactiveOn = interactiveOn - expStartTime;
    if ~exist(fullfile(expPath, [namespace 'trials.goCue_times.npy']), 'file') || overwrite == true
      if ~isnan(interactiveOn)
        alf.writeEventseries(expPath, [namespace 'trials.goCue'], interactiveOn, [], []);
      else
        warning('No ''interactiveOn'' events recorded, cannot register to Alyx')
      end
    end
    
    % Write response
    response = getOr(evts, 'responseValues', NaN);
    if max(response) == 3
      response(response == 3) = 0; % No go
      response(response == 2) = -1; % CCW
    else
      response = -sign(response); % -ve now means CCW
    end
    responseTimes = evts.responseTimes - expStartTime;
    
    if ~exist(fullfile(expPath, [namespace 'trials.choice.npy']), 'file') || overwrite == true
      if ~isnan(response)
        writeNPY(int8(response(:)), fullfile(expPath, [namespace 'trials.choice.npy']));
        alf.writeEventseries(expPath, [namespace 'trials.response'],...
          responseTimes, [], []);
      else
        warning('No ''feedback'' events recorded, cannot register to Alyx')
      end
    end
    
    % Write stim on times
    if ~exist(fullfile(expPath, [namespace 'trials.stimOn_times.npy']), 'file') || overwrite == true
      stimOnTimes = getOr(evts, 'stimulusOnTimes', NaN);
      if ~isnan(stimOnTimes)
        stimOnTimes = stimOnTimes - expStartTime;
        alf.writeEventseries(expPath, [namespace 'trials.stimOn'], stimOnTimes, [], []);
      else
        warning('No ''stimulusOn'' events recorded, cannot register to Alyx')
      end
    end
    
    % Write stimulus values
    if ~exist(fullfile(expPath, [namespace 'trials.contrastLeft.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.contrastRight.npy']), 'file') || ...
        overwrite == true
      contL = getOr(evts, 'contrastLeftValues', NaN);
      contR = getOr(evts, 'contrastRightValues', NaN);
      if ~any(isnan(contL))&&~any(isnan(contR))
        writeNPY(contL(:), fullfile(expPath, [namespace 'trials.contrastLeft.npy']));
        writeNPY(contR(:), fullfile(expPath, [namespace 'trials.contrastRight.npy']));
      else
        warning('No ''contrastLeft'' and/or ''contrastRight'' events recorded, cannot register to Alyx')
      end
    end
    
    % Write probability left
    if ~exist(fullfile(expPath, [namespace 'trials.probabilityLeft.npy']), 'file') || overwrite == true
      probLeft = getOr(evts, 'proportionLeftValues', ...
        ones(length(data.events.endTrialTimes),1)*0.5);
      writeNPY(probLeft(:), fullfile(expPath, [namespace 'trials.probabilityLeft.npy']));
    end
    
    % Write trial intervals
    if ~exist(fullfile(expPath, [namespace 'trials.intervals.npy']), 'file') || overwrite == true
      startTimes = evts.newTrialTimes(:)-expStartTime;
      endTimes = evts.endTrialTimes(:)-expStartTime;
      if length(endTimes) < length(startTimes)
        endTimes(end+1) = evts.expStopTimes-expStartTime;
      end
      alf.writeInterval(expPath, [namespace 'trials'], startTimes, endTimes, [], []);
    end
    
    % Write included and repeat num
    if ~exist(fullfile(expPath, [namespace 'trials.included.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.repNum.npy']), 'file') || ...
        overwrite == true
      repNum = uint8(evts.repeatNumValues(:));
      writeNPY(repNum == 1, fullfile(expPath, [namespace 'trials.included.npy']));
      writeNPY(repNum, fullfile(expPath, [namespace 'trials.repNum.npy']));
    end
    
    % Write wheel times, position and velocity
    Fs = 1000;
    if ~exist(fullfile(expPath, [namespace 'wheel.position.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'wheel.timestamps.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'wheel.velocity.npy']), 'file') || ...
        overwrite == true
      t = data.inputs.wheelTimes(1):1/Fs:data.inputs.wheelTimes(end);
      t = t - expStartTime;
      rawPos = wheel.correctCounterDiscont(data.inputs.wheelValues);
      pos = interp1(data.inputs.wheelTimes-expStartTime, rawPos, t, 'linear');
      pos = pos - pos(1); % Position relative to beginning of session
      
      try % Load encoder resolution from hw info file
        rig = loadjson(dat.expFilePath(data.expRef, 'hw-info', 'master')); %FIXME: This takes ages to load
        encRes = rig.mouseInput.EncoderResolution;
      catch % Use most common resoultion instead
        encRes = 1024;
        warning('Alyx:alf:block2Alf:loadRigInfoFailed', ...
          'Failed to load hardware JSON, assuming encoder resolution to be %i', encRes)
      end
      pos = pos./(4*encRes)*2*pi*3.1; % convert to cm
      
      alf.writeTimeseries(expPath, [namespace 'wheel'], t(:), [], []);
      writeNPY(pos, fullfile(expPath, [namespace 'wheel.position.npy']));
      writeNPY(wheel.computeVelocity2(pos, 0.03, Fs), ...
        fullfile(expPath, [namespace 'wheel.velocity.npy']));
    end
    
    % Write wheel moves
    if ~exist(fullfile(expPath, [namespace 'wheelMoves.type.csv']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'wheelMoves.intervals.npy']), 'file') || ...
        overwrite == true
      [moveOnsets, moveOffsets] = wheel.findWheelMoves3(data.inputs.wheelValues, ...
        data.inputs.wheelTimes-expStartTime, Fs, []);
      
      hasTurn = response~=0;
      resp = response(hasTurn);
      % Convert response to type required by classifyWheelMoves
      resp(resp == 0) = 3; % No go
      resp(resp == -1) = 2; % CCW
      intStartTime = interactiveOn(hasTurn);
      respTime = responseTimes(hasTurn);
      moveType = wheel.classifyWheelMoves(data.inputs.wheelTimes-expStartTime, ...
        data.inputs.wheelValues, moveOnsets, moveOffsets, intStartTime, respTime, resp);
      
      txtMoveType(moveType==0) = "flinch";
      txtMoveType(moveType==1) = "CW";
      txtMoveType(moveType==2) = "CCW";
      txtMoveType(moveType==3) = "other";
      
      alf.writeInterval(expPath, [namespace 'wheelMoves'], ...
        moveOnsets, moveOffsets, [], []);
      fid = fopen(fullfile(expPath, [namespace 'wheelMoves.type.csv']),'w');
      fprintf(fid, '%s', strjoin(txtMoveType,','));
      fclose(fid);
    end
  end

  function extractChoiceWorld(data)
    % EXTRACTCHOICEWORLD Extract ALF files from a ChoiceWorld block file.
    if ~isfield(data,'trial') || ...
        isempty(data.rewardDeliveredSizes) || ...
        length(data.trial)<20
      return
    end
    
    %ANALYZE CHOCIEWORLD BLOCK
    load(dat.expFilePath(data.expRef, 'parameters', 'master'), 'parameters')
    completedTrials = data.numCompletedTrials;
    expStartTime = data.experimentStartedTime;
    trials = data.trial(1:completedTrials);
    choice = [trials.responseMadeID];
    if max(choice) == 2
      choice(choice == 3) = 0; % No go
      choice(choice == 2) = -1; % CCW
    end
    responseTimes = [trials.responseMadeTime] - expStartTime;
    feedbackType = [trials.feedbackType];
    feedbackTimes = [trials.feedbackStartedTime] - expStartTime;
    rwds = data.rewardDeliveredSizes(...
      data.rewardDeliveryTimes < data.trial(completedTrials).trialEndedTime);
    rwds = iff(size(rwds,1) < size(rwds,2), rwds', rwds);
    conds = [trials(1:completedTrials).condition];
    contrast = [conds.visCueContrast]';
    contrastLeft = contrast(:,1);
    contrastRight = contrast(:,2);
    repNum = uint8([conds.repeatNum])';
    included = repNum==1;
    trialStartTime = [trials.trialStartedTime]' - expStartTime;
    trialEndTime = [trials.trialEndedTime]' - expStartTime;
    goCueTimes = vertcat(trials.onsetToneSoundPlayedTime);
    goCueTimes = goCueTimes(:,1) - expStartTime;
    stimOnTimes = [trials.stimulusCueStartedTime]' - expStartTime;
    % responseWindow = repmat(data.parameters.responseWindow,completedTrials,1);
    contrastSet = diff([parameters.visCueContrast], [], 1);
    propotionLeft = repmat(sum(parameters.numRepeats(sign(contrastSet)==-1)) / ...
      sum(parameters.numRepeats), 1, completedTrials);
    
    % WRITE ALFS
    % Feedback
    if ~exist(fullfile(expPath, [namespace 'trials.feedbackType.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.feedback_times.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.rewardVolume.npy']), 'file') || ...
        overwrite == true
      writeNPY(int8(feedbackType(:)), fullfile(expPath, [namespace 'trials.feedbackType.npy']));
      alf.writeEventseries(expPath, [namespace 'trials.feedback'], feedbackTimes, [], []);
      % Reward
      rewardValues = feedbackType;
      rewardValues(feedbackType==1) = rwds(rwds~=0); %FIXME: Fails with extra rewards given e.g. 2018-10-15_1_SF180613 
      rewardValues(feedbackType==-1) = 0;
      writeNPY(rewardValues(:), fullfile(expPath, [namespace 'trials.rewardVolume.npy']));
    end
    
    % Trial times
    if ~exist(fullfile(expPath, [namespace 'trials.intervals.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.goCue_times.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.stimOn_times.npy']), 'file') || ...
        overwrite == true
      alf.writeInterval(expPath, [namespace 'trials'], trialStartTime, trialEndTime, [], []);
      alf.writeEventseries(expPath, [namespace 'trials.goCue'], goCueTimes, [], []);
      alf.writeEventseries(expPath, [namespace 'trials.stimOn'], stimOnTimes, [], []);
    end
    
    % Response
    if ~exist(fullfile(expPath, [namespace 'trials.choice.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.response_times.npy']), 'file') || ...
        overwrite == true
      writeNPY(int8(choice(:)), fullfile(expPath, [namespace 'trials.choice.npy']));
      alf.writeEventseries(expPath, [namespace 'trials.response'], responseTimes, [], []);
    end
    
    % Contrast
    if ~exist(fullfile(expPath, [namespace 'trials.contrastLeft.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.contrastRight.npy']), 'file') || ...
        overwrite == true
      writeNPY(contrastLeft(:), fullfile(expPath, [namespace 'trials.contrastLeft.npy']));
      writeNPY(contrastRight(:), fullfile(expPath, [namespace 'trials.contrastRight.npy']));
    end
    
    % Misc
    if ~exist(fullfile(expPath, [namespace 'trials.probabilityLeft.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.included.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'trials.repNum.npy']), 'file') || ...
        overwrite == true
      writeNPY(propotionLeft(:), fullfile(expPath, [namespace 'trials.probabilityLeft.npy']));
      writeNPY(included, fullfile(expPath, [namespace 'trials.included.npy']));
      writeNPY(repNum, fullfile(expPath, [namespace 'trials.repNum.npy']));
    end
    
    % WHEEL ALFs
    Fs = 1000;
    if ~exist(fullfile(expPath, [namespace 'wheel.position.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'wheel.timestamps.npy']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'wheel.velocity.npy']), 'file') || ...
        overwrite == true
      t = data.inputSensorPositionTimes(1):1/Fs:data.inputSensorPositionTimes(end);
      t = t - expStartTime;
      rawPos = wheel.correctCounterDiscont(data.inputSensorPositions);
      pos = interp1(data.inputSensorPositionTimes-expStartTime, rawPos, t, 'linear');
      pos = pos - pos(1); % Position relative to beginning of session
      try % Load encoder resolution from hw info file
        rig = loadjson(dat.expFilePath(data.expRef, 'hw-info', 'master')); %FIXME: This takes ages to load
        encRes = rig.mouseInput.EncoderResolution;
      catch % Use most common resoultion instead
        encRes = 1024;
        warning('Alyx:alf:block2Alf:loadRigInfoFailed', ...
          'Failed to load hardware JSON, assuming encoder resolution to be %i', encRes)
      end
      pos = pos./(4*encRes)*2*pi*3.1; % convert to cm
      alf.writeTimeseries(expPath, [namespace 'wheel'], t(:), [], []);
      writeNPY(pos, fullfile(expPath, [namespace 'wheel.position.npy']));
      writeNPY(wheel.computeVelocity2(pos, 0.03, Fs), ...
        fullfile(expPath, [namespace 'wheel.velocity.npy']));
    end
    
    % Wheel moves
    if ~exist(fullfile(expPath, [namespace 'wheelMoves.type.csv']), 'file') || ...
        ~exist(fullfile(expPath, [namespace 'wheelMoves.intervals.npy']), 'file') || ...
        overwrite == true
      
      [moveOnsets, moveOffsets] = wheel.findWheelMoves3(data.inputSensorPositions, ...
        data.inputSensorPositionTimes-expStartTime, Fs, []);
      hasTurn = choice~=0;
      resp = choice(hasTurn);
      % Convert response to type required by classifyWheelMoves
      resp(resp == 0) = 3; % No go
      resp(resp == -1) = 2; % CCW
      intStartTime = goCueTimes(hasTurn);
      respTime = responseTimes(hasTurn);
      moveType = wheel.classifyWheelMoves(data.inputSensorPositionTimes-expStartTime, ...
        data.inputSensorPositions, moveOnsets, moveOffsets, intStartTime(:), respTime(:), resp(:));
      txtMoveType(moveType==0) = "flinch";
      txtMoveType(moveType==1) = "CW";
      txtMoveType(moveType==2) = "CCW";
      txtMoveType(moveType==3) = "other";
      alf.writeInterval(expPath, [namespace 'wheelMoves'], ...
        moveOnsets, moveOffsets, [], []);
      fid = fopen(fullfile(expPath, [namespace 'wheelMoves.type.csv']),'w');
      fprintf(fid, '%s', strjoin(txtMoveType,','));
      fclose(fid);
    end
  end

  function S = removeIncompleteTrials(S, completedTrials)
    lengths = structfun(@length, S);
    names = fieldnames(S);
    names = names(lengths == completedTrials+1 | lengths == completedTrials+2);
    s = cellfun(@(x) x(1:completedTrials), pick(S, names), 'UniformOutput', 0);
    for n = 1:length(s)
      S.(names{n}) = s{n};
    end
  end
end