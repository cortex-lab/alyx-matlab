classdef Block2ALF_test < matlab.unittest.TestCase
  
  properties
    Ref
    ChoiceWorldBlock
    SignalsBlock
    Hardware
    EncRes = 360
  end
  
  methods (TestClassSetup)
    
    function setupExperiment(testCase)
      assert(exist('readNPY', 'file') == 2, 'Requires NPY-MATLAB toolbox')
      assert(exist(which('wheel.findWheelMoves3'), 'file') == 2, ...
        'Requires wheelAnalysis toolbox')
      % TODO Add paths setup here
      % Save a set of parameters for the choiceWorld block
      superSave(dat.expFilePath(expRef, 'parameters', 'm'), ...
        struct('parameters', exp.choiceWorldParams));
      return
    end
    
    function setupBlock(testCase)
      % Trial specific parameter names
      N = 25; % Number of trials
      duration = 3*60; % 3 min block
      cwBlock = struct;
      cwBlock.numCompletedTrials = N;
      cwBlock.experimentStartedTime = GetSecs;
      % Wheel
      dataPath = fileparts(getOr(what('wheel'), 'path'));
      wheelData = load(fullfile(dataPath, 'test_wheel.mat'));
      cwBlock.inputSensorPositions = wheelData.test(1).wval;
      wt = wheelData.test(1).wt - wheelData.test(1).wt(1);
      cwBlock.inputSensorPositionTimes = wt + cwBlock.experimentStartedTime;
      
      condFn = {...
        'condition';
        'responseMadeID';
        'feedbackType';
        'feedbackStartedTime';
        'trialStartedTime';
        'trialEndedTime';
        'onsetToneSoundPlayedTime';
        'stimulusCueStartedTime'};
      t = repmat(cell2struct(cell(size(condFn)), condFn), N, 1);
      [t.feedbackType] = deal(randi(3, 1, N));
      startTimes = sort(randi(duration, 1, N) + rand(1, N)) + ...
        cwBlock.experimentStartedTime;
      [t.trialStartedTime] = deal(startTimes);
      [t.onsetToneSoundPlayedTime] = deal(startTimes + testCase.sample(2e-3, N));
      [t.stimulusCueStartedTime] = deal(startTimes + testCase.sample(1e-3, N));
      [t.feedbackStartedTime] = deal(startTimes + testCase.sample(1, N));
      [t.trialEndedTime] = deal(startTimes + testCase.sample(1.5, N));
      
      [t.responseMadeID] = deal(randi(3, N, 1));
      [t.feedbackType] = deal(randsample([-1 1], N, 1));
      
      cwBlock.trials = t;
      cwBlock.rewardDeliveryTimes = [t([t.feedbackType] == 1).feedbackStartedTime];
      cwBlock.rewardDeliveredSizes = repmat(3, 1, length(cwBlock.rewardDeliveryTimes));
      
      conds = repmat(struct('visCueContrast', [], 'repeatNum', []), N, 1);
      
      contrast = [1 0.5 0.25 0.12 0.06 0]; % contrast list to use on one side or the other
      % compute contrast one each target - ones side has contrast, other has zero
      targetCon = [contrast, zeros(1, numel(contrast));
        zeros(1, numel(contrast)), contrast];
      i = randi(size(targetCon,2),N,1); % Sample contrasts N times
      [conds.visCueContrast] = deal(targetCon(:,i));
      [conds.repNum] = deal(randi(3,1,N));
      [cwBlock.trials.condition] = deal(conds);
      testCase.ChoiceWorldBlock = cwBlock;
      % responseWindow = repmat(data.parameters.responseWindow,completedTrials,1);
      
      %% Signals block
      e.expStartTimes = cwBlock.experimentStartedTime;
      e.newTrialTimes = startTimes;
      e.stimulusOnTimes = startTimes + testCase.sample(1e-3, N);
      e.interactiveOnTimes = startTimes + testCase.sample(2e-3, N);
      e.responseTimes = startTimes + testCase.sample(1, N);
      e.feedbackTimes = responseTimes + .1;
      e.endtrialTimes = startTimes + testCase.sample(1.5, N);
      
      e.feedbackValues = randsample([-1 1], N, 1);
      e.repeatNumValues = randi(3,1,N);
      e.responseValues = randsample(-1:1, N, 1);
      e.contrastLeftValues = targetCon(1,i);
      e.contrastRightValues = targetCon(2,i);
      e.proportionLeftValues = rand(1, N);
      
      out.rewardTimes = e([e.responseValues] == 1).feedbackTimes;
      out.rewardValues = repmat(3, 1, length(out.rewardTimes));
      
      in.wheelTimes = cwBlock.inputSensorPositionTimes;
      in.wheelValues = cwBlock.inputSensorPositions;
      
      testCase.SignalsBlock = struct('events', e, 'outputs', out, 'inputs', in);
    end
    
    function setupHardware(testCase)
      encObj = hw.DaqRotaryEncoder;
      encObj.EncoderResolution = testCase.EncRes;
      hwInfo = dat.expFilePath(testCase.Ref, 'hw-info', 'master', 'json');
      fid = fopen(hwInfo, 'w');
      fprintf(fid, '%s', obj2json(struct('mouseInput', encObj)));
      fclose(fid);
    end
  end
  
  methods (Test)
    function test_signalsExtraction(testCase)
      return
    end
  end
  
  methods (Static)
    function r = sample(mu,len)
      r = normrnd(mu,1,1,len);
      r = iff(r < 0, 0, r);
    end
  end
end