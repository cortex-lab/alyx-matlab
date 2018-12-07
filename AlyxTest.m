classdef (SharedTestFixtures={ ...
    matlab.unittest.fixtures.PathFixture(fullfile(fileparts(which('addRigboxPaths')), 'tests'), 'IncludingSubfolders', true)}) ...
    AlyxTest < matlab.unittest.TestCase
  
  properties
    AlyxInstance
  end
  
  properties (MethodSetupParameter)
    BaseURL = {'http://alyx-dev.cortexlab.net', 'https://alyx-dev.cortexlab.net', 'https://alyx.dev.internationalbrainlab.org'}
    User = {'', 'miles'}
    Token = {'', 'd36b813e18f23472dc4844e211ee5558a56cdef1'}
    Headless = {false, true}
  end
  
  methods (TestClassSetup)
    %     function testCase = AlyxTest(testCase)
    %       testCase.BaseURL = getOr(dat.paths, 'databaseURL', 'http://alyx-dev.cortexlab.net');
    %       ai = Alyx('miles','d36b813e18f23472dc4844e211ee5558a56cdef1');
    %       ai.BaseURL = testCase.BaseURL;
    %       testCase.AlyxInstance.logged_in = ai;
    %       testCase.AlyxInstance.logged_out = ai.logout;
    %       ai.Headless = true;
    %       testCase.AlyxInstance.headless = ai;
    %     end
    
    function addTestPath(testCase)
      f = testCase.getSharedTestFixtures;
      disp(['Added to path: ' f.Folder])
    end
  end
  
  methods (TestMethodSetup)
    function testCase = methodSetup(testCase, BaseURL, User, Token, Headless)
      testCase.AlyxInstance = Alyx(User, Token);
      testCase.AlyxInstance.BaseURL = BaseURL;
      testCase.AlyxInstance.Headless = Headless;
      % Create test directory if it doesn't exist
      alyxQ = getOr(dat.paths,'localAlyxQueue');
      if exist(alyxQ, 'dir') ~= 7
        mkdir(alyxQ);
      else % Delete any queued posts
        files = dir(alyxQ);
        files = {files(endsWith({files.name},{'put', 'patch', 'post'})).name};
        cellfun(@delete, fullfile(alyxQ, files))
      end
    end
  end
  
  methods (Test)
    function testLogin(testCase)
      %       ai = testCase.AlyxInstance;
    end
    
    function registerFile(testCase)
    end
    
    function postWater(testCase)
      ai = testCase.AlyxInstance;
      waterPost = @()ai.postWater('test', 1.5, 7.3740e+05, 'Water');
      if ai.Headless || ~ai.IsLoggedIn
        % When headless or not connected, should save post as JSON and
        % issue warning
        wa = verifyWarning(testCase, waterPost,'Alyx:flushQueue:NotConnected');
        % Check post was saved
        savedPost = dir([ai.QueueDir filesep '*.post']);
        testCase.fatalAssertNotEmpty(savedPost, 'Post not saved')
        fn = @()AlyxTest.loadPost(fullfile(savedPost.folder, savedPost.name));
        [jsonData, endpnt] = testCase.fatalAssertWarningFree(fn);
        testCase.verifyMatches(endpnt, 'water-administrations', 'Incorrect endpoint')
        expected = '{"date_time":"2018-12-07T11:13:27","water_type":"Water","subject":"test","water_administered":1.5}';
        testCase.verifyMatches(jsonData, expected, 'JSON data incorrect')
      else
        wa = verifyWarningFree(testCase, waterPost,'Alyx:flushQueue:NotConnected');
        savedPost = dir([ai.QueueDir filesep '*.post']);
        testCase.verifyEmpty(savedPost, 'Post not deleted on success')
      end
      
      % Check water record
      expectedFields = {'date_time', 'water_type', 'subject', 'water_administered'};
      testCase.verifyTrue(all(ismember(fieldnames(wa), expectedFields)), 'Field names missing')
      testCase.verifyEqual(wa.date_time, '2018-12-07T11:13:27', 'date_time incorrect')
      testCase.verifyTrue(strcmp(wa.water_type,'Water'), 'water_type incorrect')
      testCase.verifyTrue(strcmp(wa.subject,'test'), 'subject incorrect')
      testCase.verifyEqual(wa.water_administered, 1.5, 'water_administered incorrect')
      
      %       sugar = ai.postWater('test', 1.5, now, 'Water 15% Sucrose');
    end
    
    function postWeight(testCase)
      
    end
    
    function headless(testCase)
    end
    
  end
  
  methods (Static)
    function [jsonData, endpnt] = loadPost(filepath)
      try
        % Attempt to load record
        fid = fopen(filepath);
        % First line is the endpoint
        endpnt = fgetl(fid);
        % Rest of the text is the JSON data
        jsonData = fscanf(fid,'%c');
        fclose(fid);
      catch ex
        warning(ex.identifier, '%s', ex.message)
      end
    end
  end
end