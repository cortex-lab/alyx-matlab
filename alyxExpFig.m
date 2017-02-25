% TODO:
% - automatically check for new experiments frequently
% - implement tag and ignore switches
% - timeline plot
% - show water remaining

function varargout = alyxExpFig(varargin)
% ALYXEXPFIG MATLAB code for alyxExpFig.fig
%      ALYXEXPFIG, by itself, creates a new ALYXEXPFIG or raises the existing
%      singleton*.
%
%      H = ALYXEXPFIG returns the handle to a new ALYXEXPFIG or the handle to
%      the existing singleton*.
%
%      ALYXEXPFIG('CALLBACK',hObject,eventData,handles,...) calls the local
%      function named CALLBACK in ALYXEXPFIG.M with the given input arguments.
%
%      ALYXEXPFIG('Property','Value',...) creates a new ALYXEXPFIG or raises the
%      existing singleton*.  Starting from the left, property value pairs are
%      applied to the GUI before alyxExpFig_OpeningFcn gets called.  An
%      unrecognized property name or invalid value makes property application
%      stop.  All inputs are passed to alyxExpFig_OpeningFcn via varargin.
%
%      *See GUI Options on GUIDE's Tools menu.  Choose "GUI allows only one
%      instance to run (singleton)".
%
% See also: GUIDE, GUIDATA, GUIHANDLES

% Edit the above text to modify the response to help alyxExpFig

% Last Modified by GUIDE v2.5 21-Feb-2017 23:16:34

% Begin initialization code - DO NOT EDIT
gui_Singleton = 0;
gui_State = struct('gui_Name',       mfilename, ...
                   'gui_Singleton',  gui_Singleton, ...
                   'gui_OpeningFcn', @alyxExpFig_OpeningFcn, ...
                   'gui_OutputFcn',  @alyxExpFig_OutputFcn, ...
                   'gui_LayoutFcn',  [] , ...
                   'gui_Callback',   []);
if nargin && ischar(varargin{1})
    gui_State.gui_Callback = str2func(varargin{1});
end

if nargout
    [varargout{1:nargout}] = gui_mainfcn(gui_State, varargin{:});
else
    gui_mainfcn(gui_State, varargin{:});
end
% End initialization code - DO NOT EDIT


% --- Executes just before alyxExpFig is made visible.
function alyxExpFig_OpeningFcn(hObject, eventdata, handles, varargin)
% This function has no output args, see OutputFcn.
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
% varargin   command line arguments to alyxExpFig (see VARARGIN)

% Choose default command line output for alyxExpFig
handles.output = hObject;
handles.mouseName = varargin{1};
handles.thisDate = varargin{2};
handles.alyxInstance = varargin{3};

if length(varargin)>3 && ~isempty(varargin{4})
    % in a text mode, you could pass in the experiment you want to view
    handles.newExp = varargin{4}; 
    handles.expMets = expMetaForExp(handles.alyxInstance, handles.newExp.url);
    set(handles.lstExps, 'String', selString(handles.expMets));
else % otherwise, 
    % start the new experiment!!
    clear d
    d.subject = handles.mouseName;
    d.start_time = alyx.datestr(now);
    handles.newExp = alyx.postData(handles.alyxInstance, 'experiments', d);
    handles.expMets = {};

    fprintf(1, 'new experiment url: %s\n', handles.newExp.url);
end

handles.startTime = alyx.datenum(handles.newExp.start_time);

set(handles.txtNameDate, 'String', sprintf('%s, %s', handles.mouseName, datestr(handles.thisDate, 'yyyy-mm-dd')));

tmr = timer('Period', 1, 'ExecutionMode', 'fixedSpacing',...
    'TimerFcn', @(~,~)refreshAll(hObject));
handles.RefreshTimer = tmr;
% 
% set(hObject, 'CloseRequestFcn', @(~,~,~)stop(tmr));

% Update handles structure
guidata(hObject, handles);

% updateSelectedDisp(hObject);

% refreshAll(hObject);
start(tmr);


% UIWAIT makes alyxExpFig wait for user response (see UIRESUME)
% uiwait(handles.figure1);


% --- Outputs from this function are returned to the command line.
function varargout = alyxExpFig_OutputFcn(hObject, eventdata, handles) 
% varargout  cell array for returning output args (see VARARGOUT);
% hObject    handle to figure
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Get default command line output from handles structure
varargout{1} = handles.output;



function edtNotes_Callback(hObject, eventdata, handles)
% hObject    handle to edtNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: get(hObject,'String') returns contents of edtNotes as text
%        str2double(get(hObject,'String')) returns contents of edtNotes as a double


% --- Executes during object creation, after setting all properties.
function edtNotes_CreateFcn(hObject, eventdata, handles)
% hObject    handle to edtNotes (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: edit controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pshEnd.
function pshEnd_Callback(hObject, eventdata, handles)
% hObject    handle to pshEnd (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Now we'll end the experiment by adding any changed data to it and PUT-ing
% it back 

stop(handles.RefreshTimer);

newExp = handles.newExp; % the existing record that we started when this window opened
e = alyx.getData(handles.alyxInstance, newExp.url);


narr = get(handles.edtNotes, 'String');
if iscell(narr)
    narr = cellfun(@(x)strcat(x,'\n'), narr, 'uni', false); % put a new line at the end of each
    newExp.narrative = strcat(narr{:}); % concatenate all lines
elseif isstr(narr)
    newExp.narrative = narr;
else
    newExp.narrative = '';
end

try
    e = alyx.putData(handles.alyxInstance, newExp.url, newExp);
    fprintf(1, 'experiment successfully updated\n');
catch me
    fprintf(1, 'putting experiment failed\n');
    disp(me)
end
close(handles.figure1)



% --- Executes on selection change in lstExps.
function lstExps_Callback(hObject, eventdata, handles)
% hObject    handle to lstExps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)

% Hints: contents = cellstr(get(hObject,'String')) returns lstExps contents as cell array
%        contents{get(hObject,'Value')} returns selected item from lstExps

updateSelectedDisp(hObject);


% --- Executes during object creation, after setting all properties.
function lstExps_CreateFcn(hObject, eventdata, handles)
% hObject    handle to lstExps (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    empty - handles not created until after all CreateFcns called

% Hint: listbox controls usually have a white background on Windows.
%       See ISPC and COMPUTER.
if ispc && isequal(get(hObject,'BackgroundColor'), get(0,'defaultUicontrolBackgroundColor'))
    set(hObject,'BackgroundColor','white');
end


% --- Executes on button press in pshWater.
function pshWater_Callback(hObject, eventdata, handles)
% hObject    handle to pshWater (see GCBO)
% eventdata  reserved - to be defined in a future version of MATLAB
% handles    structure with handles and user data (see GUIDATA)
amountResp = inputdlg('How much water/gel?', 'Water administration', 1, {'0'});
amount = str2num(amountResp{1});
if ~isempty(amount) && amount>0
    try
        wa = alyx.postWaterManual(handles.mouseName, amount, handles.thisDate, handles.alyxInstance);
        if ~isempty(wa)
            fprintf(1, 'water posting successful\n');
        end
    catch
        fprintf(1, 'water posting attempted but failed\n');
    end
    
else
    fprintf(1, 'no water posted\n');
end

function refreshAll(hObject)

% update the expList
% refreshExpList(hObject)

% update the timelinePlot

% update the stopwatch
updateTimer(hObject)


function refreshExpList(hObject)
% check for new exp-metadata's, add them to the list

handles = guidata(hObject);

curr = get(handles.lstExps, 'String');
if iscell(curr); curr = strcat(curr{:}); end;
fprintf(1, 'current elems: %s\n', curr);
fprintf(1, 'selected: %d\n', get(handles.lstExps, 'Value'));

expMets = alyx.expMetaForExp(handles.alyxInstance, handles.newExp.url);
if length(expMets)>length(handles.expMets)
    handles.expMets = expMets;
    set(handles.lstExps, 'String', selString(handles.expMets));
end
guidata(hObject, handles);

function updateSelectedDisp(hObject)

handles = guidata(hObject);
listContents = cellstr(get(handles.lstExps,'String'));% returns lstExps contents as cell array
selNum = get(handles.lstExps,'Value');
selStr = listContents{selNum};

if strcmp(selStr, '[root]')
    dispStr = evalc('disp(handles.newExp)');
else
    dispStr = evalc('disp(handles.expMets{selNum-1})');
end

set(handles.txtSelectedObj, 'String', dispStr);

function updateTimer(hObject)
handles = guidata(hObject);
set(handles.txtTimer, 'String', datestr(now-handles.startTime, 'HH:MM:SS'));

    
function s = selString(expMets)
s = cat(2, {'[root]'}, cellfun(@(x)x.classname, expMets, 'uni', false));
