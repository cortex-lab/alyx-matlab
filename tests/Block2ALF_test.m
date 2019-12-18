classdef (SharedTestFixtures={matlab.unittest.fixtures.PathFixture(...
    [fileparts(mfilename('fullpath')) '\fixtures'])})... % add 'fixtures' folder as test fixture
    Block2ALF_test < matlab.unittest.TestCase
  
  properties
    Ref
    ChoiceWorldBlock
    SignalsBlock
    Hardware
    EncRes = 360
  end
  
  methods (TestClassSetup)
    
    function checkFixtures(testCase)
      % Check we're using test paths file
      assert(endsWith(which('dat.paths'), fullfile('fixtures','+dat','paths.m')));
      % Check temp mainRepo folder is empty.  An extra safe measure as we
      % don't won't to delete important folders by accident!
      mainRepo = dat.reposPath('main','master');
      assert(~exist(mainRepo, 'dir') || isempty(file.list(mainRepo)),...
        'Test experiment repo not empty.  Please set another path or manual empty folder');
      assert(mkdir(mainRepo, 'test'), ...
        'Failed to create test subject experiment folder')
      
      rm = @(repo)assert(rmdir(repo, 's'), 'Failed to remove test repo %s', repo);
      rmAll = @() cellfun(@(repo)iff(exist(repo,'dir') == 7, @()rm(repo), @()nop), ...
              [dat.reposPath('main', 'remote'); {dat.reposPath('main', 'local')}]);
      testCase.addTeardown(rmAll)
    end
    
    function setupExperiment(testCase)
      assert(exist('readNPY', 'file') == 2, 'Requires NPY-MATLAB toolbox')
      assert(exist(which('wheel.findWheelMoves3'), 'file') == 2, ...
        'Requires wheelAnalysis toolbox')
      % Save a set of parameters for the choiceWorld block
      testCase.Ref = dat.newExp('test', now, exp.choiceWorldParams);
    end
    
    function setupBlock(testCase)
      % Trial specific parameter names
      N = 25; % Number of trials
      duration = 3*60; % 3 min block
      cwBlock = struct('expRef', testCase.Ref, 'expType', 'ChoiceWorld');
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
      %[t.feedbackType] = distribute(randi(3, N, 1));
      t = arrayfun(@(s,v) setfield(s, 'feedbackType', v), t, randi(3, N, 1));
      startTimes = sort(randi(duration, 1, N) + rand(1, N)) + ...
        cwBlock.experimentStartedTime;
      [t.trialStartedTime] = distribute(startTimes);
      [t.onsetToneSoundPlayedTime] = distribute(startTimes + testCase.sample(2e-3, N));
      [t.stimulusCueStartedTime] = distribute(startTimes + testCase.sample(1e-3, N));
      [t.feedbackStartedTime] = distribute(startTimes + testCase.sample(1, N));
      endTimes = startTimes + [diff(startTimes)-0.1 startTimes(end)+2+rand];
      [t.trialEndedTime] = distribute(endTimes);
%       [t.trialEndedTime] = distribute(startTimes + testCase.sample(1.5, N));
      
      [t.responseMadeID] = distribute(randi(3, N, 1));
      [t.feedbackType] = distribute(randsample([-1 1], N, 1));
      
      cwBlock.trials = t;
      cwBlock.rewardDeliveryTimes = [t([t.feedbackType] == 1).feedbackStartedTime];
      cwBlock.rewardDeliveredSizes = repmat(3, 1, length(cwBlock.rewardDeliveryTimes));
      
      conds = repmat(struct('visCueContrast', [], 'repeatNum', []), N, 1);
      
      contrast = [1 0.5 0.25 0.12 0.06 0]; % contrast list to use on one side or the other
      % compute contrast one each target - ones side has contrast, other has zero
      targetCon = [contrast, zeros(1, numel(contrast));
        zeros(1, numel(contrast)), contrast];
      i = randi(size(targetCon,2),N,1); % Sample contrasts N times
      targetConCell = mat2cell(targetCon(:,i)', ones(1,N));
      [conds.visCueContrast] = distribute(targetConCell);
      [conds.repNum] = distribute(randi(3,1,N));
      [cwBlock.trials.condition] = distribute(conds);
      testCase.ChoiceWorldBlock = cwBlock;
      % responseWindow = repmat(data.parameters.responseWindow,completedTrials,1);
      
      %% Signals block
      e.expStartTimes = cwBlock.experimentStartedTime;
      e.newTrialTimes = startTimes;
      e.newTrialValues = ones(size(startTimes));
      e.stimulusOnTimes = startTimes + testCase.sample(1e-3, N);
      e.interactiveOnTimes = startTimes + testCase.sample(2e-3, N);
      e.responseTimes = startTimes + testCase.sample(1, N);
      e.feedbackTimes = e.responseTimes + .1;
      e.endTrialTimes = endTimes;
      
      e.feedbackValues = randsample([-1 1], N, 1);
      e.repeatNumValues = randi(3,1,N);
      e.responseValues = randsample(-1:1, N, 1);
      e.contrastLeftValues = targetCon(1,i);
      e.contrastRightValues = targetCon(2,i);
      e.proportionLeftValues = rand(1, N);
      
      out.rewardTimes = e.feedbackTimes([e.feedbackValues] == 1);
      out.rewardValues = repmat(3, 1, length(out.rewardTimes));
      
      in.wheelTimes = cwBlock.inputSensorPositionTimes;
      in.wheelValues = cwBlock.inputSensorPositions;
      
      testCase.SignalsBlock = struct('events', e, 'outputs', out, ...
        'inputs', in, 'expRef', testCase.Ref, 'expDef', 'testDef.m');
    end
    
    function setupHardware(testCase)
      encObj = hw.DaqRotaryEncoder;
      encObj.EncoderResolution = testCase.EncRes;
      encObj.DaqSession = struct('Channels', 'ai1'); % hack to avoid initializing
      hwInfo = dat.expFilePath(testCase.Ref, 'hw-info', 'master', 'json');
      fid = fopen(hwInfo, 'w');
      fprintf(fid, '%s', obj2json(struct('mouseInput', encObj)));
      fclose(fid);
    end
  end
  
  methods (Test)
    function test_signalsExtraction(testCase)
      data = testCase.SignalsBlock;
      [fullpath, filename] = alf.block2ALF(data);
    end
  end
  
  methods (Static)
    function r = sample(mu,len)
      r = normrnd(mu,1,1,len);
      r = iff(r < 0, 0, r);
    end
  end
end