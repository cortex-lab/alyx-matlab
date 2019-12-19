classdef (SharedTestFixtures={matlab.unittest.fixtures.PathFixture(...
    [fileparts(mfilename('fullpath')) '\fixtures'])})... % add 'fixtures' folder as test fixture
    Block2ALF_test < matlab.unittest.TestCase
  
  properties
    % The test experiment reference string
    Ref
    % A block of simulated ChoiceWorld data
    ChoiceWorldBlock
    % A block of simulated Signals data
    SignalsBlock
    % An encoder resolution to set in the hardware
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
    
    function setupBlock(tc)
      % Some constants
      n = 25; % Number of trials
      duration = 3*60; % 3 min block
      N = @(mu) tc.sample(mu, n); % Convenience function for norm dist sampling
      
      %% Create the ChoiceWorld block
      cwBlock = struct('expRef', tc.Ref, 'expType', 'ChoiceWorld');
      cwBlock.numCompletedTrials = n;
      cwBlock.experimentStartedTime = GetSecs;
      
      % Wheel
      % Load wheel from the test data in wheelAnalysis toolbox.
      dataPath = fileparts(getOr(what('wheel'), 'path'));
      wheelData = load(fullfile(dataPath, 'test_wheel.mat'));
      cwBlock.inputSensorPositions = wheelData.test(1).wval;
      wt = wheelData.test(1).wt - wheelData.test(1).wt(1);
      cwBlock.inputSensorPositionTimes = wt + cwBlock.experimentStartedTime;
      
      % Create trial structure
      trialFn = {...
        'condition';
        'responseMadeID';
        'responseMadeTime';
        'feedbackType';
        'feedbackStartedTime';
        'trialStartedTime';
        'trialEndedTime';
        'onsetToneSoundPlayedTime';
        'stimulusCueStartedTime'};
      % `trial` is nx1 struct with the above fields
      t = repmat(cell2struct(cell(size(trialFn)), trialFn), n, 1);
      
      % Assign times
      startTimes = sort(randsample(1:duration, n) + rand(1, n)) + ...
        cwBlock.experimentStartedTime;
      [t.trialStartedTime] = tc.assign(startTimes);
      [t.onsetToneSoundPlayedTime] = tc.assign(startTimes + N(2e-3));
      [t.stimulusCueStartedTime] = tc.assign(startTimes + N(1e-3));
      [t.responseMadeTime] = tc.assign(startTimes + N(1));
      [t.feedbackStartedTime] = tc.assign([t.responseMadeTime] + .1);
      % Ensure all end times occur after start times
      endTimes = startTimes + [diff(startTimes)-0.1 startTimes(end)+2+rand];
      [t.trialEndedTime] = tc.assign(endTimes);
      
      % Assign trial values
      [t.responseMadeID] = tc.assign(randi(3, n, 1));
      [t.feedbackType] = tc.assign(randsample([-1 1], n, 1));
      % Add our response ID map to parameters
      cwBlock.parameters.responseForThreshold = [1; 2];
      cwBlock.parameters.responseForNoGo = 3;
      cwBlock.parameters.experimentFun = ...
        @(pars,rig)exp.configureChoiceExperiment(exp.ChoiceWorld,pars,rig);
      
      cwBlock.trial = t;
      cwBlock.rewardDeliveryTimes = [t([t.feedbackType] == 1).feedbackStartedTime];
      cwBlock.rewardDeliveredSizes = repmat(3, 1, length(cwBlock.rewardDeliveryTimes));
      
      % Create trial.condition structure
      % This is also an nx1 struct
      conds = repmat(struct('visCueContrast', [], 'repeatNum', []), n, 1);
      contrast = [1 0.5 0.25 0.12 0.06 0]; % contrast list to use on one side or the other
      % compute contrast one each target - ones side has contrast, other has zero
      targetCon = [contrast, zeros(1, numel(contrast));
                   zeros(1, numel(contrast)), contrast];
      % in order to get 1 25x1 struct whose visCueContrast field contains
      % 2x1 arrays, we must convert to cell for assignment
      i = randi(size(targetCon,2),n,1); % Sample contrasts N times
      targetConCell = mat2cell(targetCon(:,i), 2, ones(1,n))'; % Reshape
      [conds.visCueContrast] = targetConCell{:}; % Assign
      [conds.repeatNum] = tc.assign(randi(3,1,n));
      
      % Put all together
      [cwBlock.trial.condition] = tc.assign(conds);
      tc.ChoiceWorldBlock = cwBlock;
      
      %% Signals block
      % Create events structure
      e.expStartTimes = cwBlock.experimentStartedTime;
      e.newTrialTimes = startTimes;
      e.newTrialValues = ones(size(startTimes));
      e.stimulusOnTimes = startTimes + N(1e-3);
      e.interactiveOnTimes = startTimes + N(2e-3);
      e.responseTimes = startTimes + N(1);
      e.feedbackTimes = e.responseTimes + .1;
      e.endTrialTimes = endTimes;
      
      % Events times
      e.feedbackValues = randsample([-1 1], n, 1);
      e.repeatNumValues = randi(3,1,n);
      e.responseValues = randsample(-1:1, n, 1);
      e.contrastLeftValues = targetCon(1,i);
      e.contrastRightValues = targetCon(2,i);
      e.proportionLeftValues = rand(1, n);
      
      % Create outputs structure
      out.rewardTimes = e.feedbackTimes([e.feedbackValues] == 1);
      out.rewardValues = repmat(3, 1, length(out.rewardTimes));
      
      % Create inputs structure
      in.wheelTimes = cwBlock.inputSensorPositionTimes;
      in.wheelValues = cwBlock.inputSensorPositions;
      
      % Assign to block
      tc.SignalsBlock = struct('events', e, 'outputs', out, ...
        'inputs', in, 'expRef', tc.Ref, 'expDef', 'testDef.m');
    end
    
    function setupHardware(testCase)
      % Write the hardware JSON file.  Used by extractors to determine
      % encoder resolution.
      encObj = hw.DaqRotaryEncoder;
      encObj.EncoderResolution = testCase.EncRes;
      encObj.DaqSession = struct('Channels', 'ai1'); % hack to avoid initializing
      hwInfo = dat.expFilePath(testCase.Ref, 'hw-info', 'master', 'json');
      fid = fopen(hwInfo, 'w');
      fprintf(fid, '%s', obj2json(struct('mouseInput', encObj)));
      fclose(fid);
    end
  end
  
  methods (TestMethodTeardown)
    function removeALFs(testCase)
      % Delete the ALF files inbetween tests
      expPath = dat.expPath(testCase.Ref, 'main', 'm');
      files = file.list(expPath);
      ALFs = files(~contains(files, {'_parameters.', '_hardwareInfo.'}));
      cellfun(@delete, fullfile(expPath, ALFs))
      assert(numel(file.list(expPath)) == 3, 'Failed to remove all files')
    end
  end
  
  methods (Test)
    function test_signalsExtraction(testCase)
      data = testCase.SignalsBlock;
      [fullpath, filename] = testCase.verifyWarningFree(@()alf.block2ALF(data));
      testCase.verifyTrue(all(startsWith(filename, '_misc_')), ...
        'Incorrect namespace given')
      testCase.assertTrue(all(file.exists(fullpath)), 'Failed to write files')
      
      % Choice / Response ALF
      choice = readNPY(fullpath{1});
      choiceTimes = readNPY(fullpath{11});
      testCase.verifyTrue(isa(choice, 'int8'), 'Wrong datatype for choice ALF')
      % Verify that signs switch: CW -ve
      testCase.verifyTrue(all(choice == -data.events.responseValues(:)), ...
        'Unexpected choice values')
      expected = data.events.responseTimes(:) - data.events.expStartTimes;
      testCase.verifyEqual(choiceTimes, expected, 'Unexpected response times')
      
      % ContrastLeft, ContrastRight ALF
      expected = [data.events.contrastLeftValues(:) data.events.contrastRightValues(:)];
      contrast = [readNPY(fullpath{2}), readNPY(fullpath{3})];
      testCase.verifyEqual(contrast, expected, 'Unexpected contrast values')
      
      % Feedback ALF
      feedback = readNPY(fullpath{4});
      testCase.verifyTrue(isa(feedback, 'int8'), 'Wrong datatype for feedback ALF')
      testCase.verifyTrue(all(feedback == data.events.feedbackValues(:)), ...
        'Unexpected feedback values')
      feedbackTimes = readNPY(fullpath{5});
      expected = data.events.feedbackTimes(:) - data.events.expStartTimes;
      testCase.verifyEqual(feedbackTimes, expected, ...
        'Unexpected feedback times')
      
      % GoCue / InteractiveOn ALF
      goCue = readNPY(fullpath{6});
      expected = data.events.interactiveOnTimes(:) - data.events.expStartTimes;
      testCase.verifyEqual(goCue, expected, 'Unexpected goCue times')
      
      % Included & RepNum ALFs
      incl = readNPY(fullpath{7});
      repNum = readNPY(fullpath{10});
      testCase.verifyTrue(isa(incl, 'logical'), 'Wrong datatype for included ALF')
      testCase.verifyTrue(isa(repNum, 'uint8'), 'Wrong datatype for repNum ALF')
      % Check the values
      testCase.verifyEqual(incl, (data.events.repeatNumValues == 1)', ...
        'Unexpected included values')
      testCase.verifyTrue(all(repNum == data.events.repeatNumValues(:)), ...
        'Unexpected repNum values')
      
      % Intervals
      ints = readNPY(fullpath{8});
      expected = [data.events.newTrialTimes(:) data.events.endTrialTimes(:)];
      expected = expected - data.events.expStartTimes;
      testCase.verifyEqual(ints, expected, 'Unexpected interval values')
      
      % ProbabilityLeft
      pL = readNPY(fullpath{9});
      testCase.verifyEqual(pL, data.events.proportionLeftValues(:), ...
        'Unexpected probabilityLeft values')
      
      % Reward volume
      rwd = readNPY(fullpath{12});
      testCase.verifyEqual(sum(rwd), sum(data.outputs.rewardValues), ...
        'Unexpected rewardVolume values')
      
      % StimOn
      stimOn = readNPY(fullpath{13});
      expected = data.events.stimulusOnTimes(:) - data.events.expStartTimes;
      testCase.verifyEqual(stimOn, expected, 'Unexpected stimOn times')
      
      % Wheel ALFs
      % We don't look too closely at these values as there's a more
      % rigorous test in the wheelAnalysis toolbox
      pos = readNPY(fullpath{14});
      t = readNPY(fullpath{15});
      v = readNPY(fullpath{16});
      expected = data.inputs.wheelTimes(end) - data.events.expStartTimes;
      tol = 0.3; % Due to interpolation this value won't be exact
      Fs = 1000; % Default sampling freq of extractor
      testCase.verifyEqual(t(4), expected, 'AbsTol', tol)
      testCase.verifyEqual(t(2)/Fs, expected, 'AbsTol', tol)
      testCase.verifyEqual(numel(v), numel(pos), ceil(expected*Fs))
      
      % WheelMoves ALFs
      whInts = readNPY(fullpath{17});
      type = strsplit(fileread(fullpath{18}),',');
      testCase.verifyEqual(size(whInts,1), numel(type))
      testCase.verifyEqual(size(whInts,2), 2)
    end
    
    function test_choiceWorldExtraction(testCase)
      data = testCase.ChoiceWorldBlock;
      expStartTime = data.experimentStartedTime;
      t = [data.trial];
      
      [fullpath, filename] = testCase.verifyWarningFree(@()alf.block2ALF(data));
      
      testCase.verifyTrue(all(startsWith(filename, '_misc_')), ...
        'Incorrect namespace given')
      testCase.assertTrue(all(file.exists(fullpath)), 'Failed to write files')
      
      % Choice / Response ALF
      choice = readNPY(fullpath{1});
      choiceTimes = readNPY(fullpath{11});
      testCase.verifyTrue(isa(choice, 'int8'), 'Wrong datatype for choice ALF')
      % Verify that signs switch: CW -ve
      response = [t.responseMadeID];
      correct = [...
        response(choice==0) == 3 ...
        response(choice==-1) == 2];
        
      testCase.verifyTrue(all(correct), 'Unexpected choice values')
      expected = [t.responseMadeTime] - expStartTime;
      testCase.verifyEqual(choiceTimes, expected(:), 'Unexpected response times')
      
      % ContrastLeft, ContrastRight ALF
      conds = [t.condition];
      expected = [conds.visCueContrast]';
      contrast = [readNPY(fullpath{2}), readNPY(fullpath{3})];
      testCase.verifyEqual(contrast, expected, 'Unexpected contrast values')
      
      % Feedback ALF
      feedback = readNPY(fullpath{4});
      testCase.verifyTrue(isa(feedback, 'int8'), 'Wrong datatype for feedback ALF')
      expected = [t.feedbackType];
      testCase.verifyTrue(all(feedback == expected(:)), 'Unexpected feedback values')
      feedbackTimes = readNPY(fullpath{5});
      expected = [t.feedbackStartedTime] - data.experimentStartedTime;
      testCase.verifyEqual(feedbackTimes, expected(:), ...
        'Unexpected feedback times')
      
      % GoCue / InteractiveOn ALF
      goCue = readNPY(fullpath{6});
      expected = [t.stimulusCueStartedTime] - data.experimentStartedTime;
      testCase.verifyEqual(goCue, expected(:), 'Unexpected goCue times')
      
      % Included & RepNum ALFs
      incl = readNPY(fullpath{7});
      repNum = readNPY(fullpath{10});
      testCase.verifyTrue(isa(incl, 'logical'), 'Wrong datatype for included ALF')
      testCase.verifyTrue(isa(repNum, 'uint8'), 'Wrong datatype for repNum ALF')
      % Check the values
      testCase.verifyEqual(incl, ([conds.repeatNum] == 1)', ...
        'Unexpected included values')
      testCase.verifyTrue(all(repNum == [conds.repeatNum]'), ...
        'Unexpected repNum values')
      
      % Intervals
      ints = readNPY(fullpath{8});
      expected = [t.trialStartedTime; t.trialEndedTime]';
      expected = expected - data.experimentStartedTime;
      testCase.verifyEqual(ints, expected, 'Unexpected interval values')
      
      % ProbabilityLeft
      pL = readNPY(fullpath{9});
      testCase.verifyTrue(all(pL == .5), 'Unexpected probabilityLeft values')
      
      % Reward volume
      rwd = readNPY(fullpath{12});
      testCase.verifyEqual(sum(rwd), sum(data.rewardDeliveredSizes), ...
        'Unexpected rewardVolume values')
      
      % StimOn
      stimOn = readNPY(fullpath{13});
      expected = [t.stimulusCueStartedTime] - data.experimentStartedTime;
      testCase.verifyEqual(stimOn, expected(:), 'Unexpected stimOn times')
      
      % Wheel ALFs
      % We don't look too closely at these values as there's a more
      % rigorous test in the wheelAnalysis toolbox
      pos = readNPY(fullpath{14});
      t = readNPY(fullpath{15});
      v = readNPY(fullpath{16});
      expected = data.inputSensorPositionTimes(end) - data.experimentStartedTime;
      tol = 0.3; % Due to interpolation this value won't be exact
      Fs = 1000; % Default sampling freq of extractor
      testCase.verifyEqual(t(4), expected, 'AbsTol', tol)
      testCase.verifyEqual(t(2)/Fs, expected, 'AbsTol', tol)
      testCase.verifyEqual(numel(v), numel(pos), ceil(expected*Fs))
      
      % WheelMoves ALFs
      whInts = readNPY(fullpath{17});
      type = strsplit(fileread(fullpath{18}),',');
      testCase.verifyEqual(size(whInts,1), numel(type))
      testCase.verifyEqual(size(whInts,2), 2)
    end
    
    function test_incomplete(testCase)
      % Test dealing with incomplete trials
      block1 = testCase.ChoiceWorldBlock;
      block2 = testCase.SignalsBlock;
      
      block1.trial(end+1).trialStartedTime = block1.trial(end).trialStartedTime + rand;
      block2.events.newTrialTimes(end+1) = block2.events.newTrialTimes(end) + rand;
      
      fullpath = alf.block2ALF(block1);
      testCase.verifySize(fullpath, [1 18], 'Failed to extract all files')
      fullpath = alf.block2ALF(block2, true); % overwrite
      testCase.verifySize(fullpath, [1 18], 'Failed to extract all files')
      
      % Test missing signals event
      block2.events = rmfield(block2.events, 'stimulusOnTimes');
      expected = 'Alyx:alf:block2ALF:stimulusOnValuesNotFound';
      testCase.verifyWarning(@()alf.block2ALF(block2, true), expected);
      
      % Test the overwrite flag
      % With overwrite == false the function should not attempt to extract
      % files that already exists, i.e. stimOn_times and therefore won't
      % throw a warning.
      testCase.verifyWarningFree(@() alf.block2ALF(block1, false))
      
      % Test warning on custom configuration function
      block1.parameters.experimentFun = @nop;
      expected = 'Alyx:alf:block2ALF:unknownConfig';
      testCase.verifyWarning(@()alf.block2ALF(block1), expected)
      
      % Test warning on missing hw json:
      hwInfo = dat.expFilePath(testCase.Ref, 'hw-info', 'master', 'json');
      % Replace file on teardown
      testCase.addTeardown(@()setupHardware(testCase))
      delete(hwInfo);
      testCase.assertFalse(file.exists(hwInfo), 'Failed to delete HW Json')
      expected = 'Alyx:alf:block2ALF:loadRigInfoFailed';
      testCase.verifyWarning(@()alf.block2ALF(block1, true), expected)
      testCase.verifyWarning(@()alf.block2ALF(block2, true), expected)
    end
  end
  
  methods (Static)
    function r = sample(mu, n)
      % SAMPLE Sample values from a Gaussian
      %   Sample n values from normal distribution of mean mu.  Always
      %   returns positive values.
      r = normrnd(mu,1,1,n);
      if r < 0, r = 0; end
    end
    
    function varargout = assign(A)
      % ASSIGN Assign elements of an array to field of nonscalar struct
      %  Similar to how deal works. Allows you to assign an element of an
      %  input array to a variable in one line.  This is the same as the
      %  Rigbox `distribute` utility. Input must be 1D.
      %
      %  Input:
      %    A - Array to distribute to output args
      %
      %  Outputs:
      %    [a1, a2, a3, etc.] : The elements of A
      %
      %  Example:
      %    s = repmat(struct('field', []), 1, 3); % A 3x1 struct
      %    [s.field] = testCase.assign(4:6);
      %    s(2).field % 5
      %
      % See also DISTRIBUTE
      varargout = cell(1, nargout);
      for i = 1:nargout, varargout{i} = A(i); end
    end
  end
end