function s = loadObj(eid, obj, ai)
% ALF.LOADOBJ Load an ALF object 
%  TODO Document
%  TODO Support cell inputs
%
%  Inputs:
%    eid (char) : the session uuid
%    obj (char) : the ALF object to load
%    ai (Alyx) : an Alyx object 
%
%  Output:
%    s (struct) : the loaded ALF object
%
%  Example:
%    trials = alf.loadObj('f7f19bcf-fb85-497c-8a0e-397c369d1e76', 'trials')
if nargin < 3
  ai = Alyx;
end

% If is url, extract uuid
if length(eid) > 36
  eid = Alyx.url2eid(eid);
end

datasets = getOr(ai.getData(['sessions/', eid]), 'data_dataset_session_related');
datasets = datasets(cellfun(@alf.isvalid, iff(isempty(datasets), {}, @(){datasets.name})));
% valid ALF datasets
if isempty(datasets)
  s = [];
  fprintf('No ALF datasets found for session %s (%s)\n', eid, ai.getExpRef(eid))
  return
end
% filter by obj
name = cell2mat(alf.split({datasets.name}, 'names'));
datasets = datasets(strcmp({name.obj}, obj));
ids = {datasets.id};
% get file path
[filepath, exists] = mapToCell(@(id) ai.getFile(id, 'dataset'), ids);
filepath = mapToCell(@(p,e) first(p(e)), filepath, exists);
% remove empty elements
incl = ~emptyElems(filepath);
filepath = filepath(incl);
name = name(incl);
% load the data
data = mapToCell(@alf.loadFile, filepath);
% check names match data
n = numel(data);
assert(numel(name) == n)
% make into struct
C = [{name.typ}; data];
s = struct(C{:});
